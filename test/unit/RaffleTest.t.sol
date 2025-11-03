//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 _entranceFee;
    uint256 _interval;
    address vrf_coordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callBackGasLimit;

    address private PLAYER = makeAddr("PLAYER");
    uint256 private constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployRaffle();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        _entranceFee = config._entranceFee;
        _interval = config._interval;
        vrf_coordinator = config.vrf_coordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callBackGasLimit = config.callBackGasLimit;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertWhenYouDontPayEnough() public {
        //arrange
        vm.prank(PLAYER);
        //act / assert
        vm.expectRevert(Raffle.Raffle_SendEnoughEth.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        //arrange
        vm.prank(PLAYER);
        //Act
        raffle.enterRaffle{value: 10 ether}();
        //assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        //arrange
        vm.prank(PLAYER);
        //Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        //assert
        raffle.enterRaffle{value: _entranceFee}();
    }

    function testDontAllowPlayersToEnterWhenRaffleIsCalculating() public {
        //ARRANGE
        vm.prank(PLAYER);
        raffle.enterRaffle{value: _entranceFee}();
        vm.warp(block.timestamp + _interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep();
        //ACT//ASSERT
        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: _entranceFee}();
    }

    ///////////////////////////////////////CHECKUPKEEP TESTS

    function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
        //arrange
        vm.warp(block.timestamp + _interval + 1);
        vm.roll(block.number + 1);

        //Act
        bool upKeepNeeded = raffle.checkUpkeep();

        //assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfRaffleIsNotOpen() public {
        //ARRANGE
        vm.prank(PLAYER);
        raffle.enterRaffle{value: _entranceFee}();
        vm.warp(block.timestamp + _interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep();

        //ACT
        bool upKeepNeeded = raffle.checkUpkeep();

        //ASSERT
        assert(!upKeepNeeded);
    }

    //CHALLENGE
    //testCheckUpKeepReturnsFalseIfEnoughTimneHasntPassed
    //testCheckUpKeepReturnsTrueWhenParametersAreGood

    function testCheckUpKeepReturnsFalseIfEnoughTimneHasntPassed() public {
        //ARRANGE
        vm.prank(PLAYER);
        raffle.enterRaffle{value: _entranceFee}();

        //ACT
        bool enoughTimeHasPassed = raffle.checkUpkeep();

        //assert
        assert(!enoughTimeHasPassed);
    }

    function testCheckUpKeepReturnsTrueWhenParametersAreGood() public {
        //arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: _entranceFee}();
        vm.warp(block.timestamp + _interval + 1);
        vm.roll(block.number + 1);

        //act
        bool upkeepNeeded = raffle.checkUpkeep();
        console.log(upkeepNeeded);

        //assert
        assert(upkeepNeeded);
    }

    ////////////////////////////////////////////////////////////////PERFORM UPKEEP

    function testPerformUpkeepOnlyRunsIfCheckUpkeepIsTrue() public {
        //arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: _entranceFee}();
        vm.warp(block.timestamp + _interval + 1);
        vm.roll(block.number + 1);

        //Acc//assert
        raffle.performUpkeep();
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        //arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: _entranceFee}();
        currentBalance += _entranceFee;
        numPlayers = raffle.getPlayers();

        //act//assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                rState
            )
        );
        raffle.performUpkeep();
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: _entranceFee}();
        vm.warp(block.timestamp + _interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepUpdateRaffleStateAndEmitRequestId()
        public
        raffleEntered
    {
        //ARRANGE

        //ACT
        vm.recordLogs();
        raffle.performUpkeep();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        //ASSERT
        Raffle.RaffleState rState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    //////////////////////////////////////////FULFILLRANDOMWORDS
}
