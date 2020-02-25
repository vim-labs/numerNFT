pragma solidity ^0.5.0;

import "../node_modules/@OpenZeppelin/contracts/math/SafeMath.sol";

contract NNFTChallenge {
    using SafeMath for uint256;

    address private _nnft_contract = 0x2CF87588A02a967C0A3b6442793177436C029B4A;
    address payable private _operator;

    modifier onlyChallengeOperator() {
        require(msg.sender == _operator, "Unauthorized.");
        _;
    }

    modifier onlyNNFT() {
        require(msg.sender == _nnft_contract, "Unauthorized.");
        _;
    }

    constructor() public {
        _operator = msg.sender;
    }

    function operator() public view returns (address payable op) {
        return _operator;
    }

    function updateOperator(address payable _addr)
        public
        onlyChallengeOperator()
    {
        _operator = _addr;
    }

    function updateNNFTContract(address _addr) public onlyChallengeOperator() {
        _nnft_contract = _addr;
    }
}
