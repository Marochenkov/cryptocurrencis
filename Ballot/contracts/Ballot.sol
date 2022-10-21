// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

contract Ballot {
    address public owner;

    struct Candidate {
        address payable account;
        uint votesCount;
    }

    struct Voter {
        bool voted;
        uint voteIndex;
    }

    struct VoteInfo {
        uint daysLeft;
        uint paymentAmount;
        uint fee;
        Candidate[] candidates;
    }

    Candidate[] public candidates;

    mapping(address => Voter) public voters;

    uint votingFinishDate;
    uint paymentAmount;
    uint fee;

    constructor() {
        owner = msg.sender;
    }

    modifier OnlyOwner{
        if (msg.sender == owner) {
            _;
        }
    }

    function createVoting(uint durationInDays, uint paymentAmount_, uint fee_, address[] memory candidates_) OnlyOwner public {
        votingFinishDate = block.timestamp + (durationInDays * 1 days);
        paymentAmount = paymentAmount_;
        fee = fee_;

        for (uint i = 0; i < candidates_.length; i++) {
            candidates.push(
                Candidate({
                    account: payable(candidates_[i]), 
                    votesCount: 0
                })
            );
        }
    }

    function withdrawFees() OnlyOwner public {
        require(block.timestamp >= votingFinishDate, "Voting is not finished.");

        uint winningVotesCount = 0;
        uint totalVotes = 0;

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].votesCount > winningVotesCount) {
                winningVotesCount = candidates[i].votesCount;
            } 
            totalVotes += candidates[i].votesCount;
        }

        uint winnersCount = 0;

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].votesCount == winningVotesCount) {
                winnersCount += 1;
            }
        }

        uint transferAmount = (100 - fee) * paymentAmount * totalVotes / winnersCount;
        assert(transferAmount >= 0);

        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i].votesCount == winningVotesCount) {
                candidates[i].account.transfer(transferAmount);
            }
        }
    }

    function voteFor(uint candidateIndex) public {
        require(block.timestamp < votingFinishDate, "Voting is finished.");
        require(!voters[msg.sender].voted, "Voter has already voted.");

        voters[msg.sender].voted = true;
        voters[msg.sender].voteIndex = candidateIndex;

        candidates[candidateIndex].votesCount += 1;
    }

    function getVoteInfo() public view returns (VoteInfo memory voteInfo) {
        voteInfo = VoteInfo({
            daysLeft: (votingFinishDate - block.timestamp) / 60 / 60 / 24,
            paymentAmount: paymentAmount,
            fee: fee,
            candidates: candidates
        });
    }
}

