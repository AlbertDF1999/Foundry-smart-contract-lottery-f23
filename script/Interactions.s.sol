//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrf_coordinator;
        (uint256 subId, ) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint256, address) {
        console.log("Creating subscription on chain ID: ", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription id is: ", subId);
        console.log(
            "Please update your subscription ID in you Helperconfig.s.sol"
        );

        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 constant FUND_AMOUNT = 3 ether; //3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrf_coordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator, subId, linkToken);
    }

    function fundSubscription(
        address _vrfCoordinator,
        uint256 _subId,
        address _linkToken
    ) public {
        console.log("Funding subscription, id: ", _subId);
        console.log("Using the coordinator: ", _vrfCoordinator);
        console.log("Using the chain ID: ", _linkToken);
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(
                _subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(_linkToken).transferAndCall(
                _vrfCoordinator,
                _subId,
                abi.encode(_subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {}
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address _mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrf_coordinator;
        addConsumer(_mostRecentlyDeployed, vrfCoordinator, subId);
    }

    function addConsumer(
        address contractToAddVrf,
        address _vrfCoordinator,
        uint256 _subId
    ) public {
        console.log("Adding consumer contract: ", contractToAddVrf);
        console.log("To vrfcoordinator: ", _vrfCoordinator);
        console.log("To chain ID: ", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(_vrfCoordinator).addConsumer(
            _subId,
            contractToAddVrf
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentrlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentrlyDeployed);
    }
}
