// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/ERC20.sol";

contract ERC20Test is Test {
    ERC20 public coin;

    address accountA = vm.addr(1);
    address accountB = vm.addr(2);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    function setUp() public {
        coin = new ERC20("Coin", "COIN", 18);
        coin.mint(address(this), 1_000_000);
    }

    function testERC20InvariantMetadata() public {
        assertEq(coin.name(), "Coin");
        assertEq(coin.symbol(), "COIN");
        assertEq(coin.decimals(), 18);
        assertEq(coin.totalSupply(), 1_000_000);
    }

    function testERC20Approve() public {
        assertEq(coin.allowance(address(this), accountA), 0);

        coin.approve(accountA, 1_000);

        assertEq(coin.allowance(address(this), accountA), 1_000);
    }

    function testEmitOnERC20Approve() public {
        vm.expectEmit(true, true, false, false);
        emit Approval(address(this), accountA, 1_000);

        coin.approve(accountA, 1_000);
    }

    function testERC20Transfer() public {
        coin.mint(accountA, 10_000);

        assertEq(coin.balanceOf(accountA), 10_000);
        assertEq(coin.balanceOf(accountB), 0);

        vm.prank(accountA);
        coin.transfer(accountB, 1_000);

        assertEq(coin.balanceOf(accountA), 9_000);
        assertEq(coin.balanceOf(accountB), 1_000);
    }

    function testEmitOnERC20Transfer() public {
        coin.mint(accountA, 10_000);

        vm.expectEmit(true, true, true, false);
        emit Transfer(accountA, accountB, 1_000);

        vm.prank(accountA);
        coin.transfer(accountB, 1_000);
    }

    function testERC20TransferFrom() public {
        coin.mint(accountA, 10_000);

        vm.prank(accountA);
        coin.approve(address(this), 1_000);

        coin.transferFrom(accountA, accountB, 1_000);

        assertEq(coin.balanceOf(accountA), 9_000);
        assertEq(coin.balanceOf(accountB), 1_000);
    }

    function testEmitOnERC20TransferFrom() public {
        coin.mint(accountA, 10_000);

        vm.prank(accountA);
        coin.approve(address(this), 1_000);

        vm.expectEmit(true, true, true, false);
        emit Transfer(accountA, accountB, 1_000);

        coin.transferFrom(accountA, accountB, 1_000);
    }

    function testRevertWhenNonOwnerMintsERC20() public {
        vm.expectRevert("Caller is not the owner");

        vm.prank(accountA);
        coin.mint(accountA, 10_000);
    }

    function testMintERC20() public {
        assertEq(coin.balanceOf(accountA), 0);
        assertEq(coin.totalSupply(), 1_000_000);

        coin.mint(accountA, 10_000);

        assertEq(coin.balanceOf(accountA), 10_000);
        assertEq(coin.totalSupply(), 1_010_000);
    }

    function testEmitOnERC20Mint() public {
        vm.expectEmit(true, true, true, false);
        emit Transfer(address(0), accountA, 10_000);

        coin.mint(accountA, 10_000);
    }

    function testRevertWhenNonOwnerBurnsERC20() public {
        coin.mint(accountA, 10_000);

        vm.expectRevert("Caller is not the owner");

        vm.prank(accountA);
        coin.burn(accountA, 1_000);
    }

    function testBurnERC20() public {
        coin.mint(accountA, 10_000);

        assertEq(coin.balanceOf(accountA), 10_000);
        assertEq(coin.totalSupply(), 1_010_000);

        coin.burn(accountA, 1_000);

        assertEq(coin.balanceOf(accountA), 9_000);
        assertEq(coin.totalSupply(), 1_009_000);
    }

    function testEmitOnERC20Burn() public {
        coin.mint(accountA, 10_000);

        vm.expectEmit(true, true, true, false);
        emit Transfer(accountA, address(0), 1_000);

        coin.burn(accountA, 1_000);
    }

    function testERC20TransferOwnership() public {
        assertEq(coin.owner(), address(this));

        coin.transferOwnership(accountA);

        assertEq(coin.owner(), accountA);
    }

    function testEmitOnERC20TransferOwnership() public {
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(address(this), accountA);

        coin.transferOwnership(accountA);
    }
}
