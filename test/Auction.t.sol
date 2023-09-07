// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/ERC721.sol";
import "src/Auction.sol";

contract NFT is ERC721 {
    constructor() ERC721("Token", "NFT") {}

    function mint(address _to, uint256 _id) public {
        _mint(_to, _id);
    }
}

contract AuctionTest is Test {
    Auction public auction;
    NFT public nft;

    function setUp() public {
        nft = new NFT();
        auction = new Auction(address(nft));
    }
}
