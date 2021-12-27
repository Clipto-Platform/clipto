// SPDX-License-Identifier: None
pragma solidity 0.8.10;

import {CliptoToken} from "./CliptoToken.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ReentrancyGuard} from "lib/solmate/src/utils/ReentrancyGuard.sol";

/// @title Clipto Exchange
/// @author Clipto
/// @dev Exchange contract for Clipto Videos
contract CliptoExchange is ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev Address of the Clipto Token implementation
    address public immutable TOKEN_IMPLEMENTATION;

    /// @dev Deploy a new Clipto Exchange contract.
    /// @param implementation Address of the Clipto Token implementation contract.
    constructor(address implementation) {
        TOKEN_IMPLEMENTATION = implementation;
    }

    /*///////////////////////////////////////////////////////////////
                                CREATOR STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Maps creator address to their CliptoToken contract.
    mapping(address => CliptoToken) public creators;

    /// @notice Emitted when a new creator is registered.
    /// @param creator Address of the creator.
    /// @param token Address of the CliptoToken contract.
    event CreatorRegistered(address indexed creator, CliptoToken indexed token);

    /// @notice Register a new creator
    function registerCreator(string memory creatorName) external {
        // Ensure that the creator has not been registered.
        require(address(creators[msg.sender]) == address(0), "Already registered");

        // Deploy a new CliptoToken contract for the creator.
        CliptoToken token = CliptoToken(Clones.clone(TOKEN_IMPLEMENTATION));
        token.initialize(creatorName);
        creators[msg.sender] = token;

        // Emit creator registration event.
        emit CreatorRegistered(msg.sender, token);
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
        /// @dev Boolean indicating whether the request has been fulfilled/refunded.
        bool fulfilled;
    }

    /// @notice Emitted when a new request is created.
    /// @param creator Address of the creator.
    /// @param requester Address of the requester.
    /// @param amount Amount paid for the request.
    /// @param index Index of the request in the creator's array of tokens.
    event NewRequest(address indexed creator, address indexed requester, uint256 amount, uint256 index);

    /// @notice Emitted when a request is updated.
    /// @param creator Address of the creator.
    /// @param requester Address of the requester.
    /// @param amountIncreased Amount increased in the request.
    /// @param index Index of the request in the creator's array of tokens.
    event RequestUpdated(address indexed creator, address indexed requester, uint256 amountIncreased, uint256 index);

    /// @notice Emitted when a request is delivered
    event DeliveredRequest(address indexed creator, address indexed requester, uint256 amount, uint256 index);

    /// @notice Emitted when a request is refunded
    event RefundedRequest(address indexed creator, address indexed requester, uint256 amount, uint256 index);

    /// @notice Create a new request.
    /// @dev The request's "amount" value is the callvalue
    function newRequest(address creator) external payable {
        // Push the request to the creator's request array.
        requests[creator].push(Request({requester: msg.sender, amount: msg.value, fulfilled: false}));

        // Emit new request event.
        emit NewRequest(creator, msg.sender, msg.value, requests[creator].length - 1);
    }

    /// @notice Allows adding to the value of a request
    /// @dev The request's "amount" is increased by msg.value
    function updateRequest(address creator, uint256 index) external payable {
        // Update the request amount.
        requests[creator][index].amount += msg.value;

        // Emit Update Request event.
        emit RequestUpdated(creator, msg.sender, msg.value, index);
    }

    function deliverRequest(uint256 index, string memory tokenURI) external nonReentrant {
        // Store the request in memory.
        Request memory request = requests[msg.sender][index];

        // Ensure that the request has not been fulfilled.
        require(!request.fulfilled, "Request already fulfilled");

        // Mint the token to the requester and mark the request as fulfilled.
        creators[msg.sender].safeMint(request.requester, tokenURI);
        requests[msg.sender][index].fulfilled = true;

        // Ensure the transfer is successful.
        (bool sent, ) = msg.sender.call{value: request.amount}("");
        require(sent, "Delivery failed");

        // Emit the delivered request value.
        emit DeliveredRequest(msg.sender, request.requester, request.amount, index);
    }

    function refundRequest(address creator, uint256 index) external nonReentrant {
        // Store the request in memory.
        Request memory request = requests[creator][index];
        // Ensure that only the requester can ask for a refund
        require(request.requester == msg.sender, "Not requester");
        // Ensure that the request has not been fulfilled.
        require(!request.fulfilled, "Request already delivered");

        // Refund the request.
        requests[creator][index].fulfilled = true;
        (bool sent, ) = requests[creator][index].requester.call{value: requests[creator][index].amount}("");
        require(sent, "Delivery failed");

        // Emit the refunded request value.
        emit RefundedRequest(creator, request.requester, index, request.amount);
    }
}
