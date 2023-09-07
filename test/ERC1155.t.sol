// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/ERC1155.sol";

contract MockERC1155 is ERC1155 {
    address public contractOwner;

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Caller is not the contract owner");
        _;
    }

    constructor() ERC1155("") {
        contractOwner = msg.sender;
    }

    function mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) public onlyOwner {
        _mint(_to, _id, _amount, _data);
    }

    function batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
        public
        onlyOwner
    {
        _batchMint(_to, _ids, _amounts, _data);
    }

    function burn(address _from, uint256 _id, uint256 _amount) public onlyOwner {
        _burn(_from, _id, _amount);
    }

    function batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts) public onlyOwner {
        _batchBurn(_from, _ids, _amounts);
    }
}

contract ERC1155Test is ERC1155TokenReceiver, Test {
    MockERC1155 public token;

    address accountA = vm.addr(1);
    address accountB = vm.addr(2);

    function setUp() public {
        token = new MockERC1155();

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
}
