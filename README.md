# LuckyX Airdrop NFT

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue.svg)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-orange.svg)](https://getfoundry.sh/)

A gas-efficient NFT airdrop smart contract using Merkle Tree verification, with full support for ERC721 and ERC2981 royalty standards.

## Features

- **Merkle Tree Whitelist Verification** - Efficient whitelist validation using Merkle Proofs, saving gas costs
- **ERC721 Standard** - Fully compatible with the ERC721 NFT standard
- **ERC2981 Royalty Standard** - On-chain royalty configuration, compatible with OpenSea and other major marketplaces
- **Bitmap Anti-Double-Claim** - Efficient tracking of claimed status using bitmap mechanism
- **Flexible URI Management** - Support for dynamic baseURI and contractURI updates
- **Secure Access Control** - Permission management based on OpenZeppelin Ownable

## Project Structure

```
├── src/
│   └── PioneerBadgeNFT.sol      # Main contract
├── script/
│   └── PioneerBadgeNFT.s.sol    # Deployment script
├── test/
│   └── PioneerBadgeNFT.t.sol    # Test files
├── lib/                         # Dependencies
│   ├── forge-std/
│   ├── openzeppelin-contracts/
│   └── openzeppelin-contracts-upgradeable/
└── foundry.toml                 # Foundry configuration
```

## Installation

### Prerequisites

- [Foundry](https://getfoundry.sh/) - Solidity development framework

### Clone Repository

```shell
git clone https://github.com/Luckyx-Labs/LuckyXAirdropNFT.git
cd LuckyXAirdropNFT
```

### Install Dependencies

```shell
forge install
```

To install OpenZeppelin separately:

```shell
forge install OpenZeppelin/openzeppelin-contracts
forge install OpenZeppelin/openzeppelin-contracts-upgradeable
```

## Usage

### Build Contracts

```shell
forge build
```

### Run Tests

```shell
forge test
```

Run tests with verbose output:

```shell
forge test -vvv
```

### Format Code

```shell
forge fmt
```

### Gas Report

```shell
forge snapshot
```

## Deployment

### 1. Configure Environment Variables

Create a `.env` file:

```shell
RPC_URL=your_rpc_url
PRIVATE_KEY=your_private_key
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### 2. Deploy Contract

```shell
source .env
forge script script/PioneerBadgeNFT.s.sol:PioneerBadgeNFTDeploy --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### 3. Verify Contract

Supports Etherscan V2 API (for Base, Arbitrum, Polygon, etc.):

```shell
forge verify-contract \
    --chain <CHAIN_ID> \
    --verifier-url https://api.etherscan.io/v2/api?chainid=<CHAIN_ID> \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    <DEPLOYED_CONTRACT_ADDRESS> \
    src/PioneerBadgeNFT.sol:PioneerBadgeNFT
```

Example (Base Sepolia):

```shell
forge verify-contract \
    --chain 8453 \
    --verifier-url https://api.etherscan.io/v2/api?chainid=8453 \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    0xC3fA98FbD5562F7544C1Df586ED4f136505079A1 \
    src/PioneerBadgeNFT.sol:PioneerBadgeNFT
```

## Contract Interface

### Main Functions

| Function | Description |
|----------|-------------|
| `mint(uint256 index, bytes32[] calldata merkleProof)` | Claim NFT using Merkle Proof |
| `setMerkleRoot(bytes32 _newRoot)` | Set Merkle Root (owner only) |
| `setMintActive(bool _active)` | Enable/disable minting (owner only) |
| `isMinted(uint256 index)` | Check if an index has been claimed |
| `setBaseURI(string memory newBaseURI)` | Update Base URI (owner only) |
| `setContractURI(string memory newContractURI)` | Update Contract URI (owner only) |
| `setDefaultRoyalty(address receiver, uint96 feeNumerator)` | Set default royalty (owner only) |

### Events

| Event | Description |
|-------|-------------|
| `MerkleRootUpdated(bytes32 indexed newRoot)` | Emitted when Merkle Root is updated |
| `BaseURIUpdated(string newBaseURI)` | Emitted when Base URI is updated |
| `ContractURIUpdated(string newContractURI)` | Emitted when Contract URI is updated |

## Configuration

`foundry.toml` configuration:

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = [
    "@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/",
    "@openzeppelin/contracts-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts/"
]
```

## Security

- Built on audited OpenZeppelin contract libraries
- Secure and efficient whitelist verification using Merkle Proofs
- Bitmap mechanism prevents double-claim attacks
- All admin functions have access control

## License

This project is open source under the [MIT License](LICENSE).

##  Contributing

Issues and Pull Requests are welcome!

##  Contact

- GitHub: [Luckyx-Labs](https://github.com/Luckyx-Labs)
