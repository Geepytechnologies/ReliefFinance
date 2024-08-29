// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ReliefFinance {
    address public owner; 
    uint public campaignCount = 0;
    IERC20 public rwaToken; 

    enum Category {
        Disaster,
        Children,
        FoodCrisis,
        Health,
        Education,
        Homeless,
        Animal,
        Pandemic,
        WarCrisis,
        Others
    }
    struct CampaignDetails {
        string title;
        string description;
        string physicalAddress;
        uint goal;
        uint duration;
        Category category;
    }
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
        Category category;
        uint createdAt;
    }

    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public contributions;
    mapping(uint => address[]) public campaignContributors;

    event CampaignCreated(uint id, address creator, CampaignDetails details);
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
        CampaignDetails calldata _details
    ) external returns (Campaign memory) {
        require(bytes(_details.title).length > 0, "Title is required");
        require(bytes(_details.description).length > 0, "Description is required");
        require(bytes(_details.physicalAddress).length > 0, "Address is required");
        require(_details.goal > 0, "Goal must be greater than 0");
        require(_details.duration > 0, "Duration must be greater than 0");

        campaignCount++;
        uint deadline = block.timestamp + (_details.duration * 1 days);
        uint createdAt = block.timestamp;

        campaigns[campaignCount] = Campaign({
            id: campaignCount,
            creator: payable(msg.sender),
            title: _details.title,
            description: _details.description,
            physicalAddress: _details.physicalAddress,
            goal: _details.goal,
            deadline: deadline,
            amountRaised: 0,
            isCompleted: false,
            isApproved: false,
            category: _details.category,
            createdAt: createdAt
        });

        emit CampaignCreated(campaignCount, msg.sender, _details);
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
        rwaToken.transfer(campaign.creator, campaign.amountRaised);

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
        rwaToken.transfer(msg.sender, amount);
    }

    function getContributors(uint _id) external view campaignExists(_id) returns (address[] memory) {
        return campaignContributors[_id];
    }
    function getCategories() external pure returns (string[10] memory) {
    string[10] memory categories = [
        "Disaster",
        "Children",
        "Food Crisis",
        "Health",
        "Education",
        "Homeless",
        "Animal",
        "Pandemic",
        "War Crisis",
        "Others"
    ];
    return categories;
}
function getCategoryString(Category _category) public pure returns (string memory) {
    if (_category == Category.Disaster) return "Disaster";
    if (_category == Category.Children) return "Children";
    if (_category == Category.FoodCrisis) return "Food Crisis";
    if (_category == Category.Health) return "Health";
    if (_category == Category.Education) return "Education";
    if (_category == Category.Homeless) return "Homeless";
    if (_category == Category.Animal) return "Animal";
    if (_category == Category.Pandemic) return "Pandemic";
    if (_category == Category.WarCrisis) return "War Crisis";
    return "Others";
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
        getCategoryString(campaign.category)
    );
}


}
