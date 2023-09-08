// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/EthWallet.sol";

contract EthWalletTest is Test {
    EthWallet public wallet;

    address nonOwner = vm.addr(1);

    event Withdraw(uint256 amount);

    receive() external payable {}

    function setUp() public {
        wallet = new EthWallet();

        vm.deal(address(this), 1 ether);
        vm.deal(address(wallet), 1 ether);
    }

    function testRevertWhenNonOwnerWithdraws() public {
        vm.expectRevert("Caller is not the owner");

        vm.prank(nonOwner);
        wallet.withdraw(0.5 ether);
    }

    function testWithdraw() public {
        assertEq(address(this).balance, 1 ether);
        assertEq(address(wallet).balance, 1 ether);

        wallet.withdraw(0.5 ether);

        assertEq(address(this).balance, 1.5 ether);
        assertEq(address(wallet).balance, 0.5 ether);
    }

    function testEmitOnWithdraw() public {
        vm.expectEmit(true, false, false, false);
        emit Withdraw(0.5 ether);

        wallet.withdraw(0.5 ether);
    }

    function testBalance() public {
        assertEq(address(wallet).balance, 1 ether);
        assertEq(address(wallet).balance, wallet.balance());
    }
}
