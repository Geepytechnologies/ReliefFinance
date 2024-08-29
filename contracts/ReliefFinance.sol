// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ReliefFinance {
    address public owner; 
    uint public campaignCount = 0;

    struct Campaign {
        uint id;
        address payable creator;
        string title;
        string description;
        string physicalAddress;
        uint goal;
        uint deadline;
        uint amountRaised;
        bool isCompleted;
        bool isApproved;
        string category;
        uint createdAt;
    }

    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public contributions;
    mapping(uint => address[]) public campaignContributors;

    event CampaignCreated(
        uint id, 
        address creator, 
        string title,
        string description,
        string physicalAddress,
        uint goal,
        uint duration,
        string category
    );
    
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

    constructor() {
        owner = msg.sender;
    }

    function createCampaign(
        string calldata _title,
        string calldata _description,
        string calldata _physicalAddress,
        uint _goal,
        uint _duration,
        string calldata _category
    ) external returns (Campaign memory) {
        require(bytes(_title).length > 0, "Title is required");
        require(bytes(_description).length > 0, "Description is required");
        require(bytes(_physicalAddress).length > 0, "Address is required");
        require(_goal > 0, "Goal must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");

        campaignCount++;
        uint deadline = block.timestamp + (_duration * 1 days);
        uint createdAt = block.timestamp;

        campaigns[campaignCount] = Campaign({
            id: campaignCount,
            creator: payable(msg.sender),
            title: _title,
            description: _description,
            physicalAddress: _physicalAddress,
            goal: _goal,
            deadline: deadline,
            amountRaised: 0,
            isCompleted: false,
            isApproved: false,
            category: _category,
            createdAt: createdAt
        });

        emit CampaignCreated(campaignCount, msg.sender, _title, _description, _physicalAddress, _goal, _duration, _category);
        return campaigns[campaignCount];
    }

    function approveCampaign(uint _id) external onlyOwner campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];
        require(!campaign.isApproved, "Campaign already approved");
        campaign.isApproved = true;
    }

    function contribute(uint _id) external payable campaignExists(_id) activeCampaign(_id) {
        require(msg.value > 0, "Contribution must be greater than 0");

        Campaign storage campaign = campaigns[_id];
        require(campaign.isApproved, "Campaign has not been approved");
        require(!campaign.isCompleted, "Campaign has been completed");

        if (contributions[_id][msg.sender] == 0) {
            campaignContributors[_id].push(msg.sender);
        }

        campaign.amountRaised += msg.value;
        contributions[_id][msg.sender] += msg.value;

        emit ContributionMade(_id, msg.sender, msg.value);
    }

    function completeCampaign(uint _id) external onlyOwner campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];
        require(!campaign.isCompleted, "Campaign already completed");
        require(campaign.amountRaised >= campaign.goal, "Goal not reached");

        campaign.isCompleted = true;
        campaign.creator.transfer(campaign.amountRaised);

        emit CampaignCompleted(_id, campaign.amountRaised);
    }

    function getCampaignsByCreator(address _creator) external view returns (Campaign[] memory) {
        uint count = 0;

        for (uint i = 1; i <= campaignCount; i++) {
            if (campaigns[i].creator == _creator) {
                count++;
            }
        }

        Campaign[] memory result = new Campaign[](count);
        uint index = 0;

        for (uint i = 1; i <= campaignCount; i++) {
            if (campaigns[i].creator == _creator) {
                result[index] = campaigns[i];
                index++;
            }
        }

        return result;
    }

    function getRefund(uint _id) external campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];
        require(campaign.deadline < block.timestamp, "Campaign is still ongoing");
        require(!campaign.isCompleted, "Campaign is already completed");
        require(contributions[_id][msg.sender] > 0, "No contributions found");

        uint amount = contributions[_id][msg.sender];
        contributions[_id][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function getContributors(uint _id) external view campaignExists(_id) returns (address[] memory) {
        return campaignContributors[_id];
    }

    function getCampaign(uint _id) public view returns (
        uint id,
        address creator,
        string memory title,
        string memory description,
        string memory physicalAddress,
        uint goal,
        uint deadline,
        uint amountRaised,
        bool isCompleted,
        bool isApproved,
        uint createdAt,
        string memory category
    ) {
        Campaign storage campaign = campaigns[_id];
        return (
            campaign.id,
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.physicalAddress,
            campaign.goal,
            campaign.deadline,
            campaign.amountRaised,
            campaign.isCompleted,
            campaign.isApproved,
            campaign.createdAt,
            campaign.category
        );
    }
}
