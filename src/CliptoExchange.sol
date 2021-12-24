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

    /// @dev Maps creator address to creator struct.
    mapping(address => Creator) public creators;

    /// @dev Struct representing a creator account
    struct Creator {
        /// @dev Minimum cost of a video
        uint256 cost;
        /// @dev address of creator's associated nft collection
        CliptoToken token;
    }

    /// @notice Emitted when a new creator is registered.
    /// @param creator Address of the creator.
    /// @param cost cost in L1 token
    /// @param tokenAddress address where NFT contract is deployed at
    event CreatorRegistered(address indexed creator, uint256 cost, CliptoToken tokenAddress);

    /// @notice Emitted when a new creator is modified.
    /// @param creator Address of the creator.
    /// @param cost cost in L1 token
    event CreatorModified(address indexed creator, uint256 cost);

    /// @notice Register a new creator
    function registerCreator(string memory creatorName, uint256 cost) external {
        // Ensure that the creator has not been registered.
        require(address(creators[msg.sender].token) == address(0), "Already registered");

        // Deploy a new CliptoToken contract for the creator.
        CliptoToken token = CliptoToken(Clones.clone(TOKEN_IMPLEMENTATION));
        token.initialize(creatorName);
        creators[msg.sender] = Creator({cost: cost, token: token});

        // Emit creator registrartion event
        emit CreatorRegistered(msg.sender, cost, token);
    }

    /// @notice Modify a creator details
    function modifyCreator(uint256 cost) external {
        // Modify the cost of a creator.
        creators[msg.sender].cost = cost;

        // Emit event
        emit CreatorModified(msg.sender, cost);
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

    /// @notice Allows adding to the value of a request
    /// @dev The request's "amount" is increased by msg.value
    function updateRequest(address creator, uint256 index) external payable {
        require(msg.sender == requests[creator][index].requester, "only requester may update");
        requests[creator][index].amount += msg.value;

        // even though this isn't a new request, the event serves the purpose well
        emit NewRequest(creator, msg.sender, index, requests[creator][index].amount);
    }

    function deliverRequest(uint256 index, string memory _tokenURI) external nonReentrant {
        require(requests[msg.sender][index].delivered == false, "Request already delivered");
        require(requests[msg.sender][index].refunded == false, "Request already refunded");

        creators[msg.sender].token.safeMint(requests[msg.sender][index].requester, _tokenURI);
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

    function refundRequest(address creator, uint256 index) external nonReentrant {
        require(requests[creator][index].delivered == false, "Request already delivered");
        require(requests[creator][index].refunded == false, "Request already refunded");

        requests[creator][index].refunded = true;
        (bool sent, ) = requests[creator][index].requester.call{value: requests[creator][index].amount}("");
        require(sent, "Delivery failed");

        emit RefundedRequest(creator, requests[creator][index].requester, index, requests[creator][index].amount);
    }
}
