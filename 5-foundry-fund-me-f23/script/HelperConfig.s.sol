// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
// things to do here
// 1.) Deploy mock for pricefeed in case we are on local anvil chain
// 2.) Keep track of contract addresses across different chains
// eg sepolia ETH/USD PriceFeed
// eg mainnet ETH/USD PriceFeed
contract HelperConfig is Script {
    // if we are on local anvil chain , deploy mock priceFeeds
    // otherwise , grab existing from the live network

    // a variable to get the current network and chain config and addresses
    NetworkConfig public activeNetworkConfig;
    uint8 public constant DECIMALS = 8; // decimals for usd
    int256 public constant INITIAL_PRICE = 2000e8; // initial price for eth now is 2000 usd

    struct NetworkConfig {
        address priceFeed; // ETH/USD PriceFeed
    }

    constructor() {
        if (block.chainid == 11155111) {
            // if chain id is sepolia chainId
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // check if a mock price feed is deployed , if yes , use that else deploy a new price feed
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        // price feed address
        // 1.) Deploy the mock price feed
        // 2.) Return the mock pricefeed address
        vm.startBroadcast();
        // deploy mock price feed
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        ); // usd decimals are 8 and eth initial price of 2000 usd

        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });

        return anvilConfig;
    }
}
