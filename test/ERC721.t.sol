// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/ERC721.sol";

contract MockERC721 is ERC721 {
    address public contractOwner;

    constructor() ERC721("Token", "NFT") {
        contractOwner = msg.sender;
    }

    function mint(address _to, uint256 _id) public {
        require(msg.sender == contractOwner, "Caller is not the contract owner");

        _mint(_to, _id);
    }

    function burn(uint256 _id) public {
        require(msg.sender == contractOwner, "Caller is not the contract owner");

        _burn(_id);
    }
}

contract ERC721Test is ERC721TokenReceiver, Test {
    MockERC721 public token;

    address accountA = vm.addr(1);
    address accountB = vm.addr(2);

    function setUp() public {
        token = new MockERC721();
        token.mint(address(this), 10);
    }

    function testERC721InvariantMetadata() public {
        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "NFT");
    }

    function testRevertWhenNonOwnerApprovesERC721() public {}

    function testRevertWhenUnauthorizedCallerApprovesERC721() public {}

    function testERC721Approve() public {}

    function testEmitOnERC721Aprove() public {}

    function testRevertWhenNonOwnerTransfersERC721() public {}

    function testRevertOnTransferringERC721ToZeroAddress() public {}

    function testRevertWhenUnauthorizedCallerTransfersERC721() public {}

    function testERC721TransferFrom() public {}

    function testEmitOnERC721TransferFrom() public {}

    function testRevertOnSafeTransferringToNonERC721Receiver() public {}

    function testRevertWhenNonOwnerMintsERC721() public {}

    function testRevertOnMintingERC721ToZeroAddress() public {}

    function testRevertOnMintingExistingERC721() public {}

    function testEmitOnERC721Mint() public {}

    function testRevertOnSafeMintingToNonERC721Receiver() public {}

    function testRevertWhenNonOwnerBurnsERC721() public {}

    function testRevertOnBurningNonexistentERC721() public {}

    function testERC721Burn() public {}

    function testEmitOnERC721Burn() public {}
}
