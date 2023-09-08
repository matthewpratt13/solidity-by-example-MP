// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract CrowdFund {
    struct Campaign {
        uint256 target;
        uint256 startTime;
        uint256 endTime;
        uint256 amountPledged;
        address creator;
        bool pledgesHaveBeenClaimed;
    }

    IERC20 private immutable _COIN;

    uint256 public campaignIdCounter;

    address public owner;

    mapping(uint256 campaignId => Campaign) public campaigns;
    mapping(uint256 campaignId => mapping(address caller => uint256 amount)) public amountPledged;

    event LaunchCampaign(
        uint256 indexed campaignId, address indexed creator, uint256 indexed target, uint256 startTime, uint256 endTime
    );
    event CancelCampaign(uint256 indexed campaignId);
    event Pledge(uint256 indexed campaignId, address indexed caller, uint256 amount);
    event Withdraw(uint256 indexed campaignId, address indexed to, uint256 indexed amount);
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyActive(uint256 campaignId) {
        Campaign memory campaign = campaigns[campaignId];

        require(block.timestamp >= campaign.startTime, "Campaign has not started");
        require(block.timestamp <= campaign.endTime, "Campaign has ended");
        _;
    }

    modifier onlyInactive(uint256 campaignId) {
        Campaign memory campaign = campaigns[campaignId];

        require(block.timestamp > campaign.endTime || block.timestamp < campaign.startTime, "Campaign is still active");

        _;
    }

    constructor(address _COINAddress) {
        _COIN = IERC20(_COINAddress);
        owner = msg.sender;
    }

    function launchCampaign(uint256 _target, uint256 _startTime, uint256 _endTime, uint256 _maxDuration)
        external
        onlyOwner
    {
        require(_startTime >= block.timestamp, "Start time before now");
        require(_endTime >= _startTime, "End time before start time");
        require(_endTime <= block.timestamp + _maxDuration);

        uint256 campaignId = campaignIdCounter;

        campaigns[campaignId] = Campaign({
            target: _target,
            startTime: _startTime,
            endTime: _endTime,
            amountPledged: 0,
            creator: msg.sender,
            pledgesHaveBeenClaimed: false
        });

        unchecked {
            ++campaignIdCounter;
        }

        emit LaunchCampaign(campaignId, msg.sender, _target, _startTime, _endTime);
    }

    function cancelCampaign(uint256 _campaignId) external onlyOwner onlyInactive(_campaignId) {
        require(_campaignId >= campaignIdCounter, "Campaign does not exist");

        Campaign memory campaign = campaigns[_campaignId];

        require(campaign.creator == msg.sender, "Caller is not campaign creator");

        delete campaigns[_campaignId];

        emit CancelCampaign(_campaignId);
    }

    function pledge(uint256 _campaignId, uint256 _amount) external onlyActive(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];

        campaign.amountPledged += _amount;

        amountPledged[_campaignId][msg.sender] += _amount;

        _COIN.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_campaignId, msg.sender, _amount);
    }

    function unpledge(uint256 _campaignId, uint256 _amount) external onlyActive(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];

        campaign.amountPledged -= _amount;

        amountPledged[_campaignId][msg.sender] -= _amount;

        _COIN.transfer(msg.sender, _amount);

        emit Withdraw(_campaignId, msg.sender, _amount);
    }

    function reclaimPledge(uint256 _campaignId) external onlyInactive(_campaignId) {
        Campaign memory campaign = campaigns[_campaignId];

        require(campaign.amountPledged < campaign.target, "Target has been reached");

        uint256 refundAmount = amountPledged[_campaignId][msg.sender];

        amountPledged[_campaignId][msg.sender] = 0;

        _COIN.transfer(msg.sender, refundAmount);

        emit Withdraw(_campaignId, msg.sender, refundAmount);
    }

    function withdraw(uint256 _campaignId) external onlyOwner onlyInactive(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];

        require(campaign.amountPledged >= campaign.target, "Amount pledged is below target");

        require(!campaign.pledgesHaveBeenClaimed, "Pledges already claimed");

        campaign.pledgesHaveBeenClaimed = true;

        _COIN.transfer(campaign.creator, campaign.amountPledged);

        emit Withdraw(_campaignId, campaign.creator, campaign.amountPledged);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;

        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}
