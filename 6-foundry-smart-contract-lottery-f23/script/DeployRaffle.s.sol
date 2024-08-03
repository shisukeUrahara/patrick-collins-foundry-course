// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFees,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint256 subscriptionId,
            uint32 callbackGasLimit,
            address linkTokenAddress
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            // create subscription for our mock vrf coordinator on anvil
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinator
            );

            // fund the subscription
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFees,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );

        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}
