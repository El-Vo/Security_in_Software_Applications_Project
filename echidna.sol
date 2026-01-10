// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Taxpayer.sol";
import "./Lottery.sol";

contract TestTaxpayer is Taxpayer {
    Taxpayer public candidate;
    // Define lottery periods as 10 seconds per default
    uint256 public period = 10;
    Lottery public l = new Lottery(period);

    constructor() Taxpayer(address(0x11), address(0x12)) {
        candidate = new Taxpayer(address(0x13), address(0x14));
    }

    // ASSIGNMENT PART 1

    /** 
        Check if bool isMarried and spouse address are correctly set in conjunction to each other.
        If the taxpayer isn't married, he/she shouldn't have a spouse address and vice versa.
    */
    function echidna_state_consistency() public view returns (bool) {
        return isMarried == (spouse != address(0));
    }

    /** 
        Check for marriage symmetry.
        If this taxpayer is married to someone, that partner must also be married to this taxpayer.
    */
    function echidna_marriage_symmetry() public view returns (bool) {
        if (isMarried) {
            Taxpayer partner = Taxpayer(spouse);
            try partner.spouseAddress() returns (address partnersSpouse) {
                return (partnersSpouse == address(this) &&
                    partner.isMarriedState());
            } catch {
                // If the call fails, the target is either not a contract or not a valid Taxpayer object.
                return false;
            }
        }
        return true;
    }

    /** 
        Check that no self-marriage occurred.
    */
    function echidna_no_self_marriage() public view returns (bool) {
        return spouse != address(this);
    }

    /** 
        Check if marriage is ever achieved. 
        If this test passes, it means Echidna NEVER managed to marry anyone, 
        making the other marriage tests (symmetry, etc.) useless.
    */
    /* function echidna_is_never_married() public view returns (bool) {
        return !isMarried;
    } */

    /** 
        Helper functions to allow Echidna to interact with a valid contract.
    */
    function marryCandidate() public {
        marry(address(candidate));
    }

    function divorceCandidate() public {
        divorce();
    }

    // ASSIGNMENT PART 2

    /** 
        Check that the tax allowance of an unmarried taxpayer under 65 who hasn't won the lottery is 5000.
    */
    function echidna_valid_tax_allowance() public view returns (bool) {
        if (age < 65 && !isMarriedState() && !hasExtendedTaxAllowance()) {
            return (getTaxAllowance() == 5000);
        }
        return true;
    }

    /** 
        Check that the tax allowance of an unmarried taxpayer under 65 who has won the lottery is 7000.
    */
    function echidna_valid_tax_allowance_winner() public view returns (bool) {
        if (age < 65 && !isMarriedState() && hasExtendedTaxAllowance()) {
            return (getTaxAllowance() == 7000);
        }
        return true;
    }

    /** 
        Check that the tax allowance of a taxpayer is never below zero.
    */
    function echidna_tax_allowance_never_lower_than_zero()
        public
        view
        returns (bool)
    {
        return (getTaxAllowance() >= 0);
    }

    /** 
        Check that the tax allowance of a married couple is either 10000,12000 or 14000.
    */
    function echidna_valid_married_tax_allowance() public view returns (bool) {
        if (isMarriedState()) {
            Taxpayer spObj = Taxpayer(spouseAddress());
            uint combined = getTaxAllowance() + spObj.getTaxAllowance();
            return (combined == 10000 ||
                combined == 12000 ||
                combined == 14000);
        }
        return true;
    }

    // ASSIGNMENT PART 3

    /** 
        Check that the tax allowance of an unmarried taxpayer over 65 is always 7000.
    */
    function echidna_valid_tax_allowance_over_64() public view returns (bool) {
        if (age >= 65 && !isMarriedState()) {
            return (getTaxAllowance() == 7000);
        }
        return true;
    }

    /** 
        Check that the tax allowance of a married couple over 64 is always 14000.
    */
    function echidna_valid_married_tax_allowance_over_64()
        public
        view
        returns (bool)
    {
        if (isMarriedState() && age > 64) {
            Taxpayer spObj = Taxpayer(spouseAddress());
            if (spObj.age() > 64) {
                uint combined = getTaxAllowance() + spObj.getTaxAllowance();
                return (combined == 14000);
            }
        }
        return true;
    }

    /** 
        Helper function for echidna to advance age more quickly.
    */
    function advanceTaxpayerAge() public {
        for (uint i = 0; i < 15; i++) {
            haveBirthday();
        }
    }

    /** 
        Helper function for echidna to advance age of spouse more quickly.
    */
    function advanceTaxpayerSpouseAge() public {
        for (uint i = 0; i < 15; i++) {
            Taxpayer(spouseAddress()).haveBirthday();
        }
    }

    // ASSIGNMENT PART 4

    /** 
        Helper function for echidna to run lotteries.
    */
    function startLottery() public {
        l.startLottery();
    }

    /**
        Overloaded version for Echidna to use the specific test lottery.
    */
    function joinLottery(uint256 r) public {
        joinLottery(address(l), r);
    }

    /**
        Parameterless reveal for Echidna. 
        Uses the stored value from the contract state to ensure a successful reveal.
    */
    function revealLottery() public {
        revealLottery(address(l), rev);
    }

    /**
        Allows the candidate taxpayer to join the same lottery.
    */
    function joinLotteryCandidate(uint256 r) public {
        candidate.joinLottery(address(l), r);
    }

    /**
        Parameterless reveal for the candidate.
    */
    function revealLotteryCandidate() public {
        candidate.revealLottery(address(l), candidate.rev());
    }

    /** 
        Helper function for echidna to end lotteries.
    */
    function endLottery() public {
        l.endLottery();
    }

    /** 
        Check that all participants in the lottery are valid Taxpayer contracts.
        This prevents crashes during the winner notification call.
    */
    function echidna_lottery_participants_valid() public view returns (bool) {
        address[] memory revList = l.getRevealedParticipants();
        for (uint i = 0; i < revList.length; i++) {
            if (revList[i].code.length == 0) return false;
            try Taxpayer(revList[i]).isContract() returns (bool isTax) {
                if (!isTax) return false;
            } catch {
                return false;
            }
        }
        return true;
    }

    /** 
        Check for honest behavior: A participant should not be in the revealed list multiple times.
        Duplicates bias the winning probability (total % n).
    */
    function echidna_lottery_no_duplicates() public view returns (bool) {
        address[] memory revList = l.getRevealedParticipants();
        for (uint i = 0; i < revList.length; i++) {
            for (uint j = i + 1; j < revList.length; j++) {
                if (revList[i] == revList[j]) return false;
            }
        }
        return true;
    }

    /** 
        Check that the lottery is unbiased over many rounds.
        In a fair lottery with two equal participants (this and candidate), 
        the win count difference should not grow excessively large.
    */
    function echidna_lottery_fairness() public view returns (bool) {
        uint256 w1 = lotteryWins;
        uint256 w2 = candidate.lotteryWins();
        
        // After at least some lotteries have been won
        if (w1 + w2 > 10) {
            uint256 diff = w1 > w2 ? w1 - w2 : w2 - w1;
            // A difference of more than 80% of total wins indicates high bias 
            return (diff * 10 < (w1 + w2) * 8); 
        }
        return true;
    }
}
