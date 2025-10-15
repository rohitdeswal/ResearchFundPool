// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Collaborative Research Fund Pool
/// @notice Payable pool where contributors propose and vote to fund research projects
/// @dev No imports, no constructor, no constructor inputs (per request)
contract ResearchFundPool {
    // ----- CONFIG -----
    uint256 public constant PROPOSAL_DURATION = 3 days; // voting window
    uint256 public constant QUORUM_PERCENT = 10; // proposal requires >= 10% of total contributed weight in YES votes to pass
    uint256 public constant MIN_PROPOSAL_AMOUNT = 0.01 ether;

    // ----- STATE -----
    uint256 public totalContributed;                       // total contributed to contract
    mapping(address => uint256) public contributions;      // contributor => amount contributed

    struct Proposal {
        uint256 id;
        string title;
        address payable beneficiary;
        uint256 amount;          // requested amount in wei
        address proposer;
        uint256 yesWeight;       // sum of contributor weights (wei) voting yes
        uint256 noWeight;        // sum of contributor weights (wei) voting no
        uint256 startTime;       // timestamp when created
        uint256 endTime;         // timestamp when voting ends
        bool executed;
    }

    Proposal[] public proposals;

    // voted[proposalId][voter] => true if already voted
    mapping(uint256 => mapping(address => bool)) public voted;

    // ----- EVENTS -----
    event Contributed(address indexed from, uint256 amount);
    event WithdrawnContribution(address indexed from, uint256 amount);
    event ProposalCreated(uint256 indexed id, address indexed proposer, address beneficiary, uint256 amount, uint256 endTime);
    event Voted(uint256 indexed id, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed id, bool success);

    // ----- FUNCTIONS -----

    /// @notice Contribute to the common research fund
    receive() external payable {
        _contribute(msg.sender, msg.value);
    }
    fallback() external payable {
        _contribute(msg.sender, msg.value);
    }

    /// @notice Contribute explicit function
    function contribute() external payable {
        _contribute(msg.sender, msg.value);
    }

    function _contribute(address from, uint256 amount) internal {
        require(amount > 0, "No funds sent");
        contributions[from] += amount;
        totalContributed += amount;
        emit Contributed(from, amount);
    }

    /// @notice Create a funding proposal. Only contributors (with >0 contribution) may propose.
    /// @param title Short title or description of the research project
    /// @param beneficiary Address to receive funds if proposal passes
    /// @param amount Requested amount in wei
    function createProposal(string memory title, address payable beneficiary, uint256 amount) external returns (uint256) {
        require(contributions[msg.sender] > 0, "Only contributors can propose");
        require(bytes(title).length > 0, "Title required");
        require(beneficiary != address(0), "Invalid beneficiary");
        require(amount >= MIN_PROPOSAL_AMOUNT, "Amount too small");
        require(amount <= address(this).balance, "Requested > pool balance");

        uint256 id = proposals.length;
        uint256 start = block.timestamp;
        uint256 endt = start + PROPOSAL_DURATION;

        proposals.push(Proposal({
            id: id,
            title: title,
            beneficiary: beneficiary,
            amount: amount,
            proposer: msg.sender,
            yesWeight: 0,
            noWeight: 0,
            startTime: start,
            endTime: endt,
            executed: false
        }));

        emit ProposalCreated(id, msg.sender, beneficiary, amount, endt);
        return id;
    }

    /// @notice Vote on a proposal. Voting power = contributor's current contribution (wei).
    /// @param proposalId ID of the proposal
    /// @param support true = yes, false = no
    function vote(uint256 proposalId, bool support) external {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal storage p = proposals[proposalId];
        require(block.timestamp >= p.startTime, "Voting not started");
        require(block.timestamp <= p.endTime, "Voting ended");
        require(contributions[msg.sender] > 0, "Must be a contributor to vote");
        require(!voted[proposalId][msg.sender], "Already voted");

        uint256 weight = contributions[msg.sender];
        require(weight > 0, "No voting weight");

        voted[proposalId][msg.sender] = true;
        if (support) {
            p.yesWeight += weight;
        } else {
            p.noWeight += weight;
        }

        emit Voted(proposalId, msg.sender, support, weight);
    }

    /// @notice Execute a proposal after voting ends. Transfers funds if it passed.
    /// @param proposalId ID of the proposal
    function executeProposal(uint256 proposalId) external {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal storage p = proposals[proposalId];
        require(block.timestamp > p.endTime, "Voting still active");
        require(!p.executed, "Already executed");

        // Determine quorum: yesWeight must be >= QUORUM_PERCENT of totalContributed
        // and yesWeight > noWeight
        uint256 requiredQuorum = (totalContributed * QUORUM_PERCENT) / 100;
        bool hasQuorum = p.yesWeight >= requiredQuorum;
        bool majority = p.yesWeight > p.noWeight;
        bool enoughBalance = p.amount <= address(this).balance;

        bool success = false;
        if (hasQuorum && majority && enoughBalance) {
            // Effects
            p.executed = true;
            // Interaction
            (bool sent, ) = p.beneficiary.call{value: p.amount}("");
            if (sent) {
                success = true;
            } else {
                // If send fails, revert executed flag so it can be retried or refunded by governance later
                p.executed = false;
                success = false;
            }
        } else {
            // Mark executed to prevent replays even if failed to meet thresholds, but keep executed=false if
            // we want to allow retry/corrections. Here we mark executed = true only on success to allow reattempts.
            success = false;
        }

        emit ProposalExecuted(proposalId, success);
    }

    /// @notice Simple withdrawal: contributors may withdraw part/all of their contribution.
    /// @dev Withdrawing reduces voting power for future proposals and may affect past proposals' quorum logic.
    /// @param amount Amount to withdraw in wei
    function withdrawContribution(uint256 amount) external {
        require(amount > 0, "Amount zero");
        uint256 bal = contributions[msg.sender];
        require(bal >= amount, "Not enough contributed");
        contributions[msg.sender] = bal - amount;
        totalContributed -= amount;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Transfer failed");
        emit WithdrawnContribution(msg.sender, amount);
    }

    // ----- VIEW HELPERS -----

    /// @notice Number of proposals created
    function proposalsCount() external view returns (uint256) {
        return proposals.length;
    }

    /// @notice Get proposal summary
    function getProposal(uint256 proposalId) external view returns (
        uint256 id,
        string memory title,
        address beneficiary,
        uint256 amount,
        address proposer,
        uint256 yesWeight,
        uint256 noWeight,
        uint256 startTime,
        uint256 endTime,
        bool executed
    ) {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal storage p = proposals[proposalId];
        return (
            p.id,
            p.title,
            p.beneficiary,
            p.amount,
            p.proposer,
            p.yesWeight,
            p.noWeight,
            p.startTime,
            p.endTime,
            p.executed
        );
    }
}
