// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/ERC20.sol";
import "src/CoinSwap.sol";

contract CoinSwapTest is Test {
    ERC20 public coinA;
    ERC20 public coinB;

    address public alice = vm.addr(1);
    address public bob = vm.addr(2);
    address public charlie = vm.addr(3);

    CoinSwap public coinSwap;

    event Swap(address indexed ownerA, address indexed ownerB, uint256 amountA, uint256 amountB);

    function setUp() public {
        coinA = new ERC20("Coin A", "COINA", 18);
        coinB = new ERC20("Coin B", "COINB", 18);

        coinA.mint(alice, 10_000);
        coinB.mint(bob, 10_000);

        coinSwap = new CoinSwap(coinA, alice, 1_000, coinB, bob, 2_000);
    }

    function testRevertWhenUnauthorizedCallerSwaps() public {
        vm.expectRevert("Caller is not authorized");

        vm.prank(charlie);
        coinSwap.swap();
    }

    function testRevertWhenCoinAAllowanceTooLowToSwap() public {
        vm.prank(alice);
        coinA.approve(address(coinSwap), 500);

        vm.expectRevert("Coin A allowance is too low");

        vm.prank(alice);
        coinSwap.swap();
    }

    function testRevertWhenCoinBAllowanceTooLowToSwap() public {
        vm.prank(alice);
        coinA.approve(address(coinSwap), 2_000);

        vm.prank(bob);
        coinB.approve(address(coinSwap), 1_000);

        vm.expectRevert("Coin B allowance is too low");

        vm.prank(bob);
        coinSwap.swap();
    }

    function testSwap() public {
        vm.prank(alice);
        coinA.approve(address(coinSwap), 2_000);

        vm.prank(bob);
        coinB.approve(address(coinSwap), 5_000);

        assertEq(coinA.balanceOf(alice), 10_000);
        assertEq(coinA.balanceOf(bob), 0);

        assertEq(coinB.balanceOf(alice), 0);
        assertEq(coinB.balanceOf(bob), 10_000);

        vm.prank(alice);
        coinSwap.swap();

        assertEq(coinA.balanceOf(alice), 9_000);
        assertEq(coinB.balanceOf(alice), 2_000);

        assertEq(coinA.balanceOf(bob), 1_000);
        assertEq(coinB.balanceOf(bob), 8_000);
    }

    function testEmitOnSwap() public {
        vm.prank(alice);
        coinA.approve(address(coinSwap), 2_000);

        vm.prank(bob);
        coinB.approve(address(coinSwap), 5_000);

        vm.expectEmit(true, true, false, false);
        emit Swap(alice, bob, 1_000, 2_000);

        vm.prank(alice);
        coinSwap.swap();
    }
}
