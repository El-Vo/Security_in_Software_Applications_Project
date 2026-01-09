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

## Results:
- echidna_married_and_spouse_set_at_the_same_time: failed!💥  
  Call sequence:
    TestTaxpayer.marry(0x0)
    - Solution: filter addresses for invalid values such as 0x0-0x9,0xdEaD, one's own address