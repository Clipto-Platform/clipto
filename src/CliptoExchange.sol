// SPDX-License-Identifier: None
pragma solidity 0.8.10;

import {CliptoToken} from "./CliptoToken.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ReentrancyGuard} from "../lib/solmate/src/utils/ReentrancyGuard.sol";
import {Ownable2} from "./utils/Ownable2.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Clipto Exchange
/// @author Clipto
/// @dev Exchange contract for Clipto Videos
contract CliptoExchange is ReentrancyGuard, Ownable2 {
    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev Address of the Clipto Token implementation
    address public immutable TOKEN_IMPLEMENTATION;

    /// @notice rate * 1,000,000, default: 0%
    uint256 public feeRate = 0;
    uint256 public scale = 1e6;

    /// @dev Deploy a new Clipto Exchange contract.
    /// @param implementation Address of the Clipto Token implementation contract.
    /// @param feeDestination Address receiving exchange fees
    constructor(address implementation, address feeDestination)
        Ownable2(feeDestination)
    {
        TOKEN_IMPLEMENTATION = implementation;
    }

    /*///////////////////////////////////////////////////////////////
                              EXCHANGE FEES
    //////////////////////////////////////////////////////////////*/

    /// @dev Set exchange fee
    function setFee(uint256 _feeRate, uint256 _scale) external onlyOwner {
        feeRate = _feeRate;
        scale = _scale;
    }

    /*///////////////////////////////////////////////////////////////
                                CREATOR STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Maps creator address to their CliptoToken contract.
    mapping(address => address) public creators;

    /// @notice Emitted when a new creator is registered.
    /// @param creator Address of the creator.
    /// @param token Address of the CliptoToken contract.
    /// @param data json data for profile
    event CreatorRegistered(
        address indexed creator, 
        CliptoToken indexed token, 
        string data
    );

    /// @notice Emitted when creator updates his profile.
    /// @param creator Address of the creator.
    /// @param data json data for profile
    event CreatorUpdated(
        address indexed creator,
        string data
    );

    /// @notice Register a new creator
    function registerCreator(string memory creatorName, string memory data) external {
        // Ensure that the creator has not been registered.
        require(address(creators[msg.sender]) == address(0), "Already registered");

        // Deploy a new CliptoToken contract for the creator.
        address tokenAddress = Clones.clone(TOKEN_IMPLEMENTATION);
        CliptoToken token = CliptoToken(tokenAddress);
        token.initialize(creatorName);
        creators[msg.sender] = tokenAddress;

        // Emit creator registration event.
        emit CreatorRegistered(msg.sender, token, data);
    }


    /// @notice Register a new creator
    /// @param details: json data representing values updated
    function updateCreator(string memory details) external {
        // check if the creator exists
        require(address(creators[msg.sender]) != address(0),"User not a creator");

        emit CreatorUpdated(msg.sender, details);
    }

    /*///////////////////////////////////////////////////////////////
                                REQUEST STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Maps creator address to an array of requests.
    mapping(address => Request[]) public requests;

    /// @dev Struct representing a video request
    struct Request {
        /// @dev Address of the requester
        address requester;
        /// @dev Amount of L1 token set for the request
        uint256 amount;
        /// @dev Boolean where false = not yet started and true = fulfilled or refunded.
        bool fulfilled;

        address token;
    }

    /// @notice Emitted when a new request is created.
    /// @param creator Address of the creator.
    /// @param requester Address of the requester.
    /// @param amount Amount paid for the request.
    /// @param index Index of the request in the creator's array of tokens.
    event NewRequest(
        address indexed creator, 
        address indexed requester, 
        uint256 amount, 
        uint256 index,
        string data,
        address token
    );

    /// @notice Emitted when a request is updated.
    /// @param creator Address of the creator.
    /// @param requester Address of the requester.
    /// @param amountIncreased Amount increased in the request.
    /// @param index Index of the request in the creator's array of tokens.
    event RequestUpdated(
        address indexed creator, 
        address indexed requester, 
        uint256 amountIncreased, 
        uint256 index
    );

    /// @notice Emitted when a request is delivered
    /// @param creator Address of the creator.
    /// @param requester Address of the requester.
    /// @param amount Amount in the request.
    /// @param index Index of the request in the creator's array of tokens.
    /// @param tokenAddress address of the creator token contract
    /// @param tokenId id of the of the NFT 
    event DeliveredRequest(
        address indexed creator, 
        address indexed requester, 
        uint256 amount, 
        uint256 index,
        address tokenAddress,
        uint256 tokenId
    );

    /// @notice Emitted when a request is refunded
    /// @param creator Address of the creator.
    /// @param requester Address of the requester.
    /// @param amount Amount in the request.
    /// @param index Index of the request in the creator's array of tokens.
    event RefundedRequest(
        address indexed creator, 
        address indexed requester, 
        uint256 amount, 
        uint256 index
    );

    /// @notice Create a new request.
    /// @dev The request's "amount" value is the function argument
    function newRequest(address creator, string memory data, address token, uint256 amount) external {
        // check if amount is greater than 0
        require(amount > 0, "amount should be greater than 0");

        uint256 allowance = ERC20(token).allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");

        bool sent = ERC20(token).transferFrom(msg.sender, address(this), amount);
        require(sent,"transaction failed");

        // Push the request to the creator's request array.
        requests[creator].push(Request({
            requester: msg.sender,
            amount: amount,
            fulfilled: false, 
            token: token
        }));

        // Emit new request event.
        emit NewRequest(creator, msg.sender, amount, requests[creator].length - 1, data, token);
    }

    /// @notice Create a new request.
    /// @dev The request's "amount" value is the callvalue
    function newRequestPayable(address creator, string memory data) external payable {
        // Push the request to the creator's request array.
        requests[creator].push(Request({
            requester: msg.sender, 
            amount: msg.value, 
            fulfilled: false, 
            token: address(0)
        }));

        // Emit new request event.
        emit NewRequest(creator, msg.sender, msg.value, requests[creator].length - 1, data,address(0));
    }

    /// @notice Allows adding to the value of a request
    /// @dev The request's "amount" is increased by msg.value
    function updateRequest(address creator, uint256 index) external payable {
        // Only allow original requester to updateRequest
        // If others can contribute, the original requester can rug pull everyone by calling refund
        require(requests[creator][index].requester == msg.sender, "Not requester");

        // Update the request amount.
        requests[creator][index].amount += msg.value;

        // Emit Update Request event.
        emit RequestUpdated(creator, msg.sender, msg.value, index);
    }

    /// @notice Allows the creator to deliver on a request by minting a NFT to requester
    /// @dev The creator receives funds from contract specified by the Request struct and 
    ///     the requester receives an NFT in exchange
    function deliverRequest(uint256 index, string memory tokenURI) external nonReentrant {
        Request storage request = requests[msg.sender][index];

        // Ensure that the request has not been fulfilled.
        require(!request.fulfilled, "Request already fulfilled");

        CliptoToken token = CliptoToken(creators[msg.sender]);
        // Mint the token to the requester and mark the request as fulfilled.
        uint256 tokenId = token.tokenIdCounter();
        token.safeMint(request.requester, tokenURI);
        request.fulfilled = true;

        // Take exchange fee if fee > 0 
        bool sent;
        uint256 feeAmount = (request.amount * feeRate) / scale;

        // if the request was made by token other than native(MATIC)
        if(address(request.token) != address(0)){
            sent = ERC20(request.token).transferFrom(address(this) , owner, feeAmount);
        }

        // request made by native token
        else{
            (sent, ) =  owner.call{value: feeAmount}("");
        }
        require(sent, "Fee delivery failed");

        // Remove exchange fee from the original request amount
        uint256 paymentAmount = request.amount - feeAmount;

        // if the request was made by token other than native(MATIC)
         if(address(request.token) != address(0)){
            sent = ERC20(request.token).transferFrom(address(this) , msg.sender, paymentAmount);
         }

        // request made by native token
         else{
            (sent, ) = msg.sender.call{value: paymentAmount}("");
         }
        require(sent, "Request delivery failed");

        // Emit the delivered request value.
        emit DeliveredRequest(
            msg.sender, 
            request.requester, 
            request.amount, 
            index,
            address(creators[msg.sender]),
            tokenId
        );
    }

    /// @notice Allows the requester to be refunded if the creator fails to deliver
    /// @dev The requester received funds from the contract as specified by the Request struct
    function refundRequest(address creator, uint256 index) external nonReentrant {
        Request storage request = requests[creator][index];
        // Ensure that only the requester can ask for a refund
        require(request.requester == msg.sender, "Not requester");
        // Ensure that the request has not been fulfilled.
        require(!request.fulfilled, "Request already delivered");

        // Refund the request.
        request.fulfilled = true;

        bool sent;

        // if the request was made by token other than native(MATIC)
        if(address(request.token) != address(0)){
            sent= ERC20(request.token).transferFrom(address(this) ,request.requester, request.amount);
        }

        // request made by native token
        else{
            (sent, ) = request.requester.call{value: requests[creator][index].amount}("");
        }

        require(sent, "Delivery failed");

        // Emit the refunded request value.
        emit RefundedRequest(creator, request.requester, request.amount, index);
    }

    /*///////////////////////////////////////////////////////////////
                                MIGRATIONS
    //////////////////////////////////////////////////////////////*/

    event MigrationCreator(
        address [] creatorAddress,              // all addresses of creator
        address [] tokenAddress,                // all addresses of creator's nft contract
        string  [] jsonData                     // all extra json data
    );
    
    function migrateCreator(
        address [] calldata creatorsAddress,    // all addresses of creator
        address [] calldata tokensAddress,      // all nft tokens of creator 
        string  [] calldata jsonData            // all extra json of creator
    )
    public onlyOwner        
    {
        // making sure data exists
        require(creatorsAddress.length > 0, "No creators added");

        uint i;
        for(i = 0; i < creatorsAddress.length; i++) {
            // update mappings
            creators[creatorsAddress[i]] = tokensAddress[i] ;
        }

        emit MigrationCreator(creatorsAddress, tokensAddress, jsonData);
    }

    event MigrationRequests(
        address [] creatorAddress,               // all addresses of creator
        address [] requesterAddress,             // all addresses of the requester   
        uint256 [] amount,                       // all amounts of the requests
        bool    [] fulfilled,                    // all statuses of the requests
        uint256 [] requestIds,                   // all request ids, indexes 
        string  [] jsonData                      // extra json data of the requests 
    );

    function migrateRequest(
        address [] calldata creatorsAddress,     // all addresses of creator
        address [] calldata requesterAddress,    // all addresses of the requester
        uint256 [] calldata amount,              // all amounts of the requests
        bool    [] calldata fulfilled,           // all statuses of the requests
        string  [] calldata jsonData             // extra json data of the requests
    )
    public
    onlyOwner       
    {
        // making sure data exists
        require(creatorsAddress.length > 0, "No creators added");

        uint256 [] memory requestIds = new uint256[](creatorsAddress.length);
        uint256 i;

        for(i = 0; i < creatorsAddress.length; i++) {
            // creating request struct
            Request memory request = Request({
                requester : requesterAddress[i],
                amount : amount[i],
                fulfilled : fulfilled[i],
                token : address(0)
            });

            // adding to the requests mapping
            requests[creatorsAddress[i]].push(request);
            requestIds[i] = requests[creatorsAddress[i]].length - 1;
        }

        // single event for migration
        emit MigrationRequests(
            creatorsAddress, 
            requesterAddress, 
            amount, 
            fulfilled, 
            requestIds, 
            jsonData
        );
    }
}
