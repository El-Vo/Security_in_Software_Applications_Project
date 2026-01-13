pragma solidity ^0.8.22;
// SPDX-License-Identifier: UNLICENSED
import "Taxpayer.sol";

contract Lottery {
  enum Phase {
    NotStarted,
    Commitment,
    Reveal,
    Endable
  }

  address owner;
  uint256 public round;
  mapping(address => uint256) public participantRound;
  mapping(address => bytes32) commits;
  mapping(address => uint) reveals;
  address[] revealed;

  uint256 public startTime;
  uint256 public revealTime;
  uint256 public endTime;
  uint256 public period;
  bool public isContract = true;

  /// @notice Initializes the registry with the lottery period.
  /// @param p The duration of each phase in seconds.
  constructor(uint p) {
    period = p;
    startTime = 0;
    endTime = 0;
    round = 0;
  }

  /// @notice Starts a new lottery round. Only possible if no lottery is currently active.
  function startLottery() public {
    require(startTime == 0);
    round++;
    startTime = block.timestamp;
    revealTime = startTime + period;
    endTime = revealTime + period;
  }

  /// @notice Commits a hidden value for the current lottery round.
  /// @param y The keccak256 hash of the chosen secret.
  function commit(bytes32 y) public {
    require(startTime > 0 && block.timestamp < revealTime, "Commitment phase ended or not started");
    require(participantRound[msg.sender] < round, "Already committed in this round");

    participantRound[msg.sender] = round;
    commits[msg.sender] = y;
  }

  /// @notice Reveals the secret value to participate in the drawing.
  /// @param rev The secret value that was hashed during the commitment phase.
  function reveal(uint256 rev) public {
    require(block.timestamp >= revealTime);
    require(keccak256(abi.encode(rev)) == commits[msg.sender]);

    for (uint i = 0; i < revealed.length; i++) {
      require(revealed[i] != msg.sender, "Already revealed");
    }

    revealed.push(msg.sender);
    reveals[msg.sender] = uint(rev);
  }

  /// @notice Ends the lottery and notifies the winner's Taxpayer contract.
  /// @dev Resets the state regardless of whether a winner was found.
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

  /// @notice Returns the list of addresses that successfully revealed their secret.
  function getRevealedParticipants() public view returns (address[] memory) {
    return revealed;
  }
}
