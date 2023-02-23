# TurnstileBond
[Git Source](https://github.com/turnstilefinance/turnstile-bond-protocol/blob/7486069347c62151d295a0ea73b101fdf7c03106/src/TurnstileBond.sol)

**Inherits:**
[TurnstileUser](/src/ICSR.sol/contract.TurnstileUser.md), ERC1155


## State Variables
### bondInfo

```solidity
mapping(uint256 => BondInfo) public bondInfo;
```


### sellerNfts

```solidity
mapping(address => uint256[]) public sellerNfts;
```


### currentBonds

```solidity
uint256[] public currentBonds;
```


### allBonds

```solidity
uint256[] public allBonds;
```


## Functions
### constructor


```solidity
constructor(address _turnstile, uint256 _id) TurnstileUser(_turnstile, _id);
```

### receive


```solidity
receive() external payable;
```

### uri


```solidity
function uri(uint256) public pure override returns (string memory);
```

### sellerInfo


```solidity
function sellerInfo(address _seller) external view returns (uint256[] memory tokenIds);
```

### bondStatus


```solidity
function bondStatus(uint256 _tokenId) external view returns (BondInfo memory info);
```

### sellerBondStatus


```solidity
function sellerBondStatus(address _seller) external view returns (BondInfo[] memory info);
```

### allBondStatus


```solidity
function allBondStatus() external view returns (BondInfo[] memory info);
```

### currentBondStatus


```solidity
function currentBondStatus() external view returns (BondInfo[] memory info);
```

### getClaimableBond


```solidity
function getClaimableBond(address _user) external view returns (ClaimableInfo[] memory info);
```

### start

start a bond sale

*withdrawn/canceld bond can not be restarted*


```solidity
function start(uint256 _tokenId, uint256 _softCap, uint256 _hardCap, uint256 _premium) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|the token id|
|`_softCap`|`uint256`|the minimum goal|
|`_hardCap`|`uint256`|the maximum goal|
|`_premium`|`uint256`|the premium|


### cancel

cancel the bond sale

*cancel the bond sale and refund the seller*


```solidity
function cancel(uint256 _tokenId) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|the token id|


### receiveFund

receive the fund

*receive the fund and transfer canto to seller*


```solidity
function receiveFund(uint256 _tokenId) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|the token id|


### withdraw

withdraw turnstile nft

*withdraw turnstile nft and refund the extra fund*


```solidity
function withdraw(uint256 _tokenId) external;
```

### fund

*fund the bond*


```solidity
function fund(uint256 _tokenId) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|the token id|


### claim

claim the bond

*claim amount will be calculated by the ratio of raised and accrued if not canceled*


```solidity
function claim(uint256 _tokenId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|the token id|


### claimableAmount

amount of token claimable

*claim amount will be calculated by the ratio of raised and accrued if not canceled*


```solidity
function claimableAmount(uint256 _tokenId, address _user) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|the token id|
|`_user`|`address`|the user address|


### harvest

accrue the bond from turnstile

*accrue amount cannot exceed premium*


```solidity
function harvest(uint256 _tokenId) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|the token id|


### pay

force accrue to `_tokenId`

*accrue amount can exceed premium*


```solidity
function pay(uint256 _tokenId) public payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`uint256`|the token id|


## Errors
### NotSeller

```solidity
error NotSeller();
```

### NotActive

```solidity
error NotActive();
```

### TransferFailed

```solidity
error TransferFailed();
```

## Structs
### BondInfo

```solidity
struct BondInfo {
    Status status;
    address payable seller;
    uint256 softCap;
    uint256 hardCap;
    uint256 premium;
    uint256 raised;
    uint256 received;
    uint256 accrued;
}
```

### ClaimableInfo

```solidity
struct ClaimableInfo {
    uint256 tokenId;
    uint256 amount;
}
```

## Enums
### Status

```solidity
enum Status {
    NotStarted,
    Active,
    Canceled,
    Withdrawn
}
```

