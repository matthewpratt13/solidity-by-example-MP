// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";

contract CoinSwap {
    ERC20 public coinA;
    address public ownerA;
    uint256 public amountA;

    ERC20 public coinB;
    address public ownerB;
    uint256 public amountB;

    event Swap(address indexed ownerA, address indexed ownerB, uint256 amountA, uint256 amountB);

    constructor(ERC20 _coinA, address _ownerA, uint256 _amountA, ERC20 _coinB, address _ownerB, uint256 _amountB) {
        coinA = _coinA;
        ownerA = _ownerA;
        amountA = _amountA;

        coinB = _coinB;
        ownerB = _ownerB;
        amountB = _amountB;
    }

    function swap() external {
        require(msg.sender == ownerA || msg.sender == ownerB, "Caller is not authorized");

        require(coinA.allowance(ownerA, address(this)) >= amountA, "Coin A allowance is too low");

        require(coinB.allowance(ownerB, address(this)) >= amountB, "Coin B allowance is too low");

        _safeTransferFrom(coinA, ownerA, ownerB, amountA);
        _safeTransferFrom(coinB, ownerB, ownerA, amountB);

        emit Swap(ownerA, ownerB, amountA, amountB);
    }

    function _safeTransferFrom(ERC20 _coin, address _from, address _to, uint256 _amount) private {
        bool success = _coin.transferFrom(_from, _to, _amount);
        require(success, "Transfer failed");
    }
}
