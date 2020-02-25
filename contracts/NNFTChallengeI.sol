pragma solidity ^0.5.0;

contract NNFTChallengeI {
    function solveChallenge(uint256 _cid, uint256[] memory _solution)
        public
        returns (bool isChallengeSolved);
    function operator() public returns (address payable op);
}
