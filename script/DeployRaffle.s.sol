//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function deployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig netConf = new HelperConfig();
        //local => deploy mocks, get local config
        //sepolia => get sepolia config
        HelperConfig.NetworkConfig memory config = netConf.getConfig();

        if (config.subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (config.subscriptionId, config.vrf_coordinator) = createSub
                .createSubscription(config.vrf_coordinator);
            //Now we need to fund our subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrf_coordinator,
                config.subscriptionId,
                config.link
            );
        }

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

        AddConsumer addConsumer = new AddConsumer();

        addConsumer.addConsumer(
            address(raffle),
            config.vrf_coordinator,
            config.subscriptionId
        );

        return (raffle, netConf);
    }

    function run() public {}
}
