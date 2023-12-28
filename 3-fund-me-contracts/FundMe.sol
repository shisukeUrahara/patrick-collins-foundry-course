// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {PriceConverter} from "./PriceConverter.sol";

// custom errors
error NotOwner();
contract FundMe{
    using PriceConverter for uint256;
    // state variables
    uint public constant MIN_USD_AMOUNT=5*1e18; // since it is initialized once at contract deployment outside a function, we can make it constant variable which saves gas
    address[] public funders;
    address public immutable owner; // in this contract owner is also initialized once but in the constructor , so we made it immutable
    mapping(address funder =>uint256 amountFunded) public addressToAmountFunded;

    // constructor
    constructor(){
        owner=msg.sender;

    }

    // modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // a function to allow users to send at least 5$ worth of eth to this contract
    // payable keyword is to define that this function can receive ether
    function fund() public payable{
        require(msg.value.getConversionRate()>=MIN_USD_AMOUNT,"did not send enough eth");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender]+=msg.value;
    }

    // a function to allow an addres to  withdraw money from the contract
    function withdraw() public onlyOwner() {
          for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        // transfer ether to sender , 3 ways to do this
        // (i) transfer (if transfer fails , it throws an error)
        payable(msg.sender).transfer(address(this).balance);

        // (ii) send (if transfer fails , it throws a boolean)
        bool sendSuccess= payable(msg.sender).send(address(this).balance);
        require(sendSuccess,"Transfer failed");

        // (iii) call (low level call , can call any method through this call method)
        (bool callSuccess,bytes memory dataReturned ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");




    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

   
}