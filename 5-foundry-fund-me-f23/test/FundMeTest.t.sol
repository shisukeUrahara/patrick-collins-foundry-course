// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {PriceConverter} from "../src/PriceConverter.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); // aggregator price feed for sepolia
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testMinUSD() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testCorrectPriceFeedVersion() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }
}
