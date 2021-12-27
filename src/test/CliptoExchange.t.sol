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

    // Correctness test for registerCreator()
    function test_creatorRegistration() public {
        // Register creator.
        exchange.registerCreator("Gabriel");

        // Retrieve creator information.
        address token = address(exchange.creators(address(this)));

        // Ensure the data returned is correct.
        assertTrue(token != address(0));
    }

    // Correctness test for newRequest()
    function test_requestCreation() public {
        // Register a creator.
        test_creatorRegistration();

        // Create a new request (the creator address is address(this))
        exchange.newRequest{value: 1e18}(address(this));

        // Check that the request was created
        (address requester, uint256 value, bool fulfilled) = exchange.requests(address(this), 0);

        // Ensure the data returned is correct.
        assertEq(requester, address(this));
        assertEq(value, 1e18);
        assertFalse(fulfilled);
    }

    // Correctness test for deliverRequest()
    function test_requestDelivery() public {
        test_requestCreation();

        // Update Request
        exchange.updateRequest{value: 1e18}(address(this), 0);
        // Check that the request was updated
        (address requester, uint256 value, bool fulfilled) = exchange.requests(address(this), 0);
        assertEq(requester, address(this));
        assertEq(value, 2e18);
        assertFalse(fulfilled);

        uint256 balanceBefore = address(this).balance;
        exchange.deliverRequest(0, "http://website.com");
        (, , fulfilled) = exchange.requests(address(this), 0);

        // Check if contract state has been updated
        assertTrue(fulfilled);
        assertTrue(address(this).balance > balanceBefore + 19e17);
        
        // Check if token has been successfully minted
        CliptoToken token = exchange.creators(address(this));
        assertEq(token.balanceOf(address(this)), 1);
        assertEq(token.totalSupply(), 1);
        assertEq(token.tokenURI(0), "http://website.com");
    }

    // Correctness test for refundRequest()
    function test_requestRefund() public {
        test_requestCreation();

        uint256 balanceBefore = address(this).balance;
        exchange.refundRequest(address(this), 0);
        (, , bool fulfilled) = exchange.requests(address(this), 0);

        // Check if contract state has been updated
        assertTrue(fulfilled);
        assertTrue(address(this).balance > balanceBefore + 9e17);

        // Check if token has not been minted
        CliptoToken token = exchange.creators(address(this));
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.totalSupply(), 0);
    }

    // Check if refund is possible after request is delivered 
    function testFail_requestDeliverRequestRefund() public {
        test_requestCreation();
        exchange.deliverRequest(0, "http://website.com");
        exchange.refundRequest(address(this), 0);
    }

    // Check if multiple refund is not possible
    function testFail_multipleRefund() public {
        test_requestCreation();
        exchange.refundRequest(address(this), 0);
        exchange.refundRequest(address(this), 0);
    }

    // Check if multiple delivery is not possible
    function testFail_multipleDeliver() public {
        test_requestCreation();
        exchange.deliverRequest(0, "http://website.com");
        exchange.deliverRequest(0, "http://website.com");
    }

    // Check if multiple registration is not possible
    function testFail_multipleRegister() public {
        exchange.registerCreator("Gabriel");
        exchange.registerCreator("Gabriel");
    }

    // Check if delivery is not possible from unknown indices
    // This is a symbolic test and can take a while to run
    function proveFail_deliverUnknownIndices(uint256 index) public {
        test_requestCreation();
        if (index > 0) {
            exchange.deliverRequest(index, "http://website.com");
        }
    }

    // Check if refund is not possible from unknown indices
    // This is a symbolic test and can take a while to run
    function proveFail_refundUnknownIndices(uint256 index) public {
        test_requestCreation();
        if (index > 0) {
            exchange.refundRequest(address(this), index);
        }
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
