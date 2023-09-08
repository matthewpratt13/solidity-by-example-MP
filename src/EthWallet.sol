// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract EthWallet {
    event Withdraw(uint256 amount);

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint256 _amount) external {
        require(msg.sender == owner, "Caller is not the owner");

        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");

        emit Withdraw(_amount);
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}
