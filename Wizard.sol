// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract WizardNFT is ERC721 {
    uint256 public tokenCounter;

    /*Creating NFTs*/
    constructor () ERC721("Wizard", "WIZ"){
        tokenCounter = 0;
    }

    /*This function mints new NFTs*/
    function createCollectible() public returns(uint256) {
        uint256 newTokenId = tokenCounter;
        _safeMint(msg.sender, newTokenId);
        tokenCounter = tokenCounter + 1;
        return newTokenId;
    }

    /*This function checks whether the NFT belong to the user*/
    function checkOwner(address user, uint256 tokenId) public view returns (bool) {
        if (ERC721.ownerOf(tokenId) == user) {
            return true;
        }
        else {
            return false;
        }
    }
}

contract WizardDAO is WizardNFT {
    mapping(uint256 => mapping(uint256 => bool)) public IdsToVote;
    mapping(uint256 => bool) public AlreadyVoted;
    mapping(address => bool) public Whitelisted;
    mapping(uint256 => string) public IdToProposals;
    mapping(uint256 => uint256) public proposalEndTime;
    mapping(uint256 => bool) public proposalAccepted;

    event Voted(address voter, uint256 voterNftId, bool choice);
    uint256 proposalId;
    uint256 votingPeriod;
    mapping(uint256 => uint256) public favouringVotes;
    mapping(uint256 => uint256) public opposingVotes;
    address owner;

    constructor() {
        owner = msg.sender;
        proposalId = 0;
        votingPeriod = 45818; //1 week
        
    }

    /*This function is used to whitelist certain members. Can only accessed by the deployer/owner*/
    function whitelist(address member) public {
        require(msg.sender == owner, "You don't have permission");
        Whitelisted[member] = true;
    }

    /*This function is used to create new proposals*/
    function createProposal(string memory description) public {
        proposalId = proposalId + 1;
        IdToProposals[proposalId] = description;
        proposalEndTime[proposalId] = block.timestamp + votingPeriod;
    }

    /*This function let the user to vote either in favor of or oppose proposals */
    function vote(uint256 tokenId, uint256 _proposalId, bool choice) public {
        require(WizardNFT.checkOwner(msg.sender, tokenId), "Access Denied");
        require(!AlreadyVoted[tokenId], "You have already voted");
        if (choice) {
            favouringVotes[_proposalId] = favouringVotes[_proposalId] + 1;
            IdsToVote[_proposalId][tokenId] = choice;
            AlreadyVoted[tokenId] = true;
            emit Voted(msg.sender, tokenId, choice);
        }
        else {
            opposingVotes[_proposalId] = opposingVotes[_proposalId] + 1;
            IdsToVote[_proposalId][tokenId] = choice;
            AlreadyVoted[tokenId] = true;
            emit Voted(msg.sender, tokenId, choice);
        }
    }

    /*This function is used the end the votings and view the results*/
    function endVoting(uint256 _proposalId) public returns (string memory) {
        require(msg.sender == owner, "You don't have permission");
        require(block.timestamp > proposalEndTime[_proposalId], "Voting period is not over yet");
    
        string memory favorMessage = "The proposal is accepted";
        string memory opposeMessage = "The proposal is rejected";
        string memory drawMessage = "The proposal has equal number of favoring and opposing votes";
        

        if (opposingVotes[_proposalId] > favouringVotes[_proposalId]) {
            proposalAccepted[_proposalId] = false;
            return opposeMessage;
        }

        if (favouringVotes[_proposalId] > opposingVotes[_proposalId]) {
            proposalAccepted[_proposalId] = true;
            return favorMessage;
        }

        if (favouringVotes[_proposalId] == opposingVotes[_proposalId]) {
            proposalAccepted[_proposalId] = false;
            return drawMessage;
        }
    }
}

contract WizardTreasury {
    
    mapping(address => uint256) public addressToAmount;
    event Staked(address staker, uint256 amount);
    event Unstaked(address unstaker, uint256 amount);

    /*This function lets user to stake their assets*/
    function stake(uint256 amount) public payable {
        require(amount > 0, "Must be greater than zero");
        addressToAmount[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }

    /*Used to unstake*/
    function unstake() public {
        uint256 withdraw = addressToAmount[msg.sender];
        addressToAmount[msg.sender] = 0;
        payable(msg.sender).transfer(withdraw);
        emit Unstaked(msg.sender, withdraw);
    }
}
