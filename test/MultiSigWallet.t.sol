// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    address public accountA = vm.addr(1);
    address public accountB = vm.addr(2);
    address public accountC = vm.addr(3);

    MultiSigWallet public wallet;

    function setUp() public {
        address[] memory accounts = new address[](3);

        accounts[0] = accountA;
        accounts[1] = accountB;
        accounts[2] = accountC;

        wallet = new MultiSigWallet(accounts, 3);
    }
}
