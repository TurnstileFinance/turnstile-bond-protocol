// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import "./ICSR.sol";

contract TurnstileBond is TurnstileUser, ERC1155 {
    struct BondInfo {
        address payable seller;
        uint256 minGoal;
        uint256 maxGoal;
        uint256 premium;
        uint256 raised;
        uint256 received;
        uint256 accrued;
        bool canceled;
    }

    mapping(uint256 => BondInfo) public bondInfo;

    error NotSeller();
    error Canceled();
    error TransferFailed();

    constructor(address _turnstile, uint256 _id) TurnstileUser(_turnstile, _id) {
    }

    receive() external payable {
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return "";
    }

    function start(uint256 _tokenId, uint256 _minGoal, uint256 _maxGoal, uint256 _premium) external {
        require(bondInfo[_tokenId].raised == 0,"already sold"); // TODO check if this is valid
        turnstile.transferFrom(msg.sender, address(this), _tokenId);
        bondInfo[_tokenId] = BondInfo({
            seller : payable(msg.sender),
            minGoal : _minGoal,
            maxGoal : _maxGoal,
            premium : _premium,
            raised : 0,
            received : 0,
            accrued : 0,
            canceled: false
        }); // refresh the sale
    }

    function cancel(uint256 _tokenId) external payable {
        harvest(_tokenId);
        if(msg.sender != bondInfo[_tokenId].seller) {
            revert NotSeller();
        }
        if(bondInfo[_tokenId].canceled) {
            revert Canceled();
        }
        require(bondInfo[_tokenId].raised <= bondInfo[_tokenId].minGoal, "minGoal passed");
        bondInfo[_tokenId].canceled = true;
        turnstile.safeTransferFrom(address(this), msg.sender, _tokenId);
        if(bondInfo[_tokenId].accrued > 0) {
            uint256 amount = bondInfo[_tokenId].accrued;
            bondInfo[_tokenId].accrued = 0;
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "refund failed");
        }
    }

    function receive(uint256 _tokenId) external {
        harvest(_tokenId);
        if(msg.sender != bondInfo[_tokenId].seller) {
            revert NotSeller();
        }
        if(bondInfo[_tokenId].canceled) {
            revert Canceled();
        }
        (bool success, ) = bondInfo[_tokenId].seller.call{value: bondInfo[_tokenId].raised - bondInfo[_tokenId].received }("");
        require(success, "receive failed");
    }

    function fund(uint256 _tokenId) external payable {
        harvest(_tokenId);
        if(bondInfo[_tokenId].canceled) {
            revert Canceled();
        }
        require(bondInfo[_tokenId].accrued < bondInfo[_tokenId].raised, "accrued >= raised");
        uint256 amount = msg.value;
        if(bondInfo[_tokenId].raised + amount > bondInfo[_tokenId].maxGoal) {
            amount = bondInfo[_tokenId].maxGoal - bondInfo[_tokenId].raised;
        }
        bondInfo[_tokenId].raised += amount;
        _mint(msg.sender, _tokenId, amount, "");
        if(msg.value - amount > 0) {
            //refund
            (bool success, ) = msg.sender.call{value: msg.value - amount}("");
            require(success, "refund failed");
        }
    }
    
    function claim(uint256 _tokenId) external {
        harvest(_tokenId);
        uint256 amount = balanceOf[msg.sender][_tokenId];
        bondInfo[_tokenId].raised -= amount;
        _burn(msg.sender, _tokenId, amount);
        if(bondInfo[_tokenId].canceled) {
            // when canceled receive full refund
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "refund failed");
        } else {
            (bool success, ) = msg.sender.call{value : amount * bondInfo[_tokenId].accrued / (bondInfo[_tokenId].raised)}("");
            require(success, "refund failed");
        }
    }

    function claimableAmount(uint256 _tokenId, address _user) external view returns(uint256) {
        uint256 amount = balanceOf[msg.sender][_tokenId];
        if(bondInfo[_tokenId].canceled) {
            return amount;
        } else {
            return amount * bondInfo[_tokenId].accrued / (bondInfo[_tokenId].raised);
        }
    }

    function harvest(uint256 _tokenId) public {
        uint256 balance = turnstile.balances(_tokenId);
        uint256 amount = balance;
        if(bondInfo[_tokenId].accrued + balance > bondInfo[_tokenId].raised * (1e18 + bondInfo[_tokenId].premium) / 1e18) {
            amount = (bondInfo[_tokenId].raised * (1e18 + bondInfo[_tokenId].premium) / 1e18) - bondInfo[_tokenId].accrued;
        }
        turnstile.withdraw(_tokenId, payable(address(this)), amount);
        bondInfo[_tokenId].accrued += amount;
    }

    function withdraw(uint256 _tokenId) public {
        harvest(_tokenId);
        if(msg.sender != bondInfo[_tokenId].seller) {
            revert NotSeller();
        }
        require(bondInfo[_tokenId].accrued >= bondInfo[_tokenId].raised * (1e18 + bondInfo[_tokenId].premium) / 1e18, "raised too small");
        turnstile.transferFrom(address(this), msg.sender, _tokenId);
        (bool success, ) = msg.sender.call{value : bondInfo[_tokenId].accrued - bondInfo[_tokenId].raised * (1e18 + bondInfo[_tokenId].premium) / 1e18}("");
        require(success, "refund failed");
    }

    function pay(uint256 _tokenId) public payable {
        // we don't care about exceeding premium
        bondInfo[_tokenId].accrued += msg.value;
    }
}
