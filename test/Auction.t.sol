// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/Auction.sol";

contract AuctionTest is Test {
    address public nftAddress;

    Auction public auction;

    function setUp() public {
        auction = new Auction(nftAddress);
    }
}
