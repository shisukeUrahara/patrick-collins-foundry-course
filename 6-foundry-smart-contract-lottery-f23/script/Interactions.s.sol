// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingChainConfig() public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , ) = helperConfig
            .activeNetworkConfig();

        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint256) {
        console.log("**@ creating subscription on chainid , ", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("**@ subscription created , subId is , ", subId);
        console.log(
            "**@ please update subscription id in helper config script"
        );
        return subId;
    }

    function run() external returns (uint256) {
        return createSubscriptionUsingChainConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether; // aka 3 link

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint256 subId,
            ,
            address linkTokenAddress
        ) = helperConfig.activeNetworkConfig();

        fundSubscription(vrfCoordinator, subId, linkTokenAddress);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subId,
        address linkTokenAddress
    ) public {
        console.log("**@ Funding Subscription ,. ", subId);
        console.log("**@ using vrfCoordinator , ", vrfCoordinator);
        console.log("**@ on chainid , ", block.chainid);

        if (block.chainid == 31337) {
            // funding subscription on anvil mock coordinator
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );

            vm.stopBroadcast();
        } else {
            // do an actual fund tx on the given chain
            vm.startBroadcast();
            LinkToken(linkTokenAddress).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );

            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}
