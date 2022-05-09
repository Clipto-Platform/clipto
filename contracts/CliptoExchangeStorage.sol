// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

abstract contract CliptoExchangeStorage {
    address public beacon;
    address public owner;
    address public feeRecipient;

    struct Request {
        address requester;
        address nftReceiver;
        address erc20;
        uint256 amount;
        bool fulfilled;
    }

    mapping(address => address) public creators;
    mapping(address => Request[]) public requests;
}
