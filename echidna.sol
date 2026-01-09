// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Taxpayer.sol";

contract TestTaxpayer is Taxpayer {
    Taxpayer public candidate;

    constructor() Taxpayer(address(0x11), address(0x12)) {
        candidate = new Taxpayer(address(0x13), address(0x14));
    }

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
    function marry_candidate() public {
        marry(address(candidate));
    }

    function divorce_candidate() public {
        divorce();
    }
}
