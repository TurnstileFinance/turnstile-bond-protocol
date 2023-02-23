# ITurnstile
[Git Source](https://github.com/turnstilefinance/turnstile-bond-protocol/blob/7486069347c62151d295a0ea73b101fdf7c03106/src/ICSR.sol)

**Inherits:**
ERC721Enumerable


## Functions
### balances


```solidity
function balances(uint256) external view virtual returns (uint256);
```

### currentCounterId


```solidity
function currentCounterId() external view virtual returns (uint256);
```

### getTokenId


```solidity
function getTokenId(address _smartContract) external view virtual returns (uint256);
```

### isRegistered


```solidity
function isRegistered(address _smartContract) external view virtual returns (bool);
```

### register


```solidity
function register(address _recipient) external virtual returns (uint256 tokenId);
```

### assign


```solidity
function assign(uint256 _tokenId) external virtual returns (uint256);
```

### withdraw


```solidity
function withdraw(uint256 _tokenId, address payable _recipient, uint256 _amount) external virtual returns (uint256);
```

