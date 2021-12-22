// SPDX-License-Identifier: None
pragma solidity 0.8.10;

import {CliptoToken} from "./CliptoToken.sol";

/// @title Clipto Exchange
/// @author Clipto
/// @dev Exchange contract for Clipto Videos
contract CliptoExchange {
    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev Address of the Clipto Token implementation
    address public immutable TOKEN_IMPLEMENTATION;

    constructor(address implementation) {
        TOKEN_IMPLEMENTATION = implementation;
    }

    /*///////////////////////////////////////////////////////////////
                                CREATOR STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Maps creator address to creator struct.
    mapping(address => Creator) public creators;

    /// @dev Struct representing a creator account
    struct Creator {
        /// @dev Creator's profile url on arweave
        string profileUrl;
        /// @dev Minimum cost of a video
        uint256 cost;
        /// @dev address of creator's associated nft collection
        address token;
    }

    /// @notice Emitted when a new creator is registered.
    /// @param creator Address of the creator.
    /// @param profileUrl Creator's profile on arweave.
    /// @param cost cost in L1 token
    /// @param tokenAddress address where NFT contract is deployed at
    event CreatorRegistered(address indexed creator, string indexed profileUrl, uint256 cost, address tokenAddress);

    /// @notice Emitted when a new creator is modified.
    /// @param creator Address of the creator.
    /// @param profileUrl Creator's profile on arweave.
    /// @param cost cost in L1 token
    event CreatorModified(address indexed creator, string indexed profileUrl, uint256 cost);

    /// @notice Register a new creator
    function registerCreator(
        string memory creatorName,
        string memory profileUrl,
        uint256 cost
    ) external returns (address) {
        require(creators[msg.sender].token == address(0), "Already registered");

        // TODO: Do not deploy a new contract for each creator!
        address tokenAddress = address(new CliptoToken(creatorName));
        creators[msg.sender] = Creator({profileUrl: profileUrl, cost: cost, token: tokenAddress});

        // Emit event
        emit CreatorRegistered(msg.sender, profileUrl, cost, tokenAddress);

        return tokenAddress;
    }

    /// @notice Modify a creator details
    function modifyCreator(string memory profileUrl, uint256 cost) external {
        creators[msg.sender].profileUrl = profileUrl;
        creators[msg.sender].cost = cost;

        // Emit event
        emit CreatorModified(msg.sender, profileUrl, cost);
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
        /// @dev Whether the request is delivered
        bool delivered;
        /// @dev flag to indicate whether the request was refunded
        bool refunded;
    }

    /// @notice Emitted when a new request is created.
    event NewRequest(address indexed creator, address indexed requester, uint256 index, uint256 amount);

    /// @notice Emitted when a request is delivered
    event DeliveredRequest(address indexed creator, address indexed requester, uint256 index, uint256 amount);

    /// @notice Emitted when a request is refunded
    event RefundedRequest(address indexed creator, address indexed requester, uint256 index, uint256 amount);

    /// @notice Create a new request.
    /// @dev The request's "amount" value is the callvalue
    function newRequest(address creator) external payable {
        // Add the request to the creator's requests array.
        require(msg.value >= creators[creator].cost, "Insufficient value");

        requests[creator].push(Request({requester: msg.sender, amount: msg.value, delivered: false, refunded: false}));

        emit NewRequest(creator, msg.sender, requests[creator].length, msg.value);
    }

    function deliverRequest(uint256 index, string memory _tokenURI) external {
        require(requests[msg.sender][index].delivered == false, "Request already delivered");
        require(requests[msg.sender][index].refunded == false, "Request already refunded");

        CliptoToken(creators[msg.sender].token).safeMint(requests[msg.sender][index].requester, _tokenURI);
        requests[msg.sender][index].delivered = true;
        (bool sent, ) = msg.sender.call{value: requests[msg.sender][index].amount}("");
        require(sent, "Delivery failed");

        emit DeliveredRequest(
            msg.sender,
            requests[msg.sender][index].requester,
            index,
            requests[msg.sender][index].amount
        );
    }

    function refundRequest(address creator, uint256 index) external {
        require(requests[creator][index].delivered == false, "Request already delivered");
        require(requests[creator][index].refunded == false, "Request already refunded");

        requests[creator][index].refunded = true;
        (bool sent, ) = requests[creator][index].requester.call{value: requests[creator][index].amount}("");
        require(sent, "Delivery failed");

        emit RefundedRequest(creator, requests[creator][index].requester, index, requests[creator][index].amount);
    }

    /*///////////////////////////////////////////////////////////////
                              NFT UTILITIES
    //////////////////////////////////////////////////////////////*/

    /// @dev Deploy a mimimal proxy contract for a user's NFT collection.
    function deployProxy() internal returns (address proxy) {
        bytes20 implementation = bytes20(TOKEN_IMPLEMENTATION);

        assembly {
            // Read a free storage slot
            let clone := mload(0x40)

            // Store the constructor (10 bytes) + the 10 bytes of execution code that comes before the address
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)

            // Store the 20 bytes behind the clone pointer (where the zeroes start)
            // 0x14 = 20
            mstore(add(clone, 0x14), implementation)

            // Store 32 bytes behind the implementation address
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            // Use the CREATE opcode to deploy a new contract
            // Send 0 Ether
            // The code starts at pointer stored in "clone"
            // The codesize is 55 bytes (0x37)
            proxy := create(0, clone, 0x37)
        }
    }
}
