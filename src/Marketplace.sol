// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IERC1155.sol";

contract Marketplace is IERC1155TokenReceiver {
    struct SaleInfo {
        uint256[] tokenIds;
        uint256[] tokenAmounts;
        uint256 tokenPrice;
        address seller;
        address tokenAddress;
    }

    IERC1155 public nft;

    uint256 public saleIdCounter;

    address public contractOwner;

    mapping(uint256 saleId => SaleInfo) public sales;
    mapping(uint256 saleId => mapping(uint256 tokenId => bool soldOut)) public tokenSoldOut;

    event CreateSale(uint256 indexed saleId, address indexed tokenAddress);
    event CancelSale(uint256 indexed saleId);
    event BuyTokens(uint256 indexed saleId, address indexed buyer, address indexed tokenAddress);
    event TokenSoldOut(uint256 indexed saleId, uint256 indexed tokenId);
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    function createSale(
        uint256[] calldata _tokenIds,
        uint256[] calldata _tokenAmounts,
        uint256 _tokenPrice,
        address _seller,
        address _tokenAddress
    ) external onlyOwner {
        require(_tokenAddress != address(0), "Cannot be zero address");
        require(_tokenIds.length == _tokenAmounts.length, "NFT IDs and amounts do not match");

        uint256 saleId = saleIdCounter;

        sales[saleId] = SaleInfo({
            tokenIds: _tokenIds,
            tokenAmounts: _tokenAmounts,
            tokenPrice: _tokenPrice,
            seller: _seller,
            tokenAddress: _tokenAddress
        });

        unchecked {
            ++saleIdCounter;
        }

        nft = IERC1155(_tokenAddress);

        uint256 numberOfTokens = _tokenAmounts.length;

        for (uint256 i; i < numberOfTokens; ++i) {
            uint256 tokenBalance = nft.balanceOf(_seller, _tokenIds[i]);
            require(tokenBalance != 0, "Seller is not a token owner");

            nft.safeTransferFrom(_seller, msg.sender, _tokenIds[i], _tokenAmounts[i], "");
        }

        emit CreateSale(saleId, _tokenAddress);
    }

    function cancelSale(uint256 _saleId) external onlyOwner {
        require(_saleId < saleIdCounter, "Sale does not exist");

        SaleInfo memory sale = sales[_saleId];

        uint256 numberOfTokens = sale.tokenAmounts.length;

        uint256 tokenId;
        uint256 tokenAmount;

        for (uint256 i; i < numberOfTokens;) {
            tokenId = sale.tokenIds[i];
            tokenAmount = sale.tokenAmounts[i];

            nft.safeTransferFrom(address(this), sale.seller, tokenId, tokenAmount, "");
        }

        emit CancelSale(_saleId);
    }

    function buy(uint256 _saleId, uint256[] memory _tokenIds, uint256[] memory _tokenAmountsToBuy) external payable {
        require(_saleId <= saleIdCounter, "Sale does not exist");
        require(_tokenIds.length == _tokenAmountsToBuy.length, "NFT IDs and amounts do not match");

        SaleInfo memory sale = sales[_saleId];

        uint256 numberOfTokens = _tokenAmountsToBuy.length;

        uint256 totalCost;

        for (uint256 i; i < numberOfTokens; ++i) {
            require(sale.tokenAmounts[i] != 0, "No tokens for sale");
            require(!tokenSoldOut[_saleId][_tokenIds[i]], "Token sold out");

            if (_tokenAmountsToBuy[i] == sale.tokenAmounts[i]) {
                tokenSoldOut[_saleId][_tokenIds[i]] = true;
                emit TokenSoldOut(_saleId, sale.tokenIds[i]);
            }

            unchecked {
                totalCost += sale.tokenPrice * _tokenAmountsToBuy[i];
            }
        }

        require(msg.sender.balance >= totalCost, "Insufficient balance");
        require(msg.value == totalCost, "Incorrect amount of ETH");

        (bool success,) = sale.seller.call{value: totalCost}("");
        require(success, "Transfer failed");

        nft.safeBatchTransferFrom(address(this), msg.sender, _tokenIds, _tokenAmountsToBuy, "");

        emit BuyTokens(_saleId, msg.sender, sale.tokenAddress);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        contractOwner = _newOwner;

        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
