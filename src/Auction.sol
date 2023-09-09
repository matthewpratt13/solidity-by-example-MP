// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IERC721.sol";

contract Auction is IERC721TokenReceiver {
    enum AuctionStatus {
        Inactive,
        Active
    }

    AuctionStatus public auctionStatus;
    uint256 public endTime;

    IERC721 public nft;
    address public nftAddress;
    address payable public seller;

    uint256 public startingPrice;
    uint256 private _highestBid;
    address private _highestBidder;

    mapping(address bidder => uint256 value) public bids;
    mapping(uint256 nftId => bool isSold) public nftsSold;

    event StartAuction(uint256 indexed startingPrice, uint256 indexed nftId, uint256 endTime);
    event Bid(uint256 indexed nftId);
    event CloseAuction(address indexed winnerAddress, uint256 indexed nftId, uint256 winningBidValue);
    event Withdraw(address indexed to, uint256 indexed amount);
    event SetTokenAddress(address indexed nftAddress);
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    modifier onlySeller() {
        require(msg.sender == seller, "Caller is not the seller");
        _;
    }

    modifier onlyActive() {
        require(auctionStatus == AuctionStatus.Active, "Auction is inactive");
        _;
    }

    modifier onlyInactive() {
        require(auctionStatus == AuctionStatus.Inactive, "Auction is active");
        _;
    }

    constructor(address _nftAddress) {
        require(_nftAddress != address(0), "Cannot be the zero address");

        nftAddress = _nftAddress;

        seller = payable(msg.sender);
        auctionStatus = AuctionStatus.Inactive;

        emit SetTokenAddress(_nftAddress);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function startAuction(uint256 _startingPrice, uint256 _nftId, uint256 _endTime) external onlySeller onlyInactive {
        require(!nftsSold[_nftId], "NFT already sold");
        require(_startingPrice != 0, "Starting price cannot be 0");
        require(block.timestamp < endTime, "Invalid end time");

        startingPrice = _startingPrice;

        nft = IERC721(nftAddress);

        nft.transferFrom(msg.sender, address(this), _nftId);

        auctionStatus = AuctionStatus.Active;

        endTime = _endTime;

        emit StartAuction(_startingPrice, _nftId, _endTime);
    }

    function bid(uint256 _nftId) external payable onlyActive {
        require(!nftsSold[_nftId], "NFT already sold");
        require(block.timestamp < endTime, "Auction has closed");
        require(msg.sender != seller, "Seller cannot bid on NFT");
        require(msg.value >= startingPrice, "Bid below starting price");
        require(msg.value > _highestBid, "Bid too low");

        _highestBidder = msg.sender;
        _highestBid = msg.value;

        bids[_highestBidder] = _highestBid;

        emit Bid(_nftId);
    }

    function closeAuction(uint256 _nftId) external onlySeller onlyActive {
        require(block.timestamp >= endTime, "Auction in progress");

        auctionStatus = AuctionStatus.Inactive;

        nftsSold[_nftId] = true;

        address recipient;

        if (_highestBidder != address(0)) {
            recipient = _highestBidder;
        } else {
            recipient = msg.sender;
        }

        nft.safeTransferFrom(address(this), recipient, _nftId);

        emit CloseAuction(recipient, _nftId, _highestBid);
    }

    function reclaimBid() external {
        require(msg.sender != _highestBidder, "Caller is highest bidder");

        uint256 withdrawalAmount = bids[msg.sender];

        bids[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: withdrawalAmount}("");

        require(success, "Transfer failed");

        emit Withdraw(msg.sender, withdrawalAmount);
    }

    function withdraw() external onlySeller onlyInactive {
        uint256 withdrawalAmount = _highestBid;

        bids[_highestBidder] = 0;

        (bool success,) = seller.call{value: withdrawalAmount}("");

        require(success, "Transfer failed");

        emit Withdraw(seller, withdrawalAmount);
    }

    function setTokenAddress(address _newAddress) external onlySeller onlyInactive {
        nftAddress = _newAddress;

        emit SetTokenAddress(_newAddress);
    }

    function transferOwnership(address payable _newSeller) external onlySeller onlyInactive {
        seller = _newSeller;

        emit OwnershipTransferred(msg.sender, _newSeller);
    }

    function getHighestBid() external view returns (uint256) {
        return bids[_highestBidder];
    }

    function getHighestBidder() external view returns (address) {
        return _highestBidder;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}
