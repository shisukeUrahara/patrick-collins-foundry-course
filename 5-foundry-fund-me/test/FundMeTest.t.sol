// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    // reference to deployed contract here so that it can be used throughout the contract
    FundMe fundMe;

    // deploy the contract here , its the beforeEach equivalent of these tests
    function setUp() external {
        fundMe = new FundMe();
    }

    function testMinUsdValue() external {
        console.log("testMinUsdValue test ");
        assertEq(fundMe.MIN_USD_AMOUNT(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.owner(), address(this));
    }
}
