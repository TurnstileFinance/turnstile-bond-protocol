pragma solidity ^0.8.18;

address constant CSR = 0xEcf044C5B4b867CFda001101c617eCd347095B44;

import {ERC721, IERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface ITurnstile is IERC721 {
    function balances(uint256) external view returns(uint256);
    function currentCounterId() external view returns (uint256);
    function getTokenId(address _smartContract) external view returns (uint256);
    function isRegistered(address _smartContract) external view returns (bool);
    function register(address _recipient) external returns (uint256 tokenId);
    function assign(uint256 _tokenId) external returns (uint256);
    function withdraw(uint256 _tokenId, address payable _recipient, uint256 _amount) external returns(uint256);
}

interface ITurnstileBond {
    function start(uint256 _tokenId, uint256 _minGoal, uint256 _maxGoal, uint256 _premium) external;
    function cancel(uint256 _tokenId) external payable;
    function withdraw(uint256 _tokenId) external; 
}

// @dev MockDEX is a mock contract that mints CSR NFT from Turnstile and starts bonding to TurnstileBond.
contract MockDEX {
    ITurnstile immutable public turnstile;
    ITurnstileBond immutable public turnstileBond;
    uint256 immutable public tokenId;

    constructor(address _turnstile, address _turnstileBond) {
        turnstile = ITurnstile(_turnstile);
        turnstileBond = ITurnstileBond(_turnstileBond);
        tokenId = turnstile.register(msg.sender);
    }
}