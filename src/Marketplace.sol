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
    struct SaleInfo {
        uint256[] tokenIds;
        uint256[] tokenAmountsForSale;
        uint256[] tokenAmountsSold;
        uint256 tokenPrice;
        address tokenAddress;
        address seller;
    }

    uint256 public saleIdCounter;

    address public contractOwner;

    mapping(uint256 saleId => SaleInfo) public sales;

    event CreateSale(uint256 indexed saleId, address indexed tokenAddress, uint256 tokenPrice);

    event CancelSale(uint256 indexed saleId);

    event TokenSoldOut(uint256 indexed saleId, uint256 indexed tokenId);

    event BuyTokens(uint256 indexed saleId, address indexed buyer, address indexed tokenAddress);

    event Withdraw(address indexed to, uint256 indexed amount);

    constructor() {
        contractOwner = msg.sender;
    }

    receive() external payable {}

    function createSale(
        address _tokenAddress,
        uint256[] calldata _tokenIds,
        uint256[] calldata _tokenAmountsForSale,
        uint256 _tokenPrice
    ) external {
        require(msg.sender == contractOwner, "Caller is not the owner");
        require(_tokenAddress != address(0), "Cannot be zero address");
        require(_tokenIds.length == _tokenAmountsForSale.length, "NFT IDs and amounts do not match");

        uint256[] memory tokenAmountsSold = new uint256[](_tokenIds.length);

        uint256 saleId = saleIdCounter;

        sales[saleId] = SaleInfo({
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
        require(msg.sender == contractOwner, "Caller is not the owner");

        require(_saleId < saleIdCounter, "Sale does not exist");

        SaleInfo storage sale = sales[_saleId];

        require(msg.sender == sale.seller, "Caller must be sale creator");

        IERC1155 nft = IERC1155(sale.tokenAddress);

        nft.safeBatchTransferFrom(address(this), msg.sender, sale.tokenIds, sale.tokenAmountsForSale, "");

        emit CancelSale(_saleId);
    }

    function buy(uint256 _saleId, uint256[] memory _tokenIds, uint256[] memory _tokenAmountsToBuy) external payable {
        require(_saleId <= saleIdCounter, "Sale does not exist");

        require(_tokenIds.length == _tokenAmountsToBuy.length, "NFT IDs and amounts do not match");

        SaleInfo storage sale = sales[_saleId];

        uint256 tokenAmounts = _tokenAmountsToBuy.length;

        uint256[] memory availableTokens = new uint256[](tokenAmounts);

        uint256 tokenPrice = sale.tokenPrice;

        uint256 totalCost;

        for (uint256 i; i < tokenAmounts;) {
            availableTokens[i] = sale.tokenAmountsForSale[i] - sale.tokenAmountsSold[i];

            require(availableTokens[i] != 0, "Tokens not available");

            require(availableTokens[i] >= _tokenAmountsToBuy[i], "Too few tokens available");

            sale.tokenAmountsForSale[i] -= _tokenAmountsToBuy[i];

            sale.tokenAmountsSold[i] += _tokenAmountsToBuy[i];

            unchecked {
                totalCost += tokenPrice * _tokenAmountsToBuy[i];
            }

            if (_tokenAmountsToBuy[i] == availableTokens[i]) {
                emit TokenSoldOut(_saleId, sale.tokenIds[i]);
            }

            unchecked {
                ++i;
            }
        }

        require(msg.sender.balance >= totalCost, "Insufficient balance");

        require(msg.value == totalCost, "Incorrect amount of ETH");

        (bool success,) = address(this).call{value: msg.value}("");

        require(success, "Transfer failed");

        IERC1155 nft = IERC1155(sale.tokenAddress);

        nft.safeBatchTransferFrom(address(this), msg.sender, _tokenIds, _tokenAmountsToBuy, "");

        emit BuyTokens(_saleId, msg.sender, sale.tokenAddress);
    }

    function withdraw(uint256 _saleId, uint256 _amount) external {
        require(msg.sender == contractOwner, "Caller is not the owner");

        SaleInfo memory sale = sales[_saleId];

        uint256 totaltokenAmountsSold = sale.tokenAmountsSold.length;

        uint256 availableBalance;

        for (uint256 i; i < totaltokenAmountsSold; ++i) {
            availableBalance += sale.tokenAmountsSold[i] * sale.tokenPrice;
        }

        require(_amount <= availableBalance, "Insufficient balance");

        (bool success,) = sale.seller.call{value: _amount}("");

        require(success, "Transfer failed");

        emit Withdraw(msg.sender, _amount);
    }
}
