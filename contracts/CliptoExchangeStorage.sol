// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

abstract contract CliptoExchangeStorage {
    address public CLIPTO_TOKEN_ADDRESS;
    address public owner;

    struct Request {
        address requester;
        address erc20;
        uint256 amount;
        bool fulfilled;
        string metadataURI;
    }

    struct Creator {
        address nft;
        string metadataURI;
    }

    mapping(address => Creator) public creators;
    mapping(address => Request[]) public requests;
}
