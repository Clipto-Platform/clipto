// SPDX-License-Identifier: None
pragma solidity 0.8.10;

import {CliptoExchange} from "../CliptoExchange.sol";
import {CliptoToken} from "../CliptoToken.sol";
import {DSTestPlus} from "lib/solmate/src/test/utils/DSTestPlus.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract CliptoExchangeTest is DSTestPlus, IERC721Receiver {
    CliptoExchange internal exchange;

    function setUp() external {
        exchange = new CliptoExchange(address(new CliptoToken()));
    }

    function testCreatorRegistration() public {
        // Register creator.
        exchange.registerCreator(
            "Gabriel", 
            "https://arweave.net/0xprofileurl", 
            1e18
        );

        // Retrieve creator information.
        (string memory profileUrl, uint256 cost, CliptoToken token) = exchange.creators(address(this));
        address tokenAddress = address(token);

        // Ensure the data returned is correct.
        assertEq(profileUrl, "https://arweave.net/0xprofileurl");
        assertEq(cost, 1e18);
        assertEq(address(token), tokenAddress);
    }

    function testRequestCreation() public {
        // Register a creator.
        testCreatorRegistration();

        // Create a new request (the creator address is address(this))
        exchange.newRequest{value: 1e18}(address(this));

        // Check that the request was created
        (address requester, uint256 value, bool delivered, bool refunded) = exchange.requests(address(this), 0);

        // Ensure the data returned is correct.
        assertEq(requester, address(this));
        assertEq(value, 1e18);
        assertFalse(delivered);
        assertFalse(refunded);
    }

    function testRequestDelivery() public {
        testRequestCreation();

        uint256 balanceBefore = address(this).balance;
        exchange.deliverRequest(0, "http://website.com");
        (, , bool delivered, ) = exchange.requests(address(this), 0);

        assertTrue(delivered);
        assertTrue(address(this).balance > balanceBefore + 9e17);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        assertEq(tokenId, 0);
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
