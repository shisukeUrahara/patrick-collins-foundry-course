// SPDF-License-Identifier: MIT

pragma solidity ^0.8.20;
import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // before start broadcast i.e not a real gas spending tx
        HelperConfig helperConfig = new HelperConfig();
        // get current chain priceFeed
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
