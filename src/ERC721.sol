// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract ERC721 {
    string public name;
    string public symbol;

    address public contractOwner;

    mapping(uint256 id => address owner) private _ownerOf;
    mapping(address owner => uint256 amount) private _balanceOf;
    mapping(uint256 id => address operator) private _approved;
    mapping(address owner => mapping(address operator => bool isApproved)) private _isApprovedForAll;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool isApproved);
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Caller is not the contract owner");
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;

        contractOwner = msg.sender;
    }

    function approve(address _spender, uint256 _id) external {
        address owner = _ownerOf[_id];

        require(msg.sender == owner || _isApprovedForAll[owner][msg.sender], "Caller not authorized");

        _approved[_id] = _spender;

        emit Approval(owner, _spender, _id);
    }

    function setApprovalForAll(address _operator, bool _isApproved) external {
        _isApprovedForAll[msg.sender][_operator] = _isApproved;

        emit ApprovalForAll(msg.sender, _operator, _isApproved);
    }

    function safeTransferFrom(address _from, address _to, uint256 _id) external {
        transferFrom(_from, _to, _id);

        require(
            _to.code.length == 0
                || ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "Transfer to non-ERC721Receiver"
        );
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, bytes calldata _data) external {
        transferFrom(_from, _to, _id);

        require(
            _to.code.length == 0
                || ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _id, _data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "Transfer to non-ERC721 receiver"
        );
    }

    function transferFrom(address _from, address _to, uint256 _id) public {
        require(_from == _ownerOf[_id], "Transfer from non-owner");
        require(_to != address(0), "Transfer to zero address");

        require(
            msg.sender == _from || _isApprovedForAll[_from][msg.sender] || msg.sender == _approved[_id],
            "Caller not authorized"
        );

        // underflow is impossible because ownership is checked above
        // recipient balance cannot realistically overflow
        unchecked {
            _balanceOf[_from]--;
            _balanceOf[_to]++;
        }

        _ownerOf[_id] = _to;

        delete _approved[_id];

        emit Transfer(_from, _to, _id);
    }

    function safeMint(address _to, uint256 _id, bytes memory _data) external onlyOwner {
        _mint(_to, _id);

        require(
            _to.code.length == 0
                || ERC721TokenReceiver(_to).onERC721Received(msg.sender, address(0), _id, _data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "Transfer to non-ERC721 receiver"
        );
    }

    function burn(uint256 _id) external onlyOwner {
        address owner = _ownerOf[_id];

        require(owner != address(0), "Token not minted");

        // underflow is impossible because ownership is checked above
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[_id];
        delete _approved[_id];

        emit Transfer(owner, address(0), _id);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        contractOwner = _newOwner;

        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    function ownerOf(uint256 _id) external view returns (address owner) {
        require((owner = _ownerOf[_id]) != address(0), "Token not minted");
    }

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "Owner is zero address");

        return _balanceOf[_owner];
    }

    function getApproved(uint256 _id) external view returns (address) {
        require(_ownerOf[_id] != address(0), "Token not minted");

        return _approved[_id];
    }

    function isApprovedForAll(address _owner, address _spender) external view returns (bool) {
        return _isApprovedForAll[_owner][_spender];
    }

    function _mint(address _to, uint256 _id) internal {
        require(_to != address(0), "Mint to zero address");
        require(_ownerOf[_id] == address(0), "Token already minted");

        // overflow unrealistic
        unchecked {
            _balanceOf[_to]++;
        }

        _ownerOf[_id] = _to;

        emit Transfer(address(0), _to, _id);
    }

    // ERC-165 interface logic

    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return _interfaceId == 0x01ffc9a7 // ERC-165 Interface ID for ERC165
            || _interfaceId == 0x80ac58cd // ERC-165 Interface ID for ERC721
            || _interfaceId == 0x5b5e139f; // ERC-165 Interface ID for ERC721Metadata
    }
}

// contract that accepts ERC-721 tokens

contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}
