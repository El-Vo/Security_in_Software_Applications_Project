// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Taxpayer.sol";

contract TestTaxpayer is Taxpayer {
    constructor() Taxpayer(address(0x1), address(0x2)) {}

    /** 
        Check if bool isMarried and spouse address are correctly set in conjunction to each other.
        If the taxpayer isn't married, he/she shouldn't have a spouse address and vice versa.
    */
    function echidna_married_and_spouse_set_at_the_same_time() public view returns (bool) {
        if (isMarried == true) {
            return (spouse != address(0));
        }
        
        return (spouse == address(0));
    }
}