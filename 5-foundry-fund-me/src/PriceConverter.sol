// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AggregatorV3Interface } from  "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// this is price converter for ETH/USD on sepolia testnet
// for other networks , change oracle address accordingly

library PriceConverter{
     function getPrice() public view returns (uint256) {
        AggregatorV3Interface  priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (,int256 price,,,)= priceFeed.latestRoundData();
        return uint256(price*1e10); // price has 8 decimal places , so we are adding 10 more decimal places for ease of conversion to 1e18
    }

    function getConversionRate(uint256 _ethAmount) public view returns(uint256) {
        uint256 ethPrice=getPrice();
        uint256 ethAmountInUsd=(ethPrice*_ethAmount)/1e18;
        return ethAmountInUsd;
    }
}