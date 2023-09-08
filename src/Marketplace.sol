// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC1155 {
    function setApprovalForAll(address operator, bool isApproved) external;
    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

contract Marketplace {
    enum SaleStatus {
        Inactive,
        Active
    }

    struct SaleInfo {
        SaleStatus saleStatus;
        uint256[] tokenIds;
        uint256[] tokenAmountsForSale;
        uint256[] tokenAmountsSold;
        uint256 tokenPrice;
        address tokenAddress;
        address seller;
    }

    uint256 public saleIdCounter;

    mapping(uint256 saleId => SaleInfo) public sales;

    event CreateSale(uint256 indexed saleId, address indexed tokenAddress, uint256 tokenPrice);

    event CancelSale(uint256 indexed saleId);

    function createSale(
        address _tokenAddress,
        uint256[] calldata _tokenIds,
        uint256[] calldata _tokenAmountsForSale,
        uint256 _tokenPrice
    ) external {
        require(_tokenAddress != address(0), "Cannot be zero address");
        require(_tokenIds.length == _tokenAmountsForSale.length, "NFT IDs and amounts do not match");

        uint256[] memory tokenAmountsSold = new uint256[](_tokenIds.length);

        uint256 saleId = saleIdCounter;

        sales[saleId] = SaleInfo({
            saleStatus: SaleStatus.Active,
            tokenIds: _tokenIds,
            tokenAmountsForSale: _tokenAmountsForSale,
            tokenAmountsSold: tokenAmountsSold,
            tokenPrice: _tokenPrice,
            tokenAddress: _tokenAddress,
            seller: msg.sender
        });

        unchecked {
            ++saleIdCounter;
        }

        IERC1155 nft = IERC1155(_tokenAddress);

        nft.safeBatchTransferFrom(msg.sender, address(this), _tokenIds, _tokenAmountsForSale, "");

        emit CreateSale(saleId, _tokenAddress, _tokenPrice);
    }

    function cancelSale(uint256 _saleId) external {
        require(_saleId < saleIdCounter, "Sale does not exist");

        SaleInfo storage sale = sales[_saleId];

        require(sale.saleStatus == SaleStatus.Active, "Sale is inactive");

        require(msg.sender == sale.seller, "Caller must be sale creator");

        sales[_saleId].saleStatus = SaleStatus.Inactive;

        IERC1155 nft = IERC1155(sale.tokenAddress);

        nft.safeBatchTransferFrom(address(this), msg.sender, sale.tokenIds, sale.tokenAmountsForSale, "");

        emit CancelSale(_saleId);
    }
}
