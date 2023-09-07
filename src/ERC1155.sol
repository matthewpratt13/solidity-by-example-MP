// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract ERC1155 {
    string private _uri;

    mapping(address owner => mapping(uint256 id => uint256 amount)) private _balanceOf;
    mapping(address owner => mapping(address operator => bool isApproved)) private _isApprovedForAll;

    event TransferSingle(
        address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount
    );
    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );
    event ApprovalForAll(address indexed owner, address indexed operator, bool isApproved);
    event URI(string value, uint256 indexed id);

    constructor(string memory uri_) {
        _uri = uri_;
    }

    function setApprovalForAll(address _operator, bool _isApproved) public {
        _isApprovedForAll[msg.sender][_operator] = _isApproved;

        emit ApprovalForAll(msg.sender, _operator, _isApproved);
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) public {
        require(msg.sender == _from || _isApprovedForAll[_from][msg.sender], "Caller not authorized");

        _balanceOf[_from][_id] -= _amount;
        _balanceOf[_to][_id] += _amount;

        emit TransferSingle(msg.sender, _from, _to, _id, _amount);

        require(
            _to.code.length == 0
                ? _to != address(0)
                : ERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data)
                    == ERC1155TokenReceiver.onERC1155Received.selector,
            "Transfer to non-ERC1155 receiver"
        );
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) public {
        require(_ids.length == _amounts.length, "Lengths do not match");

        require(msg.sender == _from || _isApprovedForAll[_from][msg.sender], "Caller not authorized");

        uint256 id;
        uint256 amount;
        uint256 idsLength = _ids.length;

        for (uint256 i; i < idsLength;) {
            id = _ids[i];
            amount = _amounts[i];

            _balanceOf[_from][id] -= amount;
            _balanceOf[_to][id] += amount;

            // max length of an array is `type(uint256).max`
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);

        require(
            _to.code.length == 0
                ? _to != address(0)
                : ERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data)
                    == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "Transfer to non-ERC1155 receiver"
        );
    }

    function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) internal {
        _balanceOf[_to][_id] += _amount;

        emit TransferSingle(msg.sender, address(0), _to, _id, _amount);

        require(
            _to.code.length == 0
                ? _to != address(0)
                : ERC1155TokenReceiver(_to).onERC1155Received(msg.sender, address(0), _id, _amount, _data)
                    == ERC1155TokenReceiver.onERC1155Received.selector,
            "Transfer to non-ERC1155 receiver"
        );
    }

    function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) internal {
        uint256 idsLength = _ids.length;

        require(idsLength == _amounts.length, "Lengths do not match");

        for (uint256 i; i < idsLength;) {
            _balanceOf[_to][_ids[i]] += _amounts[i];

            // max length of an array is `type(uint256).max`
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), _to, _ids, _amounts);

        require(
            _to.code.length == 0
                ? _to != address(0)
                : ERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, address(0), _ids, _amounts, _data)
                    == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "Transfer to non-ERC1155 receiver"
        );
    }

    function _burn(address _from, uint256 _id, uint256 _amount) internal {
        _balanceOf[_from][_id] -= _amount;

        emit TransferSingle(msg.sender, _from, address(0), _id, _amount);
    }

    function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts) internal {
        uint256 idsLength = _ids.length;

        require(idsLength == _amounts.length, "Lengths do not match");

        for (uint256 i = 0; i < idsLength;) {
            _balanceOf[_from][_ids[i]] -= _amounts[i];

            // max length of an array is `type(uint256).max`
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, _from, address(0), _ids, _amounts);
    }

    function balanceOf(address _owner, uint256 _id) public view returns (uint256) {
        require(_owner != address(0), "Owner is zero address");

        return _balanceOf[_owner][_id];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        public
        view
        returns (uint256[] memory balances)
    {
        require(_owners.length == _ids.length, "Lengths do not match");

        balances = new uint256[](_owners.length);

        // incrementing array index cannot overflow
        unchecked {
            for (uint256 i; i < _owners.length; ++i) {
                balances[i] = _balanceOf[_owners[i]][_ids[i]];
            }
        }
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _isApprovedForAll[_owner][_operator];
    }

    function uri(uint256 _id) public view returns (string memory) {}

    // ERC-165 interface logic

    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return _interfaceId == 0x01ffc9a7 // ERC-165 Interface ID for ERC165
            || _interfaceId == 0xd9b67a26 // ERC-165 Interface ID for ERC1155
            || _interfaceId == 0x0e89341c; // ERC-165 Interface ID for ERC1155MetadataURI
    }
}

// contract that accepts ERC-1155 tokens

contract ERC1155TokenReceiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}
