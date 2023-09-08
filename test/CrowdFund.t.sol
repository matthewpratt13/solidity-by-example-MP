// SPDX=License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/CrowdFund.sol";

contract CrowdFundTest is Test {
    address public coinAddress;

    CrowdFund public crowdFund;

    function setUp() public {
        crowdFund = new CrowdFund(coinAddress);
    }
}
