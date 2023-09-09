// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool isApproved);

    function approve(address spender, uint256 id) external;
    function setApprovalForAll(address operator, bool isApproved) external;
    function transferFrom(address from, address to, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external;
    function isApprovedForAll(address _owner, address _spender) external view returns (bool);
    function ownerOf(uint256 _id) external view returns (address owner);
    function balanceOf(address _owner) external view returns (uint256);
}

interface IERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4);
}
