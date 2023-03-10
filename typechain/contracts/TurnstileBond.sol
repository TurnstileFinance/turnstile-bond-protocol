// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ERC1155} from "solmate/src/tokens/ERC1155.sol";
import "./ICSR.sol";

contract TurnstileBond is TurnstileUser, ERC1155 {
    enum Status {
        NotStarted,
        Rasing,
        Ended,
        Withdrawn,
        Canceled
    }

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

    mapping(uint256 => BondInfo) public bondInfo;

    mapping(address => uint256[]) public sellerNfts;

    uint256[] public currentBonds;
    uint256[] public allBonds;

    error NotSeller();
    error NotRasing();
    error NotEnded();
    error TransferFailed();

    constructor(address _turnstile, uint256 _id) TurnstileUser(_turnstile, _id) {
    }

    receive() external payable {
    }

    // -- view functions --
    function uri(uint256 ) public pure override returns (string memory) {
        return "";
    }

    function sellerInfo(address _seller) external view returns(uint256[] memory tokenIds) {
        return sellerNfts[_seller];
    }

    struct BondStatusResponse {
        uint256 tokenId;
        uint256 accrued;
        BondInfo info;
    }

    function bondStatus(uint256 _tokenId) public view returns(BondStatusResponse memory info) {
        return BondStatusResponse({
        tokenId : _tokenId,
        info : bondInfo[_tokenId],
        accrued : bondInfo[_tokenId].accrued + turnstile.balances(_tokenId)
        });
    }

    function sellerBondStatus(address _seller) external view returns(BondStatusResponse[] memory info) {
        uint256 turnstileBalance = turnstile.balanceOf(_seller);
        uint256 bondLength = sellerNfts[_seller].length;
        info = new BondStatusResponse[](bondLength + turnstileBalance);
        for(uint256 i = 0; i < bondLength; i++) {
            info[i] = bondStatus(sellerNfts[_seller][i]);
        }
        for(uint256 i = 0; i < turnstileBalance; i++) {
            info[bondLength + i] = bondStatus(turnstile.tokenOfOwnerByIndex(_seller, i));
        }
    }

    function allBondStatus() external view returns(BondStatusResponse[] memory info) {
        info = new BondStatusResponse[](allBonds.length);
        for(uint256 i = 0; i < allBonds.length; i++) {
            info[i] = bondStatus(allBonds[i]);
        }
    }

    function currentBondStatus() external view returns(BondStatusResponse[] memory info) {
        info = new BondStatusResponse[](currentBonds.length);
        for(uint256 i = 0; i < currentBonds.length; i++) {
            info[i] = bondStatus(currentBonds[i]);
        }
    }

    struct ClaimableBondResponse {
        uint256 tokenId;
        uint256 amount;
        BondStatusResponse bondStatus;
    }

    function getClaimableBond(address _user) external view returns(ClaimableBondResponse[] memory info) {
        ClaimableBondResponse[] memory data = new ClaimableBondResponse[](allBonds.length);
        uint256 resultlen = 0;
        for(uint256 i = 0; i < allBonds.length; i++) {
            uint256 claimable = claimableAmount(allBonds[i], _user);
            if(balanceOf[_user][allBonds[i]] > 0) {
                data[resultlen] = ClaimableBondResponse({
                tokenId : allBonds[i],
                amount : claimable,
                bondStatus : bondStatus(allBonds[i])
                });
                resultlen++;
            }
        }
        info = new ClaimableBondResponse[](resultlen);
        for(uint256 i = 0; i < resultlen; i++) {
            info[i] = data[i];
        }
    }

    // -- seller functions --
    /// @notice start a bond sale
    /// @dev withdrawn/canceld bond can not be restarted
    /// @param _tokenId the token id
    /// @param _softCap the minimum goal
    /// @param _hardCap the maximum goal
    /// @param _premium the premium
    function start(uint256 _tokenId, uint256 _softCap, uint256 _hardCap, uint256 _premium) external {
        require(bondInfo[_tokenId].raised == 0,"already sold"); // TODO check if this is valid
        require(_softCap <= _hardCap, "softCap > hardCap");
        turnstile.transferFrom(msg.sender, address(this), _tokenId);
        bondInfo[_tokenId] = BondInfo({
        status : Status.Rasing,
        seller : payable(msg.sender),
        softCap : _softCap,
        hardCap : _hardCap,
        premium : _premium,
        raised : 0,
        received : 0,
        accrued : 0
        }); // refresh the sale
        sellerNfts[msg.sender].push(_tokenId);
        currentBonds.push(_tokenId);
        for(uint256 i = 0; i < allBonds.length; i++) { // do not add duplicated token id to allBonds
            if(allBonds[i] == _tokenId) {
                return;
            }
        }
        allBonds.push(_tokenId);
    }

    /// @notice cancel the bond sale
    /// @dev cancel the bond sale and refund the seller
    /// @param _tokenId the token id
    function cancel(uint256 _tokenId) external payable {
        harvest(_tokenId);
        if(msg.sender != bondInfo[_tokenId].seller) {
            revert NotSeller();
        }
        if(bondInfo[_tokenId].status != Status.Rasing) {
            revert NotRasing();
        }
        require(bondInfo[_tokenId].raised <= bondInfo[_tokenId].softCap, "minGoal passed");
        require(bondInfo[_tokenId].received <= msg.value, "received > msg.value");
        uint256 refund = msg.value - bondInfo[_tokenId].received;
        bondInfo[_tokenId].received = 0;
        bondInfo[_tokenId].status = Status.Canceled;
        turnstile.safeTransferFrom(address(this), msg.sender, _tokenId);
        if(bondInfo[_tokenId].accrued > 0) {
            uint256 amount = bondInfo[_tokenId].accrued + refund;
            bondInfo[_tokenId].accrued = 0;
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "refund failed");
        }
        // remove _tokenId from sellerNfts
        uint256[] storage tokenIds = sellerNfts[msg.sender];
        for(uint256 i = 0; i < tokenIds.length; i++) {
            if(tokenIds[i] == _tokenId) {
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                break;
            }
        }

        for(uint256 i = 0; i < currentBonds.length; i++) {
            if(currentBonds[i] == _tokenId) {
                currentBonds[i] = currentBonds[currentBonds.length - 1];
                currentBonds.pop();
                break;
            }
        }
    }


    /// @notice end the bond sale
    /// @dev end the bond sale and receive the fund
    /// @param _tokenId the token id
    function end(uint256 _tokenId) external {
        if(msg.sender != bondInfo[_tokenId].seller) {
            revert NotSeller();
        }
        if(bondInfo[_tokenId].status != Status.Rasing) {
            revert NotRasing();
        }
        require(bondInfo[_tokenId].raised >= bondInfo[_tokenId].softCap, "minGoal not passed");

        bondInfo[_tokenId].status = Status.Ended;
        harvest(_tokenId);
        receiveFund(_tokenId);
    }

    /// @notice receive the fund
    /// @dev receive the fund and transfer canto to seller only after funding ended
    /// @param _tokenId the token id
    function receiveFund(uint256 _tokenId) public {
        if(msg.sender != bondInfo[_tokenId].seller) {
            revert NotSeller();
        }
        if(bondInfo[_tokenId].status == Status.Ended) {
            revert NotEnded();
        }
        uint256 receiving = bondInfo[_tokenId].raised - bondInfo[_tokenId].received;
        if(receiving > 0) {
            bondInfo[_tokenId].received += receiving;
            (bool success, ) = msg.sender.call{value: receiving}("");
            require(success, "receive failed");
        }
    }

    /// @notice withdraw turnstile nft
    /// @dev withdraw turnstile nft and refund the extra fund
    function withdraw(uint256 _tokenId) external {
        receiveFund(_tokenId); // receive the fund before withdrawal
        require(bondInfo[_tokenId].accrued >= (bondInfo[_tokenId].raised * (1e18 + bondInfo[_tokenId].premium)) / 1e18, "accrued < raised * (1 + premium)");
        turnstile.transferFrom(address(this), msg.sender, _tokenId);
        (bool success, ) = msg.sender.call{value : bondInfo[_tokenId].accrued - (bondInfo[_tokenId].raised * (1e18 + bondInfo[_tokenId].premium)) / 1e18}("");
        require(success, "refund failed");
        // remove _tokenId from sellerNfts
        uint256[] storage tokenIds = sellerNfts[msg.sender];
        for(uint256 i = 0; i < tokenIds.length; i++) {
            if(tokenIds[i] == _tokenId) {
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                break;
            }
        }
        for(uint256 i = 0; i < currentBonds.length; i++) {
            if(currentBonds[i] == _tokenId) {
                currentBonds[i] = currentBonds[currentBonds.length - 1];
                currentBonds.pop();
                break;
            }
        }
    }

    // -- buyer functions --
    /// @dev fund the bond
    /// @param _tokenId the token id
    function fund(uint256 _tokenId) external payable {
        harvest(_tokenId);
        if(bondInfo[_tokenId].status != Status.Rasing) {
            revert NotRasing();
        }
        uint256 amount = msg.value;
        if(bondInfo[_tokenId].raised + amount > bondInfo[_tokenId].hardCap) {
            amount = bondInfo[_tokenId].hardCap - bondInfo[_tokenId].raised;
        }
        bondInfo[_tokenId].raised += amount;
        _mint(msg.sender, _tokenId, amount, "");

        // end the bond if the bond is fully raised
        if(bondInfo[_tokenId].raised == bondInfo[_tokenId].hardCap) {
            harvest(_tokenId);
            bondInfo[_tokenId].status = Status.Ended;
        }

        if(msg.value - amount > 0) {
            //refund
            (bool success, ) = msg.sender.call{value: msg.value - amount}("");
            require(success, "refund failed");
        }
    }

    /// @notice claim the bond
    /// @dev claim amount will be calculated by the ratio of raised and accrued if not canceled
    /// @param _tokenId the token id
    function claim(uint256 _tokenId) external {
        require(bondInfo[_tokenId].status != Status.NotStarted && bondInfo[_tokenId].status != Status.Rasing, "not claimable yet");

        uint256 amount = balanceOf[msg.sender][_tokenId];
        uint256 accrueShare = 0;
        if( bondInfo[_tokenId].raised > 0) {
            accrueShare = bondInfo[_tokenId].accrued * amount / bondInfo[_tokenId].raised;
        }
        bondInfo[_tokenId].raised -= amount;
        _burn(msg.sender, _tokenId, amount);
        if(bondInfo[_tokenId].status == Status.Canceled) {
            // when canceled receive full refund
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "refund failed");
        } else {
            if(bondInfo[_tokenId].raised == 0) {
                return;
            }
            bondInfo[_tokenId].accrued -= accrueShare;

            (bool success, ) = msg.sender.call{value : accrueShare}("");
            require(success, "refund failed");
        }
    }

    /// @notice amount of token claimable
    /// @dev claim amount will be calculated by the ratio of raised and accrued if not canceled
    /// @param _tokenId the token id
    /// @param _user the user address
    function claimableAmount(uint256 _tokenId, address _user) public view returns(uint256) {
        uint256 amount = balanceOf[_user][_tokenId];
        if(bondInfo[_tokenId].status == Status.Canceled) {
            return amount;
        } else {
            if(bondInfo[_tokenId].raised == 0) {
                return 0;
            }
            return amount * bondInfo[_tokenId].accrued / (bondInfo[_tokenId].raised);
        }
    }

    // -- accrue functions --

    /// @notice accrue the bond from turnstile
    /// @dev accrue amount cannot exceed premium
    /// @param _tokenId the token id
    function harvest(uint256 _tokenId) public {
        uint256 balance = turnstile.balances(_tokenId);
        uint256 amount = balance;
        if(bondInfo[_tokenId].accrued + balance > bondInfo[_tokenId].raised * (1e18 + bondInfo[_tokenId].premium) / 1e18) {
            amount = (bondInfo[_tokenId].raised * (1e18 + bondInfo[_tokenId].premium) / 1e18) - bondInfo[_tokenId].accrued;
        }
        if(amount == 0){
            return;
        }
        turnstile.withdraw(_tokenId, payable(address(this)), amount);
        bondInfo[_tokenId].accrued += amount;
    }

    /// @notice force accrue to `_tokenId`
    /// @dev accrue amount can exceed premium
    /// @param _tokenId the token id
    function pay(uint256 _tokenId) public payable {
        // we don't care about exceeding premium
        bondInfo[_tokenId].accrued += msg.value;
    }
}
