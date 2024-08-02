//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 *@title A raffle contract
 * @author ShisukeUrahara
 *@notice This contract is for creating a sample raffle
 *@dev Implements Chainlink VRFV2
 */
contract Raffle {
    error Raffle__NotEnoughEthSent();
    uint256 private immutable i_entranceFees;
    address payable[] private s_players;

    // events
    event RaffleEntered(address indexed player);

    constructor(uint256 _entranceFees) {
        i_entranceFees = _entranceFees;
    }

    // function to enter raffle
    function enterRaffle() external payable {
        // less gas efficient
        require(msg.value >= i_entranceFees, "Not Enough Fees.");
        // more gas efficient
        if (msg.value < i_entranceFees) {
            revert Raffle__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // a function to pick the winner
    function pickWinner() public {}

    // getter functions
    function getEntranceFees() public view returns (uint256) {
        return i_entranceFees;
    }
}
