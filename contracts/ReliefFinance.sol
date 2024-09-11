// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ReliefFinance {
    address public owner;
    Campaign[] public allCampaigns;
    uint256 public campaignCount = 0;
    uint256[] public approvedCampaigns;

    struct Campaign {
        uint256 id;
        address payable creator;
        string title;
        string description;
        string physicalAddress;
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
        bool isCompleted;
        string category;
        uint256 createdAt;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    mapping(uint256 => address[]) public campaignContributors;

    event CampaignCreated(
        uint256 id,
        address creator,
        string title,
        uint256 goal,
        uint256 duration,
        string category
    );

    event ContributionMade(uint256 id, address contributor, uint256 amount);
    event CampaignCompleted(uint256 id, uint256 amountRaised);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier activeCampaign(uint256 _id) {
        require(
            campaigns[_id].deadline > block.timestamp,
            "Campaign has ended"
        );
        require(!campaigns[_id].isCompleted, "Campaign is already completed");
        _;
    }

    modifier campaignExists(uint256 _id) {
        require(campaigns[_id].id == _id, "Campaign does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function getAllCampaigns() public view returns (Campaign[] memory) {
        return allCampaigns;
    }

    function getPaginatedCampaigns(uint256 start, uint256 limit)
        public
        view
        returns (Campaign[] memory)
    {
        uint256 end = start + limit;
        if (end > allCampaigns.length) {
            end = allCampaigns.length;
        }

        Campaign[] memory result = new Campaign[](end - start);
        uint256 index = 0;

        for (uint256 i = start; i < end; i++) {
            result[index] = allCampaigns[i];
            index++;
        }

        return result;
    }

    function getLatestCampaigns() public view returns (Campaign[] memory) {
    uint256 count = 0;
    uint256 approvedCount = 0;

    for (uint256 i = 1; i <= campaignCount; i++) {
        if (isApproved(i)) {
            approvedCount++;
        }
    }

    uint256 campaignLimit = approvedCount < 10 ? approvedCount : 10;
    Campaign[] memory result = new Campaign[](campaignLimit);

    if (approvedCount > 0) {
        for (uint256 i = campaignCount; i > 0 && count < campaignLimit; i--) {
            if (isApproved(i)) {
                result[count] = campaigns[i]; 
                count++;
            }
        }
    }

    return result;
}


    function createCampaign(
        string calldata _title,
        string calldata _description,
        string calldata _physicalAddress,
        uint256 _goal,
        uint256 _duration,
        string calldata _category
    ) external returns (Campaign memory) {
        require(bytes(_title).length > 0, "Title is required");
        require(bytes(_description).length > 0, "Description is required");
        require(bytes(_physicalAddress).length > 0, "Address is required");
        require(_goal > 0, "Goal must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");

        campaignCount++;
        uint256 deadline = block.timestamp + (_duration * 1 days);
        uint256 createdAt = block.timestamp;

        Campaign memory newCampaign = Campaign({
            id: campaignCount,
            creator: payable(msg.sender),
            title: _title,
            description: _description,
            physicalAddress: _physicalAddress,
            goal: _goal,
            deadline: deadline,
            amountRaised: 0,
            isCompleted: false,
            category: _category,
            createdAt: createdAt
        });

        campaigns[campaignCount] = newCampaign;
        allCampaigns.push(newCampaign); 

    emit CampaignCreated(
            newCampaign.id,
            newCampaign.creator,
            newCampaign.title,
            newCampaign.goal,
            newCampaign.deadline,
            newCampaign.category
        );

        return newCampaign;
    }

    function isApproved(uint256 _id) public view returns (bool) {
        for (uint256 i = 0; i < approvedCampaigns.length; i++) {
            if (approvedCampaigns[i] == _id) {
                return true;
            }
        }
        return false;
    }

    function approveCampaign(uint256 _id)
        external
        onlyOwner
        campaignExists(_id)
    {
        require(!isApproved(_id), "Campaign already approved");

        approvedCampaigns.push(_id);
    }

    function contribute(uint256 _id)
        external
        payable
        campaignExists(_id)
        activeCampaign(_id)
    {
        require(msg.value > 0, "Contribution must be greater than 0");

        Campaign storage campaign = campaigns[_id];
        require(isApproved(_id), "Campaign has not been approved");
        require(!campaign.isCompleted, "Campaign has been completed");

        if (contributions[_id][msg.sender] == 0) {
            campaignContributors[_id].push(msg.sender);
        }

        campaign.amountRaised += msg.value;
        contributions[_id][msg.sender] += msg.value;

        emit ContributionMade(_id, msg.sender, msg.value);
    }

    function completeCampaign(uint256 _id)
        external
        onlyOwner
        campaignExists(_id)
    {
        Campaign storage campaign = campaigns[_id];
        require(!campaign.isCompleted, "Campaign already completed");
        require(
            campaign.amountRaised >= (campaign.goal * 25) / 100,
            "At least 25% of the goal must be raised to complete the campaign"
        );

        campaign.isCompleted = true;
        campaign.creator.transfer(campaign.amountRaised);

        emit CampaignCompleted(_id, campaign.amountRaised);
    }

    function getCampaignsByCreator(address _creator)
        external
        view
        returns (Campaign[] memory)
    {
        uint256 count = 0;

        for (uint256 i = 1; i <= campaignCount; i++) {
            if (campaigns[i].creator == _creator) {
                count++;
            }
        }

        Campaign[] memory result = new Campaign[](count);
        uint256 index = 0;

        for (uint256 i = 1; i <= campaignCount; i++) {
            if (campaigns[i].creator == _creator) {
                result[index] = campaigns[i];
                index++;
            }
        }

        return result;
    }

    function getRefund(uint256 _id) external campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];
        require(
            campaign.deadline < block.timestamp,
            "Campaign is still ongoing"
        );
        require(!campaign.isCompleted, "Campaign is already completed");
        require(contributions[_id][msg.sender] > 0, "No contributions found");
        require(
            campaign.amountRaised < (campaign.goal * 25) / 100,
            "25% of the campaign goal was reached, no refunds"
        );

        uint256 amount = contributions[_id][msg.sender];
        contributions[_id][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function getContributors(uint256 _id)
        external
        view
        campaignExists(_id)
        returns (address[] memory)
    {
        return campaignContributors[_id];
    }

    function getCampaign(uint256 _id)
        public
        view
        returns (
            uint256 id,
            address creator,
            string memory title,
            string memory description,
            string memory physicalAddress,
            uint256 goal,
            uint256 deadline,
            uint256 amountRaised,
            bool isCompleted,
            uint256 createdAt,
            string memory category
        )
    {
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
            campaign.createdAt,
            campaign.category
        );
    }
}
