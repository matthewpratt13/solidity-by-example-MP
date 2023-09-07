// SPDX=License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/ERC20.sol";
import "src/CrowdFund.sol";

contract Coin is ERC20 {
    constructor() ERC20("Coin", "COIN", 18) {}

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}

contract CrowdFundTest is Test {
    Coin public coin;
    CrowdFund public crowdFund;

    function setUp() public {
        coin = new Coin();
        crowdFund = new CrowdFund(address(coin));
    }
}
