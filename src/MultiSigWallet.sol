// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract MultiSigWallet {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool isExecuted;
        uint256 numberOfConfirmations;
    }

    address[] public owners;
    Transaction[] public transactions;

    uint256 public numberOfConfirmationsRequired;

    mapping(address account => bool) public isOwner;
    mapping(uint256 txIndex => mapping(address owner => bool)) public isConfirmed;

    event UpdateBalance(uint256 indexed amount);
    event SubmitTransaction(uint256 indexed txIndex, address indexed to, uint256 indexed value, bytes data);
    event ExecuteTransaction(uint256 indexed txIndex);
    event ConfirmTransaction(uint256 indexed txIndex);
    event RevokeConfirmation(uint256 indexed txIndex);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Caller is not an owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].isExecuted, "Transaction already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Transaction already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint256 _numberOfConfirmationsRequired) {
        require(_owners.length > 0, "No owners found");
        require(
            _numberOfConfirmationsRequired > 0 && _numberOfConfirmationsRequired <= _owners.length,
            "Invalid number of required confirmations"
        );

        uint256 numberOfOwners = _owners.length;

        for (uint256 i; i < numberOfOwners;) {
            address owner = _owners[i];

            require(owner != address(0), "Owner is zero address");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;

            owners.push(owner);

            // max length of an array is `type(uint256).max`
            unchecked {
                ++i;
            }
        }

        numberOfConfirmationsRequired = _numberOfConfirmationsRequired;
    }

    receive() external payable {
        emit UpdateBalance(address(this).balance);
    }

    function submitTransaction(address _to, uint256 _value, bytes memory _data) external onlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({to: _to, value: _value, data: _data, isExecuted: false, numberOfConfirmations: 0})
        );

        emit SubmitTransaction(txIndex, _to, _value, _data);
    }

    function executeTransaction(uint256 _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.numberOfConfirmations >= numberOfConfirmationsRequired, "Insufficient confirmations");

        transaction.isExecuted = true;

        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);

        require(success, "Transaction failed");

        emit ExecuteTransaction(_txIndex);
    }

    function confirmTransaction(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        transaction.numberOfConfirmations++;

        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(_txIndex);
    }

    function revokeConfirmation(uint256 _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "Transaction not confirmed");

        // underflow impossible because confirmation is checked above
        unchecked {
            transaction.numberOfConfirmations--;
        }

        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(_txIndex);
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        external
        view
        returns (address to, uint256 value, bytes memory data, bool isExecuted, uint256 numberOfConfirmations)
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.isExecuted,
            transaction.numberOfConfirmations
        );
    }
}
