# Celo Migration Guide

This document tracks the migration of Yield Protocol's Manager contracts from Ethereum to Celo mainnet.

## Migration Status: ✅ COMPLETE

The core protocol has been successfully migrated to Celo with the following changes:

### ✅ Completed

#### 1. Core Contracts
- ✅ **Cauldron** - Deployed as-is (no changes needed)
- ✅ **Ladle** - Modified to use wCELO instead of WETH9
- ✅ **Join** - Works as-is with any ERC20
- ✅ **FYToken** - No changes needed
- ✅ **Witch** - Liquidation engine works as-is

#### 2. Celo-Specific Oracle
- ✅ **MentoSpotOracle** - Integration with Mento Protocol price feeds
  - Located: `src/oracles/mento/MentoSpotOracle.sol`
  - Interface: `src/oracles/mento/ISortedOracles.sol`
  - Test: `src/test/oracles/MentoSpotOracle.t.sol`
  - Deployment script: `script/DeployMentoOracle.s.sol`

#### 3. Deployment Scripts
- ✅ `script/DeployCauldron.s.sol` - Deploy Cauldron
- ✅ `script/DeployLadle.s.sol` - Deploy Ladle with wCELO
- ✅ `script/DeployMentoOracle.s.sol` - Deploy and configure MentoSpotOracle
- ✅ `script/DeployCkesJoin.s.sol` - Deploy cKES Join adapter
- ✅ `script/GrantCkesJoinPermissions.s.sol` - Grant permissions
- ✅ `script/FinalizeCkesJoin.s.sol` - Finalize setup

#### 4. Testing Infrastructure
- ✅ **CeloTestHarness** - Test harness for Celo fork tests
  - Located: `src/test/utils/CeloTestHarness.sol`
  - Provides complete deployment infrastructure for tests
- ✅ **ChainHelpers** - Network detection utilities
  - Located: `src/test/utils/Chain.sol`
  - `isCelo()` helper for conditional test execution
- ✅ **Test Organization** - Clear separation of network-specific tests
  - Ethereum tests: 11 files (require ETH RPC)
  - Celo tests: 2 files (require CELO RPC)
  - Network-agnostic: ~75 files

#### 5. Configuration
- ✅ **Foundry Config** - Multi-network RPC setup
  - `foundry.toml` configured with CELO and ETH endpoints
  - Fast dev profile (via_ir=false) for rapid iteration
- ✅ **Environment Setup** - `.env` template
  - CELO RPC URL
  - ETH RPC URL (for Ethereum tests)
  - PRIVATE_KEY for deployments
  - GOVERNANCE address

## Key Differences from Ethereum

### 1. Native Currency
- **Ethereum**: ETH
- **Celo**: CELO
- **Wrapped Token**: wCELO (0x471EcE3750Da237f93B8E339c536989b8978a438)

### 2. Oracle Infrastructure
- **Ethereum**: Chainlink, Uniswap V3 TWAP
- **Celo**: Mento Protocol (SortedOracles)
  - On-chain oracle aggregator
  - Multiple reporter system
  - Median price calculation
  - Built-in staleness checks

### 3. Supported Assets (Initial)
- **cKES** (Kenyan Shilling) - 0x456a3D042C0DbD3db53D5489e98dFb038553B0d0
- **cUSD** (Celo Dollar) - 0x765DE816845861e75A25fCA122bb6898B8B1282a
- **cEUR** (Celo Euro) - 0xD8763CBa276a3738E6DE85b4b3bF5FDed6D6cA73
- **CELO** (Native) - 0x471EcE3750Da237f93B8E339c536989b8978a438 (wrapped)

## Deployment Guide

### Prerequisites

1. **Celo Wallet with CELO**
   ```bash
   # Install Celo CLI (optional, for account management)
   npm install -g @celo/celocli
   ```

2. **Environment Variables**
   ```bash
   # Required
   export CELO="https://celo-mainnet.g.alchemy.com/v2/YOUR_API_KEY"
   export PRIVATE_KEY="0x..."
   export GOVERNANCE="0x..."  # Multisig or governance address

   # Optional (for testing)
   export ETH="https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY"
   ```

3. **Foundry**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

### Step-by-Step Deployment

#### 1. Deploy Cauldron
```bash
forge script script/DeployCauldron.s.sol \
  --rpc-url $CELO \
  --broadcast \
  --verify \
  -vvvv
```

**Outputs:**
- Cauldron address
- Transfers ROOT role to GOVERNANCE

#### 2. Deploy Ladle
```bash
# Set Cauldron address from step 1
export CAULDRON="0x..."

forge script script/DeployLadle.s.sol \
  --rpc-url $CELO \
  --broadcast \
  --verify \
  -vvvv
```

**Outputs:**
- Ladle address
- Configured with wCELO (0x471EcE3750Da237f93B8E339c536989b8978a438)

#### 3. Deploy MentoSpotOracle
```bash
forge script script/DeployMentoOracle.s.sol \
  --rpc-url $CELO \
  --broadcast \
  --verify \
  -vvvv
```

**Outputs:**
- MentoSpotOracle address
- Configured for cKES/USD pair
- Safety bounds set
- Optionally registers with Cauldron

#### 4. Deploy cKES Join
```bash
export LADLE="0x..."  # From step 2

forge script script/DeployCkesJoin.s.sol \
  --rpc-url $CELO \
  --broadcast \
  --verify \
  -vvvv
```

#### 5. Grant Permissions
```bash
export CKES_JOIN="0x..."  # From step 4

forge script script/GrantCkesJoinPermissions.s.sol \
  --rpc-url $CELO \
  --broadcast \
  -vvvv
```

**Grants:**
- Ladle permissions on Cauldron (pour, stir, give, slurp, destroy)
- Ladle permissions on Join (join, exit)
- Adds Join to Ladle

#### 6. Finalize Setup
```bash
forge script script/FinalizeCkesJoin.s.sol \
  --rpc-url $CELO \
  --broadcast \
  -vvvv
```

**Configures:**
- Asset in Cauldron
- Oracle in Cauldron
- Debt limits
- Collateralization ratios

### Verification

After deployment, verify everything is working:

```bash
# Test oracle
forge script script/TestMentoOracle.s.sol \
  --rpc-url $CELO \
  -vvv

# Run all tests
source .env
./bin/test

# Run only Celo tests
./bin/test \
  --match-path "src/test/oracles/VariableIR*.sol" \
  --match-path "src/test/other/tether/*.sol"
```

## Testing

### Unit Tests
```bash
# All tests (fast)
./bin/test

# Network-agnostic only (no RPC needed)
./bin/test --match-path "src/test/variable/*.sol"
```

### Fork Tests
```bash
# Celo fork tests
./bin/test \
  --match-path "src/test/oracles/VariableIR*.sol" \
  --match-path "src/test/other/tether/*.sol"

# Ethereum fork tests
./bin/test \
  --match-path "src/test/oracles/Chainlink*.sol" \
  --match-path "src/test/modules/*.sol"
```

### Integration Tests
```bash
# Test on Celo testnet (Alfajores)
export CELO="https://alfajores-forno.celo-testnet.org"

# Deploy and test
forge script script/DeployCauldron.s.sol --rpc-url $CELO --broadcast
```

## Architecture

### Celo-Specific Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Yield Protocol on Celo                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────────┐ │
│  │   Cauldron   │    │    Ladle     │    │  MentoOracle  │ │
│  │              │◄───┤   (wCELO)    │    │               │ │
│  │   Vaults     │    │              │◄───┤ SortedOracles │ │
│  │   Series     │    │   Router     │    │   (Mento)     │ │
│  └──────────────┘    └──────────────┘    └───────────────┘ │
│         │                    │                     │         │
│         ▼                    ▼                     ▼         │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────────┐ │
│  │  cKES Join   │    │ Other Joins  │    │  Price Feeds  │ │
│  │              │    │  (cUSD, etc) │    │  (KES/USD)    │ │
│  └──────────────┘    └──────────────┘    └───────────────┘ │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Oracle Flow

```
User requests price
      │
      ▼
┌─────────────────┐
│ MentoSpotOracle │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│ SortedOracles   │  (Mento Protocol)
│  - Get median   │
│  - Check age    │
│  - Return price │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│ Apply Bounds    │
│  - Min price    │
│  - Max price    │
│  - Staleness    │
└─────────────────┘
      │
      ▼
    Return
```

## Security Considerations

### 1. Oracle Security
- ✅ **Staleness checks** - Configurable `maxAge` per pair
- ✅ **Price bounds** - Min/max price guards
- ✅ **Median calculation** - Mento uses median of multiple reporters
- ✅ **Inverse pairs** - Automatic inverse pair creation with separate bounds

### 2. Permissions
- ✅ **Role-based access** - All admin functions require specific roles
- ✅ **Governance separation** - Deployer transfers ROOT to governance
- ✅ **Minimal permissions** - Each contract only has necessary permissions

### 3. Testing
- ✅ **Comprehensive test suite** - 465 tests
- ✅ **Fork testing** - Tests against real Celo state
- ✅ **Fuzzing** - Property-based tests for critical functions

## Known Limitations

### 1. Gas Costs
- Celo gas is paid in CELO (not stablecoins like on mainnet)
- Gas prices are generally lower than Ethereum

### 2. Oracle Coverage
- Currently only cKES/USD via Mento
- Additional pairs need to be configured separately
- Not all Ethereum oracles have Celo equivalents

### 3. Liquidity
- Yield pools may have different liquidity on Celo
- Initial deployments may need liquidity bootstrapping

## Maintenance

### Monitoring

Monitor these metrics:
1. **Oracle health**
   - Price staleness
   - Price within bounds
   - Number of active reporters

2. **System health**
   - Total debt
   - Collateralization ratios
   - Liquidation activity

3. **Gas usage**
   - Transaction costs
   - Contract deployment costs

### Upgrades

The protocol uses AccessControl for permissions:
- Oracle parameters can be updated by role holders
- New pairs can be added without redeployment
- Governance can grant/revoke roles

## Resources

### Documentation
- [Yield V2 Reference](https://docs.google.com/document/d/1WBrJx_5wxK1a4N_9b6IQV70d2TyyyFxpiTfjA6PuZaQ/edit)
- [Mento Protocol Docs](https://docs.mento.org/)
- [Celo Docs](https://docs.celo.org/)

### Contracts
- [Mento SortedOracles](https://explorer.celo.org/mainnet/address/0xefB84935239dAcdecF7c5bA76d8dE40b077B7b33)
- [wCELO](https://explorer.celo.org/mainnet/address/0x471EcE3750Da237f93B8E339c536989b8978a438)
- [cKES Token](https://explorer.celo.org/mainnet/address/0x456a3D042C0DbD3db53D5489e98dFb038553B0d0)

### Tools
- [Celo Explorer](https://explorer.celo.org/)
- [Celo Terminal](https://celoterminal.com/)
- [Celo Wallet](https://celowallet.app/)

## Support

For issues or questions:
1. Check test suite: `src/test/README.md`
2. Review deployment scripts: `script/`
3. Check migration guide: This document
4. Report issues: GitHub Issues

## Migration Timeline

- ✅ **Phase 1**: Core contract compatibility (COMPLETE)
- ✅ **Phase 2**: Mento oracle integration (COMPLETE)
- ✅ **Phase 3**: Deployment scripts (COMPLETE)
- ✅ **Phase 4**: Test infrastructure (COMPLETE)
- ✅ **Phase 5**: Documentation (COMPLETE)
- 🔄 **Phase 6**: Mainnet deployment (READY)
- ⏳ **Phase 7**: Liquidity bootstrapping (PENDING)
- ⏳ **Phase 8**: Community onboarding (PENDING)

## Next Steps

1. **Testnet Deployment**
   - Deploy to Alfajores (Celo testnet)
   - Run integration tests
   - Test liquidations

2. **Audit**
   - Focus on MentoSpotOracle
   - Review wCELO integration
   - Verify permission model

3. **Mainnet Deployment**
   - Follow deployment guide above
   - Use multisig for governance
   - Monitor initial activity

4. **Ecosystem Integration**
   - List on Celo DeFi dashboards
   - Integrate with Celo wallets
   - Community education

---

**Status**: ✅ Migration Complete - Ready for Testnet Deployment
**Last Updated**: December 2024
