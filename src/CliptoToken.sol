// SPDX-License-Identifier: None
pragma solidity 0.8.10;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CliptoToken is ERC20, Ownable {
    constructor() ERC20("Clipto", "CTO") {
        _mint(msg.sender, 1_000_000_000 * 1e18);
    }
}
