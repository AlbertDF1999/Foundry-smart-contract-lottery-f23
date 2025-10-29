//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.sol";

contract DeployRaffle is Script {
    function deployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig netConf = new HelperConfig();
        //local => deploy mocks, get local config
        //sepolia => get sepolia config
        HelperConfig.NetworkConfig memory config = netConf.getConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config._entranceFee,
            config._interval,
            config.vrf_coordinator,
            config.gasLane,
            config.subscriptionId,
            config.callBackGasLimit
        );
        vm.stopBroadcast();

        return (raffle, netConf);
    }

    function run() public {}
}
