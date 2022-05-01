// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract CliptoTokenStorage {
    address public owner;
    address public minter;

    string public contractMetadataURI;
}
