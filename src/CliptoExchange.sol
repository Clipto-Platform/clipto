pragma solidity 0.8.10;

/// @title Clipto Exchange
/// @author Clipto
/// @dev Exchange contract for Clipto Videos
contract CliptoExchange {
    /*///////////////////////////////////////////////////////////////
                            CLIPTO STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Struct represent a creator account
    struct Creator {
        /// @dev Creator address
        address creator;
        /// @dev Minimum cost of a video
        uint256 minimumCost;
    }

    /// @dev Struct representing a video request
    struct Request {
        // Address of the video creator
        address creator;
        // Address of the requester
        address requester;
    }
}
