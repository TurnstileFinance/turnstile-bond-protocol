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

    function mockAddress(string memory name) public returns(address) {
        return vm.addr(uint256(keccak256(abi.encodePacked("name : ",name))));
    }
    
    function testStart() external {
        (address a, uint256 id,) = createCSR("test1");
        vm.startPrank(a);
        turnstile.approve(address(bond), id);
        bond.start(id, 100, 1000, 10);
        vm.stopPrank();
    }
}