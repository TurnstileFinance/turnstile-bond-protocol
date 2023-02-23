// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "src/Turnstile.sol";
import "src/TurnstileBond.sol";
contract DeployTestnet is Script {
    function run() external {
        uint256 privateKey = uint256(keccak256(abi.encodePacked("name : ", "deployer")));
        address mock = vm.addr(privateKey);
        vm.startBroadcast(privateKey);
        Turnstile turnstile = new Turnstile();
        uint256 nftId = turnstile.register(mock);
        new TurnstileBond(address(turnstile), nftId);
        vm.stopBroadcast();
    }
}