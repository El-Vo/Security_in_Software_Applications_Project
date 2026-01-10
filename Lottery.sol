pragma solidity ^0.8.22;
// SPDX-License-Identifier: UNLICENSED
import "Taxpayer.sol";

contract Lottery {

    address owner;
    uint256 public round;
    mapping(address => uint256) public participantRound;
    mapping(address => bytes32) commits;
    mapping(address => uint) reveals;
    address[] revealed;

    uint256 startTime;
    uint256 revealTime;
    uint256 endTime;
    uint256 period;
    bool iscontract;

    // Initialize the registry with the lottery period.
    constructor(uint p) {
        period = p;
        startTime = 0;
        endTime = 0;
        round = 0;
        iscontract = true;
    }

    //If the lottery has not started, anyone can invoke a lottery.
    function startLottery() public {
        require(startTime == 0);
        round++;
        //startTime current time. Users send their committed value
        startTime = block.timestamp;
        //revealTime  time for revealing. User reveal their value
        revealTime = startTime + period;
        //endTime a winner can be computed
        endTime = revealTime + period;
    }

    //A taxpayer send his own commitment.
    function commit(bytes32 y) public {
        require(startTime > 0 && block.timestamp < revealTime, "Commitment phase ended or not started");
        require(participantRound[msg.sender] < round, "Already committed in this round");
        
        participantRound[msg.sender] = round;
        commits[msg.sender] = y;
    }

    //A valid taxpayer who sent his own commitment, sends the revealing value.
    function reveal(uint256 rev) public {
        require(block.timestamp >= revealTime);
        require(keccak256(abi.encode(rev)) == commits[msg.sender]);
        
        // Prevent duplicate participation in the same round
        for (uint i = 0; i < revealed.length; i++) {
            require(revealed[i] != msg.sender, "Already revealed");
        }

        revealed.push(msg.sender);
        reveals[msg.sender] = uint(rev);
    }

    //Ends the lottery and compute the winner.
    function endLottery() public {
        require(block.timestamp >= endTime);
        
        if (revealed.length > 0) {
            uint total = 0;
            for (uint i = 0; i < revealed.length; i++) {
                total += reveals[revealed[i]];
            }
            
            Taxpayer(revealed[total % revealed.length]).setWonLottery();
        }
        
        // Always reset state for the next lottery round
        startTime = 0;
        revealTime = 0;
        endTime = 0;
        delete revealed;
    }
    function isContract() public view returns (bool) {
        return iscontract;
    }

    function getRevealedParticipants() public view returns (address[] memory) {
        return revealed;
    }
}
