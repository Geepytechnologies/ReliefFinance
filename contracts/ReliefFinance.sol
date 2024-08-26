// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ReliefFinance {
    address public owner; 
    uint public campaignCount = 0;
    IERC20 public rwaToken; // $RWA token contract

    struct Campaign {
        uint id;
        address payable creator;
        string name;
        string email;
        string description;
        string physicalAddress;
        uint goal;
        uint deadline;
        uint amountRaised;
        bool isCompleted;
    }

    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public contributions;

    event CampaignCreated(uint id, address creator, string name, string email, uint goal, uint deadline);
    event ContributionMade(uint id, address contributor, uint amount);
    event CampaignCompleted(uint id, uint amountRaised);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier activeCampaign(uint _id) {
        require(campaigns[_id].deadline > block.timestamp, "Campaign has ended");
        require(!campaigns[_id].isCompleted, "Campaign is already completed");
        _;
    }

    modifier campaignExists(uint _id) {
        require(campaigns[_id].id == _id, "Campaign does not exist");
        _;
    }

    constructor(address _rwaTokenAddress) {
        owner = msg.sender;
        rwaToken = IERC20(_rwaTokenAddress);
    }

    function createCampaign(
        string calldata _name,
        string calldata _email,
        string calldata _description,
        string calldata _physicalAddress,
        uint _goal,
        uint _duration
    ) external returns (uint) {
        require(bytes(_name).length > 0, "Name is required");
        require(bytes(_email).length > 0, "Email is required");
        require(bytes(_description).length > 0, "Description is required");
        require(bytes(_physicalAddress).length > 0, "Address is required");
        require(_goal > 0, "Goal must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");

        campaignCount++;
        uint deadline = block.timestamp + _duration;

        campaigns[campaignCount] = Campaign({
            id: campaignCount,
            creator: payable(msg.sender),
            name: _name,
            email: _email,
            description: _description,
            physicalAddress: _physicalAddress,
            goal: _goal,
            deadline: deadline,
            amountRaised: 0,
            isCompleted: false
        });

        emit CampaignCreated(campaignCount, msg.sender, _name, _email, _goal, deadline);
        return campaignCount;
    }

    function contribute(uint _id, uint _amount) external campaignExists(_id) activeCampaign(_id) {
        require(_amount > 0, "Contribution must be greater than 0");

        Campaign storage campaign = campaigns[_id];
        campaign.amountRaised += _amount;
        contributions[_id][msg.sender] += _amount;

        rwaToken.transferFrom(msg.sender, address(this), _amount);

        emit ContributionMade(_id, msg.sender, _amount);
    }

    function completeCampaign(uint _id) external onlyOwner campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];
        require(!campaign.isCompleted, "Campaign already completed");
        require(campaign.amountRaised >= campaign.goal, "Goal not reached");

        campaign.isCompleted = true;
        rwaToken.transfer(campaign.creator, campaign.amountRaised);

        emit CampaignCompleted(_id, campaign.amountRaised);
    }

    function getRefund(uint _id) external campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];
        require(campaign.deadline < block.timestamp, "Campaign is still ongoing");
        require(!campaign.isCompleted, "Campaign is already completed");
        require(contributions[_id][msg.sender] > 0, "No contributions found");

        uint amount = contributions[_id][msg.sender];
        contributions[_id][msg.sender] = 0;
        rwaToken.transfer(msg.sender, amount);
    }
}
