pragma solidity ^0.5.0;

import "./NNFTChallenge.sol";

contract Taxicab is NNFTChallenge {
    mapping(uint256 => uint256) private _cidToBest;

    function cube(uint256 _value) internal pure returns (uint256 cubeValue) {
        return _value * _value * _value;
    }

    function solveChallenge(uint256 _cid, uint256[] memory _s)
        public
        onlyNNFT
        returns (bool isChallengeSolved)
    {
        if (_s.length % 2 != 0) return false;
        if (_s.length / 2 != _cid) return false;
        if (_s[1] < _s[0]) return false;

        uint256 v = cube(_s[0]) + cube(_s[1]);
        if (_cidToBest[_cid] != 0 && v >= _cidToBest[_cid]) return false;

        for (uint256 i = 3; i <= _s.length; i += 2) {
            uint256 vCheck = cube(_s[i]) + cube(_s[i - 1]);
            if (vCheck != v) return false;
            if (_s[i] < _s[i - 1]) return false;

            for (uint256 j = 1; j < i; j += 2) {
                if (_s[j] == _s[i]) return false;
            }
        }

        _cidToBest[_cid] = v;
        return true;
    }
}
