// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";
import {Test, console} from "forge-std/Test.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract OurTokenTest is Test {
    uint256 BOB_STARTING_AMOUNT = 100 ether;
    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether; // 1 million tokens with 18 decimal places

    OurToken public ourToken;
    DeployOurToken public deployer;
    address public deployerAddress;
    address bob;
    address alice;

    // events
    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        deployer = new DeployOurToken();

        ourToken = new OurToken(INITIAL_SUPPLY);
        ourToken.transfer(msg.sender, INITIAL_SUPPLY);

        bob = makeAddr("bob");
        alice = makeAddr("alice");

        vm.prank(msg.sender);
        ourToken.transfer(bob, BOB_STARTING_AMOUNT);
    }

    function testInitialSupply() public view {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(this), 1);
    }

    function testAllowances() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice to spend tokens on his behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);
        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);
        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), BOB_STARTING_AMOUNT - transferAmount);
    }

    // Additional test cases

    function testBalanceOf() public {
        // Check initial balance of deployer
        assertEq(
            ourToken.balanceOf(msg.sender),
            INITIAL_SUPPLY - BOB_STARTING_AMOUNT
        );

        // Check initial balance of Bob
        assertEq(ourToken.balanceOf(bob), BOB_STARTING_AMOUNT);
    }

    function testTransfer() public {
        uint256 transferAmount = 50 ether;

        // Transfer tokens from Bob to Alice
        vm.prank(bob);
        ourToken.transfer(alice, transferAmount);

        // Check balances after transfer
        assertEq(ourToken.balanceOf(bob), BOB_STARTING_AMOUNT - transferAmount);
        assertEq(ourToken.balanceOf(alice), transferAmount);
    }

    function testTransferFailInsufficientBalance() public {
        uint256 transferAmount = BOB_STARTING_AMOUNT + 1 ether;

        // Attempt to transfer more than Bob's balance
        vm.prank(bob);
        vm.expectRevert();
        ourToken.transfer(alice, transferAmount);
    }

    function testApproveAndTransferFrom() public {
        uint256 approveAmount = 200 ether;
        uint256 transferAmount = 100 ether;

        // Bob approves Alice to spend tokens
        vm.prank(bob);
        ourToken.approve(alice, approveAmount);

        // Alice transfers tokens from Bob to herself
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        // Check balances and remaining allowance
        assertEq(ourToken.balanceOf(bob), BOB_STARTING_AMOUNT - transferAmount);
        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(
            ourToken.allowance(bob, alice),
            approveAmount - transferAmount
        );
    }

    function testEvents() public {
        uint256 transferAmount = 10 ether;

        // Expect Transfer event
        vm.expectEmit(true, true, false, true);
        emit Transfer(bob, alice, transferAmount);

        // Bob transfers to Alice
        vm.prank(bob);
        ourToken.transfer(alice, transferAmount);
    }
}
