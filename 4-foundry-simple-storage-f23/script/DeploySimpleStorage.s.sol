// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract DeploySimpleStorage is Script {
    // this method runs to deploy the contract

    // command to run this script in forge
    // forge script script/DeploySimpleStorage.s.sol --rpc-url $RPC_URL --bro
    // adcast --private-key $PRIVATE_KEY

    // calling a write function through cast
    //     cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "store(uint256)"
    // 123 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

    // calling a read function through cast
    // cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "retrieve()"

    function run() external returns (SimpleStorage) {
        vm.startBroadcast(); // everything between vm.startBroadcast(); and vm.stopBroadcast(); , send to the rpc
        SimpleStorage simpleStorage = new SimpleStorage();
        vm.stopBroadcast();
        return simpleStorage;
    }
}
