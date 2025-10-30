// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

//@title A sample raffle contract
//@author Albert Castro
//@notice This contract is for creating a simple raffle
//@dev Implements chainlink VRFv2.5

// error Raffle_SendEnoughEth();
// error Raffle_TransferFailed();
// error Raffle_RaffleNotOpen();
// error Raffle_UpkeepNotNeeded(
//     uint256 balance,
//     uint256 playersLenght,
//     uint256 raffleState
// );

contract Raffle is VRFConsumerBaseV2Plus {
    //Type declarations

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    error Raffle_SendEnoughEth();
    error Raffle_TransferFailed();
    error Raffle_RaffleNotOpen();
    error Raffle_UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLenght,
        uint256 raffleState
    );

    //State Variables
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    RaffleState private s_raffleState;
    address private s_recentWinner;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    //Events
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address vrf_coordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callBackGasLimit
    ) VRFConsumerBaseV2Plus(vrf_coordinator) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callBackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN; //start as open
    }

    //      struct RandomWordsRequest {
    //     bytes32 keyHash;
    //     uint256 subId;
    //     uint16 requestConfirmations;
    //     uint32 callbackGasLimit;
    //     uint32 numWords;
    //     bytes extraArgs;
    //   }

    function enterRaffle() external payable {
        //require(msg.value >= i_entranceFee, "Fee not fully covered!");
        if (msg.value < i_entranceFee) {
            revert Raffle_SendEnoughEth();
        }
        if (s_raffleState == RaffleState.CALCULATING) {
            revert Raffle_RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        //makes migration easier
        //makes frontend indexing easier
        emit RaffleEntered(msg.sender);
    }

    //1 get a random number
    //2 use random number to choose winnercd ..
    //2 be automatically called
    function performUpkeep() external {
        //check to see if enough time has passed
        bool upkeepNeeded = checkUpkeep();
        if (!upkeepNeeded) {
            revert Raffle_UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        //Get random numbers if enough time has passed

        s_raffleState = RaffleState.CALCULATING;

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    //@dev this is the function that the chainlink nodes will call to see
    //if the lottery is ready to have a winner picked.
    //the following should be true in order for upkeepNeeded to be true:
    //1 the time interval has passed between raffle rounds
    //2 the lottery is open
    //3 the contract has eth
    //4 implicitly your subscription has LINK
    //@param - ignored
    //@return upkeepNeeded - true if its time to restart the lottery

    //bytes calldata /*checkdata */ //(bytes calldata /*checkdata */)

    function checkUpkeep()
        public
        view
        returns (
            bool upkeepNeeded //(bool upkeepNeeded, bytes calldata /*perform data */)
        )
    {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool lotteryOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && lotteryOpen && hasBalance && hasPlayers;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        //checks (NON HERE)

        //effects (internal contract state)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);

        //interactions (external contract interations)
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }
    }

    //GETTER FUNCTIONS

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 playerIndex) public view returns (address) {
        return s_players[playerIndex];
    }
}

// import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
// import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
