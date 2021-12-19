// SPDX-License-Identifier: None
pragma solidity 0.8.10;

import {CliptoExchange} from "../CliptoExchange.sol";
import {DSTestPlus} from "lib/solmate/src/test/utils/DSTestPlus.sol";

contract CliptoExchangeTest is DSTestPlus {
    CliptoExchange exchange;

    function setUp() external {
        exchange = new CliptoExchange();
    }

    function testCreatorRegistration() public {
        // Register creator.
        exchange.registerCreator("Gabriel Haines", 1e18);

        // Retrieve creator information.
        (string memory name, uint256 cost) = exchange.creators(address(this));

        // Ensure the data returned is correct.
        assertEq(name, "Gabriel Haines");
        assertEq(cost, 1e18);
    }

    function testRequestCreation() external {
        // Register a creator.
        testCreatorRegistration();

        // Create a new request (the creator address is address(this))
        exchange.newRequest{value: 1e18}(address(this));

        // Check that the request was created
        (address requester, uint256 value) = exchange.requests(address(this), 0);

        // Ensure the data returned is correct.
        assertEq(requester, address(this));
        assertEq(value, 1e18);
    }
}
