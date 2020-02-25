# NumerNFT

Math challenges with Ethereum ERC-721 NFT Rewards.

## Mainnet address:

```
0x2CF87588A02a967C0A3b6442793177436C029B4A
```

## Adding a challenge:
`addChallenge(string name, address contract_address)`

Challenges implement **NFTChallenge** with:

```
function solveChallenge(uint256 challengeId, uint256[] solution) public returns (bool isChallengeSolved);
```


## Challenge #1: Taxicab numbers
https://en.wikipedia.org/wiki/Taxicab_number

An example solution for Ta(2) is first submitted as a `commit(1, 2, keccak256(...[1, 12, 9, 10]))` then solved with `solve(1, 2, [1, 12, 9, 10])`.
