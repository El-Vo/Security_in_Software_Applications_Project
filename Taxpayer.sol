// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./Lottery.sol";

contract Taxpayer {
    uint public age;

    bool isMarried;

    bool iscontract;

    /* Reference to spouse if person is married, address(0) otherwise */
    address spouse;

    address parent1;
    address parent2;

    /* Constant default income tax allowance */
    uint constant DEFAULT_ALLOWANCE = 5000;

    /* Constant income tax allowance for Older Taxpayers over 65 */
    uint constant ALLOWANCE_OAP = 7000;

    /* Income tax allowance */
    uint tax_allowance;

    uint income;

    uint256 public rev;

    mapping(address => bool) public authorizedLotteries;

    bool extended_tax_allowance;

    uint256 public lotteryWins;

    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    modifier onlyValidAddress(address _addr) {
        require(
            isValidSpouseAddress(_addr),
            "Invalid or restricted spouse address"
        );
        _;
    }

    //Parents are taxpayers
    constructor(address p1, address p2) {
        age = 0;
        isMarried = false;
        parent1 = p1;
        parent2 = p2;
        spouse = address(0);
        income = 0;
        tax_allowance = DEFAULT_ALLOWANCE;
        iscontract = true;
        extended_tax_allowance = false;
    }

    /**
     * @dev Establishes a symmetrical marriage with another taxpayer.
     * Uses a reciprocal call to ensure both contracts reflect the marriage.
     * @param new_spouse The address of the spouse's Taxpayer contract.
     */
    function marry(address new_spouse) public onlyValidAddress(new_spouse) {
        if (isMarried && spouse == new_spouse) return;
        require(!isMarried, "Taxpayer is already married");

        Taxpayer sp = Taxpayer(new_spouse);
        require(
            !sp.isMarriedState() || sp.spouseAddress() == address(this),
            "Partner unavailable"
        );

        spouse = new_spouse;
        isMarried = true;
        sp.marry(address(this));
    }

    /**
     * @dev Dissolves the marriage symmetrically.
     * Resets local state first and then triggers divorce in the spouse's contract.
     */
    function divorce() public {
        if (!isMarried) return;

        address oldSpouse = spouse;
        spouse = address(0);
        isMarried = false;

        // Set the default tax allowance again with respect to if the taxpayer has won the lottery or is over 64 years old.
        if (hasExtendedTaxAllowance()) {
            setTaxAllowance(ALLOWANCE_OAP);
        } else {
            setTaxAllowance(DEFAULT_ALLOWANCE);
        }

        Taxpayer(oldSpouse).divorce();
    }

    /**
     * @dev Transfers a portion of the tax allowance to the spouse.
     * Ensures that the deduction and addition are balanced and only possible while married.
     * @param change The amount of allowance to transfer.
     */
    function transferAllowance(uint change) public {
        require(isMarried, "Not married");
        require(change > 0, "Amount must be positive");
        require(change <= tax_allowance, "Insufficient allowance");

        tax_allowance -= change;
        Taxpayer(spouse).receiveAllowance(change);
    }

    /**
     * @dev Receives tax allowance from the spouse.
     * Can only be called by the current spouse contract.
     * @param amount The amount of allowance to receive.
     */
    function receiveAllowance(uint amount) external {
        require(isMarried, "Not married");
        require(msg.sender == spouse, "Only spouse can transfer allowance");
        tax_allowance += amount;
    }

    function haveBirthday() public {
        age++;

        if (age > 64 && !hasExtendedTaxAllowance()) {
            setExtendedTaxAllowance();
        }
    }

    function setTaxAllowance(uint ta) private {
        tax_allowance = ta;
    }

    function getTaxAllowance() public view returns (uint) {
        return tax_allowance;
    }

    function addTaxAllowance(uint ta) private {
        tax_allowance = tax_allowance + ta;
    }

    function setWonLottery() external {
        require(
            authorizedLotteries[msg.sender],
            "Only an authorized lottery can notify win"
        );
        lotteryWins++;
        setExtendedTaxAllowance();
    }

    function setExtendedTaxAllowance() internal {
        if (extended_tax_allowance) return;
        extended_tax_allowance = true;
        addTaxAllowance(ALLOWANCE_OAP - DEFAULT_ALLOWANCE);
    }

    function hasExtendedTaxAllowance() public view returns (bool) {
        return extended_tax_allowance;
    }

    function isMarriedState() public view returns (bool) {
        return isMarried;
    }

    function spouseAddress() public view returns (address) {
        return spouse;
    }

    function isContract() public view returns (bool) {
        return iscontract;
    }

    function joinLottery(address lot, uint256 r) public {
        Lottery lObj = Lottery(lot);
        // Check if it is a lottery contract
        try lObj.isContract() returns (bool isLot) {
            require(isLot, "Address is not a lottery contract");
        } catch {
            revert("Address does not support lottery interface");
        }

        lObj.commit(keccak256(abi.encode(r)));
        rev = r;
        authorizedLotteries[lot] = true;
    }
    function revealLottery(address lot, uint256 r) public {
        Lottery lObj = Lottery(lot);
        lObj.reveal(r);
        rev = 0;
    }

    /**
     * @dev Validates if an address is suitable for contract interactions.
     * Checks against the null address, precompiled contracts (0x1-0x9),
     * the burn address (0xdEaD), and the contract's own address.
     * Additionally verifies that the target is a contract and a valid Taxpayer.
     * @param _addr The address to be validated.
     * @return bool True if the address is valid, false otherwise.
     */
    function isValidSpouseAddress(address _addr) public view returns (bool) {
        if (
            _addr == address(0) ||
            _addr == BURN_ADDRESS ||
            _addr == address(this) ||
            uint160(_addr) <= 9 ||
            _addr.code.length == 0
        ) {
            return false;
        }

        // Try to call isContract() to verify it is a Taxpayer contract
        try Taxpayer(_addr).isContract() returns (bool isTax) {
            return isTax;
        } catch {
            return false;
        }
    }
}
