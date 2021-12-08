// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WizardNFT is ERC721 {
    uint256 public tokenCounter;
    mapping(uint256 => address) public tokenIdToAddress;
    /*Creating NFTs*/
    constructor () ERC721("Wizard", "WIZ"){
        tokenCounter = 0;
    }

    /*This function mints new NFTs*/
    function createCollectible() public returns(uint256) {
        uint256 newTokenId = tokenCounter;
        _safeMint(msg.sender, newTokenId);
        tokenIdToAddress[newTokenId] = msg.sender;
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

    using SafeMath for uint;
    mapping(uint256 => mapping(uint256 => bool)) public IdsToVote; //Maps proposal id to tokenid to choice of the voters
    mapping(uint256 => mapping(uint256 => bool)) public AlreadyVoted; //Maps users who are already voted
    mapping(address => bool) public Whitelisted; //Maps whitelisted users
    mapping(address => bool) public Delegated;
    mapping(uint256 => string) public IdToProposals; //Maps proposal ids to their description
    mapping(uint256 => uint256) public proposalEndTime; //Maps proposal ids to their end time

    event Voted(address voter, uint256 voterNftId, bool choice);
    uint256 proposalId;
    uint256 votingPeriod;
    mapping(uint256 => uint256) public favouringVotes; //Maps proposal ids to their number of favouring votes 
    mapping(uint256 => uint256) public opposingVotes; //Maps proposal ids to their number of oppsoing votes
    address owner;
    event ProposalCreated(uint256 _proposalId, string desc, address creator);

    enum Outcome{WON, LOST, DRAW}
    mapping(uint256 => Outcome) public proposalResult; //Maps the results of the proposals
    mapping(uint256 => uint256) public proposalIdToBalance;
    mapping(address => mapping(uint256 => uint256)) public addressToAmount;
    mapping(uint256 => mapping(uint256 => uint256)) public tokenIdToAmount;
    mapping(uint256 => mapping(uint256 => bool)) public shareReceived;
    bool received;
    uint profit;
    uint favourAmount;
    uint opposeAmount;
    
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
        emit ProposalCreated(proposalId, description, msg.sender);
    }

    /*This function let the user to vote either in favor of or oppose proposals */
    function vote(uint256 tokenId, uint256 _proposalId, bool choice, uint256 amount) public payable {
        require(WizardNFT.checkOwner(msg.sender, tokenId), "Access Denied");
        require(!AlreadyVoted[_proposalId][tokenId], "You have already voted");
        if (choice) {
            favouringVotes[_proposalId] = favouringVotes[_proposalId] + 1;

            addressToAmount[msg.sender][_proposalId] += amount;
            tokenIdToAmount[tokenId][_proposalId] += amount;
            proposalIdToBalance[_proposalId] += amount;

            IdsToVote[_proposalId][tokenId] = choice;
            AlreadyVoted[_proposalId][tokenId] = true;
            emit Voted(msg.sender, tokenId, choice);
        }
        else {
            opposingVotes[_proposalId] = opposingVotes[_proposalId] + 1;

            addressToAmount[msg.sender][_proposalId] += amount;
            tokenIdToAmount[tokenId][_proposalId] += amount;
            proposalIdToBalance[_proposalId] += amount;

            IdsToVote[_proposalId][tokenId] = choice;
            AlreadyVoted[_proposalId][tokenId] = true;
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
            proposalResult[_proposalId] = Outcome.LOST;
            return opposeMessage;
        }

        if (favouringVotes[_proposalId] > opposingVotes[_proposalId]) {
            proposalResult[_proposalId] = Outcome.WON;
            return favorMessage;
        }

        if (favouringVotes[_proposalId] == opposingVotes[_proposalId]) {
            proposalResult[_proposalId] = Outcome.DRAW;
            return drawMessage;
        }

        profit = proposalIdToBalance[_proposalId].mul(20).div(100);
        favourAmount = profit.div(favouringVotes[_proposalId]);
        opposeAmount = profit.div(opposingVotes[_proposalId]);
        proposalIdToBalance[_proposalId] -= profit;
    }

    function distribute(uint256 _proposalId, uint256 tokenId) public payable {
        
        require(shareReceived[tokenId][_proposalId] == false, "You have already received your share");
        
        if (uint(proposalResult[_proposalId]) == 0) {
            if (IdsToVote[_proposalId][tokenId] == true) {
                profit -= favourAmount;
                shareReceived[tokenId][_proposalId] = true;
                payable(WizardNFT.tokenIdToAddress[tokenId]).transfer(favourAmount);
            }
        }

        if (uint(proposalResult[_proposalId]) == 1) {
            if (IdsToVote[_proposalId][tokenId] == false) {
                profit -= favourAmount;
                shareReceived[tokenId][_proposalId] = true;
                payable(WizardNFT.tokenIdToAddress[tokenId]).transfer(favourAmount);
            }
        }

        if (uint(proposalResult[_proposalId]) == 3) {
            if (AlreadyVoted[_proposalId][tokenId] == true) {
                proposalIdToBalance[_proposalId] -= tokenIdToAmount[tokenId][_proposalId];
                payable(WizardNFT.tokenIdToAddress[tokenId]).transfer(tokenIdToAmount[tokenId][_proposalId]);
            }
        }    
    }

    function delegate(address _user) public {
        require(msg.sender == owner, "Access Denied");
        Delegated[_user] = true;
    }

    function withdraw(uint256 _proposalId) public payable {
        
        if (msg.sender == owner || Delegated[msg.sender]) {
            payable(msg.sender).transfer(proposalIdToBalance[_proposalId]);
        }
    }

}

