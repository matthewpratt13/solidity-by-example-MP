// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/ERC1155.sol";

contract ERC1155Test is ERC1155TokenReceiver, Test {
    ERC1155 public token;

    address accountA = vm.addr(1);
    address accountB = vm.addr(2);

    function setUp() public {
        token = new ERC1155("");

        uint256[] memory ids2To4 = new uint256[](3);
        uint256[] memory amounts2To4 = new uint256[](3);

        ids2To4[0] = 2;
        ids2To4[1] = 3;
        ids2To4[2] = 4;

        amounts2To4[0] = 2;
        amounts2To4[1] = 3;
        amounts2To4[2] = 4;

        token.mint(address(this), 1, 1, "");
        token.batchMint(address(this), ids2To4, amounts2To4, "");
    }

    function testRevertWhenNonOwnerTransfersERC1155() public {}

    function testRevertWhenUnauthorizedCallerTransfersERC1155() public {}

    function testERC1155SafeTransferFrom() public {}

    function testEmitOnERC1155SafeTransferFrom() public {}

    function testRevertOnTransferringToNonERC1155Receiver() public {}

    function testRevertOnBatchTransferringUnmatchingERC1155IdsAndAmounts() public {}

    function testRevertWhenNonOwnerBatchTransfersERC1155() public {}

    function testRevertWhenUnauthorizedCallerBatchTransfersERC1155() public {}

    function testERC1155SafeBatchTransferFrom() public {}

    function testEmitOnERC1155SafeBatchTransferFrom() public {}

    function testRevertOnBatchTransferringToNonERC1155Receiver() public {}

    function testERC1155Mint() public {}

    function testEmitOnERC1155Mint() public {}

    function testRevertOnMintingERC1155ToNonERC1155Receiver() public {}

    function testRevertOnBatchMintingUnmatchingERC1155IdsAndAmounts() public {}

    function testERC1155BatchMint() public {}

    function testEmitOnERC1155BatchMint() public {}

    function testRevertOnBatchMintingToNonERC1155Receiver() public {}

    function testERC1155Burn() public {}

    function testEmitOnERC1155Burn() public {}

    function testRevertOnBatchBurningUnmatchingERC1155IdsAndAmounts() public {}

    function testERC1155BatchBurn() public {}

    function testEmitOnERC1155BatchBurn() public {}

    function testERC1155TransferOwnership() public {}

    function testEmitOnERC1155TransferOwnership() public {}
}
