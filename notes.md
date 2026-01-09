# Things to consider:
- 4 parts of a traditional contract reflected in smart contract
    - Offer and acceptance
    - Consideration
    - Mutuality
    - Capacity/Legality

# Task 1:
- Check if person is married
    - If so, check if spouse is set
        - If so, check if spouse is also married
            - If so, check if spouse is married to person
- Assumption: monogamous marriage >> No marriage allowed if already married
- Check that parent aren't allowed to be yourself and the same
- Check that the contract can only be called by the owner?
- Reciprocal marriage prompting?
- One wallet/account could create multiple taxpayers!

## Preliminary Results:
- echidna_married_and_spouse_set_at_the_same_time: failed!💥  
  Call sequence:
    TestTaxpayer.marry(0x0)
    - Solution: filter addresses for invalid values such as 0x0-0x9,0xdEaD, one's own address

# Task 2:
- Check that tax allowance can only be transferred if person is married
- Check that tax allowance can never exceed the combined starting value
- What happens to lottery winners that divorce?
- Refrain from "resetting" allowance after winning the lottery, give instead a 2000 bonus
- Check that tax allowance cannot go below zero
- Implementation of transfer and receive allowance to minimize tamper potential and only add funds that are deducted in the main account

## Preliminary Results:
echidna_valid_tax_allowance: failed!💥  
  Call sequence:
    TestTaxpayer.marry_candidate()
    TestTaxpayer.transferAllowance(1)
    TestTaxpayer.divorce()

# Task 3:
- Check that lottery win doesn't influence the allowance for people over 64
