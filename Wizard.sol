// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract WizardNFT is ERC721 {
    uint256 public tokenCounter;
    
    constructor () public ERC721("Wizard", "WIZ"){
        tokenCounter = 0;
    }

    function createCollectible() public returns(uint256) {
        uint256 newTokenId = tokenCounter;
        _safeMint(msg.sender, newTokenId);
        tokenCounter = tokenCounter + 1;
        return newTokenId;
    }

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
    mapping(uint256 => bool) public NftIdToVotes;
    mapping(uint256 => bool) public AlreadyVoted;
    event Voted(address voter, uint256 voterNftId, bool choice);
    uint256 favouringVotes;
    uint256 opposingVotes;

    function vote(uint256 tokenId, bool choice) public {
        require(WizardNFT.checkOwner(msg.sender, tokenId), "Access Denied");
        require(!AlreadyVoted[tokenId], "You have already voted");
        if (choice) {
            favouringVotes = favouringVotes + 1;
            NftIdToVotes[tokenId] = choice;
            AlreadyVoted[tokenId] = true;
            emit Voted(msg.sender, tokenId, choice);
        }
        else {
            opposingVotes = opposingVotes + 1;
            NftIdToVotes[tokenId] = choice;
            AlreadyVoted[tokenId] = true;
            emit Voted(msg.sender, tokenId, choice);
        }
    }
}

contract WizardTreasury {
    mapping(address => uint256) public addressToAmount;
    event Staked(address staker, uint256 amount);
    event Unstaked(address unstaker, uint256 amount);

    function stake(uint256 amount) public payable {
        require(amount > 0, "Must be greater than zero");
        addressToAmount[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake() public {
        uint256 withdraw = addressToAmount[msg.sender];
        addressToAmount[msg.sender] = 0;
        payable(msg.sender).transfer(withdraw);
        emit Unstaked(msg.sender, withdraw);
    }
}
