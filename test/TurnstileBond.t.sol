// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { TurnstileBond } from "src/TurnstileBond.sol";
import { Turnstile } from "src/Turnstile.sol";
import { TurnstileUser } from "src/ICSR.sol";

contract TurnstileBondTest is Test {
    Turnstile turnstile;
    TurnstileBond bond;
    function setUp() external {
        turnstile = new Turnstile();
        uint256 tokenId = turnstile.register(address(this));
        bond = new TurnstileBond(address(turnstile), tokenId);
    }

    function createCSR(string memory name) public returns(address a, uint256 id, TurnstileUser u) {
        a = mockAddress(name);
        vm.startPrank(a);
        id = turnstile.register(a);
        u = new TurnstileUser{salt : keccak256(abi.encodePacked(name))}(address(turnstile), id);
        vm.stopPrank();
    }

    function mockAddress(string memory name) public pure returns(address) {
        return vm.addr(uint256(keccak256(abi.encodePacked("name : ",name))));
    }
    
    function testStart() external {
        (address a, uint256 id,) = createCSR("test1");
        vm.startPrank(a);
        turnstile.approve(address(bond), id);
        bond.start(id, 100, 1000, 10);
        vm.stopPrank();
    }

    function testClaimAfterCancel() external {
        (address a, uint256 id,) = createCSR("test1");
        address b = mockAddress("test2");
        vm.startPrank(a);
        turnstile.approve(address(bond), id);
        bond.start(id, 100, 1000, 10);
        vm.stopPrank();

        vm.deal(b,1000000);
        vm.startPrank(b);
        bond.fund{value: 100}(id);
        vm.stopPrank();
        
        vm.startPrank(a);
        (,
        ,
        ,
        ,
        ,
        ,
        uint256 received
        ,) = bond.bondInfo(id);

        uint256 cancelAmount = received;
        bond.cancel{value:cancelAmount}(id);
        vm.stopPrank();

        vm.startPrank(b);
        bond.claim(id);
        vm.stopPrank();
    }

    function testWithdrawAfterSuccessfulFund() external {
        (address a, uint256 id,) = createCSR("test1");
        address b = mockAddress("test2");
        vm.startPrank(a);
        turnstile.approve(address(bond), id);
        bond.start(id, 100, 1000, 1e17);
        vm.stopPrank();

        vm.deal(b,1000000);
        vm.startPrank(b);
        bond.fund{value: 1000}(id);
        vm.stopPrank();

        turnstile.distributeFees{value: 1200}(id);
        
        vm.startPrank(a);
        uint256 balanceBeforeReceive = a.balance;
        bond.receiveFund(id);
        uint256 balanceBefore = a.balance;
        assertEq(balanceBefore - balanceBeforeReceive, 1000);
        bond.withdraw(id);
        uint256 balanceAfter = a.balance;
        assertEq(balanceAfter - balanceBefore, 0);
        assertEq(turnstile.balances(id), 100);
        vm.stopPrank();
    }
}