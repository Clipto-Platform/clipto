// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract CliptoTokenStorage {
    uint256 public royaltyNumer;
    uint256 public royaltyDenom;

    address public owner;
}
