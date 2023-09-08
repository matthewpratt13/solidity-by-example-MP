// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract ERC20 {
    string public name;
    string public symbol;
    uint256 public immutable decimals;
    uint256 public totalSupply;

    address public owner;

    mapping(address owner => uint256 amount) private _balanceOf;
    mapping(address owner => mapping(address spender => uint256 amount)) private _allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        owner = msg.sender;
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        _allowance[msg.sender][_spender] = _amount;

        emit Approval(msg.sender, _spender, _amount);

        return true;
    }

    function transfer(address _to, uint256 _amount) external returns (bool) {
        _balanceOf[msg.sender] -= _amount;

        // cannot overflow because total balances cannot exceed `type(uint256).max`
        unchecked {
            _balanceOf[_to] += _amount;
        }

        emit Transfer(msg.sender, _to, _amount);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool) {
        _allowance[_from][msg.sender] -= _amount;

        _balanceOf[_from] -= _amount;

        // cannot overflow because total balances cannot exceed `type(uint256).max`
        unchecked {
            _balanceOf[_to] += _amount;
        }

        emit Transfer(_from, _to, _amount);

        return true;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "Owner is zero address");

        return _balanceOf[_owner];
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return _allowance[_owner][_spender];
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        totalSupply += _amount;

        // cannot overflow because total balances cannot exceed `type(uint256).max`
        unchecked {
            _balanceOf[_to] += _amount;
        }

        emit Transfer(address(0), _to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyOwner {
        _balanceOf[_from] -= _amount;

        // cannot underflow because user's balance will never be greaer than total supply
        unchecked {
            totalSupply -= _amount;
        }

        emit Transfer(_from, address(0), _amount);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;

        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}
