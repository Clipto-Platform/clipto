// SPDX-License-Identifier: None
pragma solidity 0.8.10;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {CliptoToken} from "./CliptoToken.sol";

/// @title Clipto Exchange
/// @author Clipto
/// @dev Exchange contract for Clipto Videos
contract CliptoExchange is ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Struct represent a creator account
    struct Creator {
        /// @dev Creator's profile url on arweave
        string profileUrl;
        /// @dev Minimum cost of a video
        uint256 cost;
        /// @dev address of creator's associated nft collection
        address token;
    }

    /// @dev Struct representing a video request
    struct Request {
        // Address of the requester
        address requester;
        // Amount of ETH set for the request
        uint256 amount;
        // Whether the request is delivered
        bool delivered;
    }

    /*///////////////////////////////////////////////////////////////
                                CREATOR STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Maps creator address to creator struct.
    mapping(address => Creator) public creators;

    /// @dev Maps creator address to an array of requests.
    mapping(address => Request[]) public requests;

    /// @notice Emitted when a new creator is regsitered.
    /// @param creator Address of the creator.
    /// @param profileUrl Creator's profile on arweave.
    event CreatorRegistered(address indexed creator, string indexed profileUrl, uint256 cost);

    /// @notice Register a new creator
    function registerCreator(string memory profileUrl, uint256 cost) external {
        // Set a new creator.
        creators[msg.sender] = Creator({profileUrl: profileUrl, cost: cost, token: address(0)});

        // Emit event.
        emit CreatorRegistered(msg.sender, profileUrl, cost);
    }

    /*///////////////////////////////////////////////////////////////
                                REQUEST STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new request is created.
    event NewRequest(address indexed creator, address indexed requester, uint256 amount);

    /// @notice Create a new request.
    /// @dev The request's "amount" value is the callvalue
    function newRequest(address creator) external payable {
        // Add the request to the creator's requests array.
        require(msg.value >= creators[creator].cost, "Request amount is less than the minimum cost");
        requests[creator].push(Request({requester: msg.sender, amount: msg.value, delivered: false}));
    }

    function deliverRequest(
        string memory creatorName,
        uint256 index,
        string memory _tokenURI
    ) external nonReentrant {
        require(requests[msg.sender][index].delivered == false, "Request already delivered");

        if (creators[msg.sender].token == address(0)) {
            creators[msg.sender].token = address(new CliptoToken(creatorName));
        }
        CliptoToken(creators[msg.sender].token).safeMint(requests[msg.sender][index].requester, _tokenURI);
        requests[msg.sender][index].delivered = true;
        (bool sent, ) = msg.sender.call{value: requests[msg.sender][index].amount}("");
        require(sent, "Delivery failed");
    }
}
