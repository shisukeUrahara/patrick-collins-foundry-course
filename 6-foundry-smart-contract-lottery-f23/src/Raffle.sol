//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
// import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
// import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

/** lib\chainlink\contracts\src\v0.8\vrf\interfaces\VRFCoordinatorV2Interface.sol
 *@title A raffle contract
 * @author ShisukeUrahara
 *@notice This contract is for creating a sample raffle
 *@dev Implements Chainlink VRFV2
 */
contract Raffle is VRFConsumerBaseV2Plus {
    // custom errors
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferEthFailed();
    error Raffle__RaffleNotOpen();

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
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    // (iii) private
    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    // events
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 _entranceFees,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFees = _entranceFees;
        i_interval = _interval;
        s_lastTimestamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit; // this is in constructor and not constant since it will vary depending on chain
        s_raffleState = RaffleState.OPEN;
    }

    // function to enter raffle
    function enterRaffle() external payable {
        // less gas efficient
        require(msg.value >= i_entranceFees, "Not Enough Fees.");
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

    // a function to pick the winner
    // (i) get a random number
    // (ii) use the random number to pick the winner
    // (iii) do all this automatical
    function pickWinner() external {
        // check that enough time has passed for the raffle
        if (block.timestamp - s_lastTimestamp < i_interval) {
            revert();
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
}
