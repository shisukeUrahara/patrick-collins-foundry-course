// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Script} from "forge-std/Script.sol";
// things to do here
// 1.) Deploy mock for pricefeed in case we are on local anvil chain
// 2.) Keep track of contract addresses across different chains
// eg sepolia ETH/USD PriceFeed
// eg mainnet ETH/USD PriceFeed
contract HelperConfig {
    // if we are on local anvil chain , deploy mock priceFeeds
    // otherwise , grab existing from the live network

    // a variable to get the current network and chain config and addresses
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeed; // ETH/USD PriceFeed
    }

    constructor() {
        if (block.chainid == 11155111) {
            // if chain id is sepolia chainId
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getAnvilEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
    }
}
