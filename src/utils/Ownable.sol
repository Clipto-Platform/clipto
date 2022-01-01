// SPDX-License-Identifier: None

pragma solidity ^0.8.10;

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /**
     * @dev Constructor to set owner
     */
    constructor(address _owner) {
        owner = _owner;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Modifier that throws if not called by owner
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Not owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a newOwner. Can only be called by owner
     *      Transfer to address(0) to revoke ownership.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
