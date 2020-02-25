pragma solidity ^0.5.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "../node_modules/@openzeppelin/contracts/ownership/Ownable.sol";
import "./NNFTChallengeI.sol";

contract NumerNFT is ERC721Full, Ownable {
    event Solved(uint256 _id, uint256 _cid, uint256 _idx, address _solver);

    struct Challenge {
        string name;
        address addr;
    }

    uint256 private _tokenId = 0;
    uint256 private _challengeId = 0;
    address payable private _numerNFTOperator;
    mapping(uint256 => Challenge) private _idToChallenge;
    mapping(uint256 => address) private _idToOperator;
    mapping(string => uint256) private _nameToChallenge;
    mapping(uint256 => uint256) private _tokenIdToId;
    mapping(uint256 => uint256) private _tokenIdToCid;
    mapping(uint256 => uint256) private _tokenIdToIdx;
    mapping(uint256 => mapping(uint256 => uint256)) private _idToCidToSolvers;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) private _idToCidToSolverToIdx;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private _idToCidToIdxToReward;
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => bool))) private _idToCidToCommitSolved;
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => address))) private _idToCidToCommitToSolver;

    modifier onlyNumerNFTOperator() {
        require(msg.sender == _numerNFTOperator, "Unauthorized.");
        _;
    }

    modifier onlyOperator(uint256 _id) {
        require(_idToOperator[_id] == msg.sender, "Unauthorized.");
        _;
    }

    modifier onlyValidChallenges(uint256 _id) {
        require(_idToOperator[_id] != address(0), "Not found.");
        _;
    }

    modifier onlyValidTokens(uint256 _id) {
        require(_id <= _tokenId, "Not found.");
        _;
    }

    modifier onlyUnsolvedChallenges(uint256 _id, uint256 _cid, uint256 _idx) {
        require(_idToOperator[_id] != address(0), "Not found.");
        require(_idx > _idToCidToSolvers[_id][_cid], "Already solved.");
        _;
    }

    constructor() public ERC721Full("NumerNFT", "NNFT") {
        _numerNFTOperator = msg.sender;
    }

    function updateNumerNFTOperator(address payable _newOperator)
        public
        onlyNumerNFTOperator
    {
        _numerNFTOperator = _newOperator;
    }

    function updateOperator(uint256 _id, address payable _operator)
        public
        onlyOperator(_id)
    {
        _idToOperator[_id] = _operator;
    }

    function challenges() public view returns (uint256 totalChallenges) {
        return _challengeId;
    }

    function challengeName(uint256 _id)
        public
        view
        returns (string memory name)
    {
        return _idToChallenge[_id].name;
    }

    function challenge(string memory _name) public view returns (uint256 id) {
        return _nameToChallenge[_name];
    }

    function challengeAddress(uint256 _id) public view returns (address addr) {
        return _idToChallenge[_id].addr;
    }

    function addChallenge(string memory _name, address _addr) public {
        require(_nameToChallenge[_name] == 0, "Alreaedy registered.");
        _challengeId += 1;
        _nameToChallenge[_name] = _challengeId;
        _idToOperator[_challengeId] = msg.sender;
        _idToChallenge[_challengeId] = Challenge({name: _name, addr: _addr});
    }

    function updateChallengeAddress(uint256 _id, address _addr)
        public
        onlyOperator(_id)
    {
        _idToChallenge[_id].addr = _addr;
    }

    function commit(uint256 _id, uint256 _cid, bytes32 _commitHash) public {
        if (_idToCidToCommitToSolver[_id][_cid][_commitHash] == address(0)) {
            _idToCidToCommitToSolver[_id][_cid][_commitHash] = msg.sender;
        }
    }

    function addReward(uint256 _id, uint256 _cid, uint256 _idx)
        public
        payable
        onlyValidChallenges(_id)
        onlyUnsolvedChallenges(_id, _cid, _idx)
    {
        _idToCidToIdxToReward[_id][_cid][_idx] += msg.value;
    }

    function reward(uint256 _id, uint256 _cid, uint256 _idx)
        public
        view
        returns (uint256 rewards)
    {
        return _idToCidToIdxToReward[_id][_cid][_idx];
    }

    function solvers(uint256 _id, uint256 _cid)
        public
        view
        returns (uint256 totalSolvers)
    {
        return _idToCidToSolvers[_id][_cid];
    }

    function tokenIdToId(uint256 _tokId)
        public
        view
        onlyValidTokens(_tokId)
        returns (uint256 _tokenChallengeId)
    {
        return _tokenIdToId[_tokId];
    }

    function tokenIdToCid(uint256 _tokId)
        public
        view
        onlyValidTokens(_tokId)
        returns (uint256 _tokenChallengeCid)
    {
        return _tokenIdToCid[_tokId];
    }

    function tokenIdToIndex(uint256 _tokId)
        public
        view
        onlyValidTokens(_tokId)
        returns (uint256 _tokenChallengePlace)
    {
        return _tokenIdToIdx[_tokId];
    }

    function tokenIdToPlace(uint256 _tokId)
        public
        view
        onlyValidTokens(_tokId)
        returns (uint256 _tokenChallengePlace)
    {
        uint256 id = tokenIdToId(_tokId);
        uint256 cid = tokenIdToCid(_tokId);
        uint256 totalSolvers = solvers(id, cid);
        uint256 solutionIdx = tokenIdToIndex(_tokId);
        return totalSolvers - solutionIdx + 1;
    }

    function tokenIdToName(uint256 _tokId)
        public
        view
        onlyValidTokens(_tokId)
        returns (string memory tokenName)
    {
        uint256 id = tokenIdToId(_tokId);
        return _idToChallenge[id].name;
    }

    function solve(uint256 _id, uint256 _cid, uint256[] memory _solution)
        public
        onlyValidChallenges(_id)
        returns (bool isSolved)
    {
        bytes32 commitHash = keccak256(abi.encodePacked(_solution));
        require(
            _idToCidToCommitToSolver[_id][_cid][commitHash] != address(0),
            "Not found."
        );

        require(
            !_idToCidToCommitSolved[_id][_cid][commitHash],
            "Already solved."
        );

        address payable solver = address(
            uint160(_idToCidToCommitToSolver[_id][_cid][commitHash])
        );

        NNFTChallengeI challengeContract = NNFTChallengeI(
            _idToChallenge[_id].addr
        );
        bool isSolution = challengeContract.solveChallenge(_cid, _solution);

        if (isSolution) {
            _tokenId += 1;
            _idToCidToSolvers[_id][_cid] += 1;

            uint256 _idx = _idToCidToSolvers[_id][_cid];

            _idToCidToCommitSolved[_id][_cid][commitHash] = true;
            _tokenIdToId[_tokenId] = _id;
            _tokenIdToCid[_tokenId] = _cid;
            _tokenIdToIdx[_tokenId] = _idx;
            _idToCidToSolverToIdx[_id][_cid][solver] = _idx;
            _mint(solver, _tokenId);

            uint256 _rewards = _idToCidToIdxToReward[_id][_cid][_idx];

            if (_rewards > 0) {
                uint256 _fee = _rewards / 20;
                uint256 _reward = _rewards - _fee;

                if (_fee > 0) {
                    _numerNFTOperator.transfer(_fee / 2);
                    challengeContract.operator().transfer(_fee / 2);
                }
                solver.transfer(_reward);
                _idToCidToIdxToReward[_id][_cid][_idx] = 0;
            }

            emit Solved(_id, _cid, _idx, solver);

            return true;
        }

        return false;
    }
}
