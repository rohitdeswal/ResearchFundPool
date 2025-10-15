
# 🧠 Collaborative Research Fund Pool

A decentralized **Collaborative Research Funding Pool** built on Solidity.  
This smart contract allows contributors to pool ETH, create proposals for research funding, vote on them, and automatically release funds to approved projects.

> 💡 Deployed Contract Address:  
> **`0x72b777e6651cB95b06571728c049311fe0130866`**

---

## 🚀 Overview

This contract enables open, transparent, and democratic funding for research projects.  
Participants can:

- 💰 **Contribute ETH** to the common research pool.  
- 🧾 **Create Proposals** requesting funding for research ideas.  
- 🗳️ **Vote** on proposals (based on contribution weight).  
- 💸 **Execute** approved proposals that meet quorum and majority.  
- 🔙 **Withdraw** their unused contributions anytime.

---

## ⚙️ Contract Details

| Property | Description |
|-----------|--------------|
| **Network** | Ethereum-compatible (EVM) |
| **Language** | Solidity ^0.8.19 |
| **License** | MIT |
| **Constructor** | ❌ None |
| **Imports** | ❌ None |
| **Deployment Inputs** | ❌ None |

---

## 📜 Core Features

### 🏦 Contribution
Anyone can contribute ETH to the fund by calling:
```solidity
function contribute() external payable;
````

or simply by sending ETH directly to the contract address.

### 🧑‍🔬 Proposal Creation

Only contributors can create funding proposals:

```solidity
function createProposal(string memory title, address payable beneficiary, uint256 amount);
```

### 🗳️ Voting

Each contributor can vote (Yes/No) once per proposal.
Voting weight = ETH contributed.

### 💼 Execution

After the voting window (3 days), anyone can execute a proposal:

```solidity
function executeProposal(uint256 proposalId);
```

If quorum (10%) and majority are met, funds are released to the beneficiary.

### 💸 Withdraw Contributions

Contributors can withdraw their funds:

```solidity
function withdrawContribution(uint256 amount);
```

---

## 📊 Governance Rules

| Rule                    | Description          |
| ----------------------- | -------------------- |
| **Voting Duration**     | 3 days               |
| **Quorum**              | ≥ 10% of total pool  |
| **Majority**            | YES votes > NO votes |
| **Min Proposal Amount** | 0.01 ETH             |

---

## 🧩 Events

| Event                                                                                                 | Description             |
| ----------------------------------------------------------------------------------------------------- | ----------------------- |
| `Contributed(address from, uint256 amount)`                                                           | Logs new contributions  |
| `ProposalCreated(uint256 id, address proposer, address beneficiary, uint256 amount, uint256 endTime)` | Logs new proposals      |
| `Voted(uint256 id, address voter, bool support, uint256 weight)`                                      | Logs voting actions     |
| `ProposalExecuted(uint256 id, bool success)`                                                          | Logs executed proposals |
| `WithdrawnContribution(address from, uint256 amount)`                                                 | Logs withdrawals        |

---

## 🧪 Testing & Usage

### Deploy Locally (Remix or Hardhat)

1. Open Remix IDE → paste the contract code.
2. Compile using **Solidity 0.8.19**.
3. Deploy without constructor parameters.
4. Interact via the Remix interface or a Web3 frontend.

### Example Commands (Remix / Web3)

* Contribute: `contribute()` or send ETH directly.
* Create Proposal: `createProposal("AI Research", 0xBeneficiary, 1000000000000000000)`
* Vote: `vote(0, true)`
* Execute: `executeProposal(0)`

---

## ⚠️ Security Notes

* Not audited (use for learning/demo only).
* Votes depend on live contributions (no snapshot).
* Reentrancy-safe for ETH sends via `call`, but audits recommended before mainnet use.
* Always test on testnet first!

---

## ❤️ Credits

Built for open collaboration and innovation in decentralized research.
Made with Solidity and a sprinkle of **desi developer hustle 💪**.

---

**License:** MIT
**Author:** [Freaky Feed Labs](https://github.com/)
**Deployed Address:** `0x72b777e6651cB95b06571728c049311fe0130866`

```

---

Bata bhai — chaahe main is README mein ek **badge section** (Build | License | Solidity version) aur **usage GIFs/screenshots** bhi add kar du for GitHub polish?  
Chahta hai kya thoda professional GitHub look?
```
