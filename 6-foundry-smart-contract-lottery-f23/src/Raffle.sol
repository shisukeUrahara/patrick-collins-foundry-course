//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
// import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";

/**
 *@title A raffle contract
 * @author ShisukeUrahara
 *@notice This contract is for creating a sample raffle
 *@dev Implements Chainlink VRFV2
 */
contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    // custom errors
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferEthFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    // type declarations
    enum RaffleState {
        OPEN, // ---> 0
        CALCULATING // ---> 1
    }

    // state variables
    // (i) constants
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // (ii) immutables
    uint256 private immutable i_entranceFees;
    uint256 private immutable i_interval;
    IVRFCoordinatorV2Plus private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    // (iii) private
    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    // events
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 _entranceFees,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFees = _entranceFees;
        i_interval = _interval;
        s_lastTimestamp = block.timestamp;
        i_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit; // this is in constructor and not constant since it will vary depending on chain
        s_raffleState = RaffleState.OPEN;
    }

    // function to enter raffle
    function enterRaffle() external payable {
        // less gas efficient
        // require(msg.value >= i_entranceFees, "Not Enough Fees.");
        // more gas efficient
        if (msg.value < i_entranceFees) {
            revert Raffle__NotEnoughEthSent();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * when is the winner supposed to be picked
     * @dev This is the function that the chainlink automation calls to check if its time to perform an upkeep
     * the following should be true for this to return true
     * 1. the raffle is in OPEN State
     * 2. its been at least the interval since the last winner was picked
     * 3. the contract has ETH (aka , players)
     * 4. (Implicit) The contract is funded with ETH
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timeHasPassed = (block.timestamp - s_lastTimestamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasPlayers && hasBalance;
        return (upkeepNeeded, "0x0");
    }

    // a function to pick the winner
    // (i) get a random number
    // (ii) use the random number to pick the winner
    // (iii) do all this automatical
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        // set raffle state to calculating
        s_raffleState = RaffleState.CALCULATING;
        // Will revert if subscription is not set and funded.
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        emit RequestedRaffleWinner(requestId);
    }

    // fulfillRandomWords function
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        // transform the result to an index of the winning address
        uint256 indexOfWinner = (randomWords[0] % s_players.length);
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        // reset the players array so a new raffle can be setup
        s_players = new address payable[](0);
        // reset the last timestamp
        s_lastTimestamp = block.timestamp;
        emit WinnerPicked(winner);

        // transfer the ticket amounts to the winner
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferEthFailed();
        }
    }

    // getter functions
    function getEntranceFees() public view returns (uint256) {
        return i_entranceFees;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 _index) public view returns (address) {
        return s_players[_index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimestamp;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getLengthOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
}
