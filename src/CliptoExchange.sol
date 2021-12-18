pragma solidity 0.8.10;

/// @title Clipto Exchange
/// @author Clipto
/// @dev Exchange contract for Clipto Videos
contract CliptoExchange {
    /*///////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Struct represent a creator account
    struct Creator {
        /// @dev Creator's name
        string name;
        /// @dev Minimum cost of a video
        uint256 cost;
        /// @dev Array of requests
        Request[] requests;
    }

    /// @dev Struct representing a video request
    struct Request {
        // Address of the requester
        address requester;
        // Amount of ETH set for the request
        uint256 amount;
    }

    /*///////////////////////////////////////////////////////////////
                                CREATOR STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Maps creator address to creator struct
    mapping(address => Creator) public creators;

    /// @notice Emitted when a new creator is regsitered.
    /// @param creator Address of the creator.
    /// @param name Creator's name.
    event CreatorRegistered(address indexed creator, string indexed name, uint256 cost);

    /// @notice Register a new creator
    function registerCreator(string memory name, uint256 cost) external {
        // Set a new creator.
        creators[msg.sender] = Creator({name: name, cost: cost, requests: new Request[](0)});

        // Emit event.
        emit CreatorRegistered(msg.sender, name, cost);
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
        creators[creator].requests.push(Request({requester: msg.sender, amount: msg.value}));
    }
}
