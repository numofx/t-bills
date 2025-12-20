# Deploying Yield Protocol v2 Minimal System on Celo

This guide covers deploying the full minimal working Yield v2 system on Celo mainnet using `DeployMinimalCeloSystem.s.sol`.

## What Gets Deployed

This script deploys a **complete, production-ready Yield v2 system** with:

### Core Contracts
- **Cauldron** - Vault accounting and debt management
- **Ladle** - User-facing router for all vault operations
- **Witch** - Liquidation engine with Dutch auction mechanism

### Oracle Infrastructure
- **MentoSpotOracle** - Integration with Mento Protocol price feeds
  - Configured for cKES/USD price pair
  - Safety bounds and staleness checks

### Asset Adapters (Joins)
- **cKES Join** - Collateral adapter for cKES
- **USDT Join** - Base asset adapter for USDT

### Fixed-Yield Token
- **fyUSDT** - Fixed-yield USDT token for one series
  - Maturity date configurable via env var
  - Redeemable 1:1 with USDT after maturity

### Configuration
- Collateral: **cKES** (Kenyan Shilling stablecoin)
- Base Asset: **USDT** (debt denomination)
- Collateralization Ratio: **150%**
- Max Debt: **1M USDT**
- Liquidation auctions: 1 hour duration

## Prerequisites

### 1. Environment Setup

You need Foundry installed:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Celo Wallet

- Must have CELO for gas (recommended: 1-2 CELO)
- Private key exported to environment
- **Warning**: Never commit private keys to git

### 3. Token Addresses

You need the addresses for:
- **cKES** - Kenyan Shilling stablecoin on Celo
- **USDT** - Tether on Celo (or equivalent USD stablecoin)

Default Celo mainnet addresses (verify these are current):
- cKES: `0x456a3D042C0DbD3db53D5489e98dFb038553B0d0`
- cUSD: `0x765DE816845861e75A25fCA122bb6898B8B1282a` (used as USD proxy in oracle)

### 4. RPC Endpoint

You need a Celo mainnet RPC endpoint:
- **Recommended**: Alchemy, Infura, or QuickNode (archive access)
- **Public**: https://forno.celo.org (may be rate-limited)

## Environment Variables

Create a `.env` file with the following:

### Required Variables

```bash
# Deployer
PRIVATE_KEY="0x..."  # Your deployer private key (NEVER COMMIT THIS)

# Governance
GOVERNANCE="0x..."   # Address that will receive ROOT roles

# Assets
CKES="0x456a3D042C0DbD3db53D5489e98dFb038553B0d0"  # cKES token address
USDT="0x..."         # USDT token address on Celo

# RPC
CELO_RPC_URL="https://celo-mainnet.g.alchemy.com/v2/YOUR_API_KEY"
```

### Optional Variables (with defaults)

```bash
# Celo infrastructure (defaults provided)
WCELO="0x471EcE3750Da237f93B8E339c536989b8978a438"
SORTED_ORACLES="0xefB84935239dAcdecF7c5bA76d8dE40b077B7b33"
KES_USD_RATE_FEED="0xbAcEE37d31b9f022Ef5d232B9fD53F05a531c169"
CUSD="0x765DE816845861e75A25fCA122bb6898B8B1282a"

# Series configuration
MATURITY="1735689600"  # Unix timestamp (default: 1 year from deployment)

# Permissions
REVOKE_DEPLOYER="true"  # Set to "false" to keep deployer ROOT access
```

## Deployment Steps

### Step 1: Prepare Environment

```bash
# Clone repository
git clone <repo>
cd manager

# Install dependencies
yarn install  # If using TypeScript scripts

# Create .env file
cp .env.example .env
# Edit .env with your values
```

### Step 2: Verify Configuration

**IMPORTANT**: Before deploying to mainnet, verify all addresses and parameters!

```bash
# Source environment
source .env

# Dry-run (no broadcast)
forge script script/DeployMinimalCeloSystem.s.sol \
  --rpc-url $CELO_RPC_URL \
  -vvvv
```

Review the output carefully:
- ✅ Check all addresses are correct
- ✅ Verify you're on Celo mainnet (chainId 42220)
- ✅ Confirm deployer balance is sufficient
- ✅ Review maturity date
- ✅ Check collateralization ratio

### Step 3: Deploy (Testnet First!)

**Always test on Alfajores (Celo testnet) first:**

```bash
# Alfajores deployment
export CELO_RPC_URL="https://alfajores-forno.celo-testnet.org"

forge script script/DeployMinimalCeloSystem.s.sol \
  --rpc-url $CELO_RPC_URL \
  --broadcast \
  -vvvv
```

### Step 4: Deploy to Mainnet

Once testnet deployment is successful:

```bash
# Load mainnet RPC
source .env

# Deploy and verify
forge script script/DeployMinimalCeloSystem.s.sol \
  --rpc-url $CELO_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

**Deployment takes ~2-3 minutes** and includes:
1. Deploying all contracts
2. Configuring permissions
3. Setting up oracle sources
4. Transferring governance
5. Running post-deployment validations

## Post-Deployment

### Verify Contracts on Celoscan

After deployment, the script outputs all contract addresses. Verify them on Celoscan:

```bash
# Example
open "https://explorer.celo.org/mainnet/address/CAULDRON_ADDRESS"
```

Look for:
- ✅ Green checkmark (verified source code)
- ✅ Contract creation transaction
- ✅ Read/Write functions available

### Test Basic Operations

Test with small amounts first:

```solidity
// 1. Create a vault
bytes12 vaultId = ladle.build(seriesId, CKES_ID, 0);

// 2. Approve cKES to Join
IERC20(cKES).approve(address(ckesJoin), 100e18);

// 3. Add 100 cKES collateral
ladle.pour(vaultId, address(this), 100e18, 0);

// 4. Borrow 50 USDT (assuming 150% collateralization)
ladle.pour(vaultId, address(this), 0, -50e18);

// 5. Check vault health
int256 level = cauldron.level(vaultId);
require(level >= 0, "Vault undercollateralized");
```

### Monitor Oracle Health

Set up monitoring for the Mento oracle:

```bash
# Check current cKES price
forge script script/TestMentoOracle.s.sol \
  --rpc-url $CELO_RPC_URL \
  -vvv
```

Expected output:
- Price within bounds (0.003 - 0.015 USD)
- Recent update time (< 10 minutes)
- No revert errors

### Set Up Liquidation Monitoring

Monitor undercollateralized vaults:

```solidity
// Get all vaults for a series
// (You'll need to track vaultIds off-chain or use events)

// Check if any vault is liquidatable
int256 level = cauldron.level(vaultId);
if (level < 0) {
    // Vault is undercollateralized
    // Can be auctioned via Witch
    witch.auction(vaultId, address(this));
}
```

## Common Operations

### Create a New Series

To add another fyUSDT series with different maturity:

```solidity
// 1. Deploy new FYToken
uint256 newMaturity = block.timestamp + 180 days;  // 6 months
bytes6 newSeriesId = bytes6(bytes12(USDT_ID) | bytes12(uint96(newMaturity)));

FYToken fyUSDT2 = new FYToken(
    USDT_ID,
    oracle,
    usdtJoin,
    newMaturity,
    "fyUSDT 6mo",
    "fyUSDT6mo"
);

// 2. Add series to Cauldron
cauldron.addSeries(newSeriesId, USDT_ID, IJoin(address(fyUSDT2)));

// 3. Add ilks (collateral types)
bytes6[] memory ilks = new bytes6[](1);
ilks[0] = CKES_ID;
cauldron.addIlks(newSeriesId, ilks);

// 4. Add to Ladle
ladle.addPool(newSeriesId, IPool(address(fyUSDT2)));

// 5. Grant permissions
fyUSDT2.grantRole(fyUSDT2.mint.selector, address(ladle));
fyUSDT2.grantRole(fyUSDT2.burn.selector, address(ladle));
```

### Add Another Collateral Type

To support cEUR as collateral:

```bash
# 1. Deploy cEUR Join
export CEUR="0x..."
forge script script/DeployCeurJoin.s.sol --broadcast

# 2. Configure oracle for cEUR/USD
# (via governance or deployer if not revoked)

# 3. Set collateralization ratio
cauldron.setSpotOracle(USDT_ID, CEUR_ID, oracle, 1500000);

# 4. Set debt limits
cauldron.setDebtLimits(USDT_ID, CEUR_ID, maxDebt, minDebt, dec);
```

### Update Oracle Safety Parameters

```solidity
// Update staleness threshold
mentoOracle.setMaxAge(CKES_ID, USDT_ID, 900);  // 15 minutes

// Update price bounds
mentoOracle.setBounds(CKES_ID, USDT_ID, 0.002e18, 0.020e18);
```

**Note**: These operations require governance or deployer (if not revoked).

## Deployment Validation Checklist

After deployment, verify:

- [ ] All contracts deployed successfully
- [ ] All contracts verified on Celoscan
- [ ] Governance has ROOT on all contracts
- [ ] Deployer ROOT revoked (if REVOKE_DEPLOYER=true)
- [ ] Oracle returns valid prices
- [ ] Oracle price within safety bounds
- [ ] Cauldron assets added (cKES, USDT)
- [ ] Cauldron series added (fyUSDT)
- [ ] Joins configured correctly
- [ ] Ladle has Cauldron permissions
- [ ] Witch has liquidation permissions
- [ ] fyUSDT has correct maturity
- [ ] Test vault creation works
- [ ] Test collateral deposit works
- [ ] Test borrowing works
- [ ] Liquidation parameters set

## Troubleshooting

### "Must deploy on Celo mainnet (chainId 42220)"

**Problem**: Deploying to wrong network

**Solution**: Verify CELO_RPC_URL points to Celo mainnet:
```bash
echo $CELO_RPC_URL
# Should be Celo mainnet, not Ethereum or testnet
```

### "GOVERNANCE not set"

**Problem**: Missing required environment variable

**Solution**:
```bash
source .env  # Reload environment
echo $GOVERNANCE  # Verify it's set
```

### "CKES is not a contract"

**Problem**: Invalid token address or wrong network

**Solution**: Verify the token exists on Celo:
```bash
cast code $CKES --rpc-url $CELO_RPC_URL
# Should return bytecode, not "0x"
```

### "Oracle: price out of bounds"

**Problem**: Mento oracle price outside safety bounds

**Solution**: Check current price and adjust bounds if needed:
```bash
forge script script/TestMentoOracle.s.sol --rpc-url $CELO_RPC_URL
# Review current price
# Adjust MIN_PRICE and MAX_PRICE in script if legitimate price movement
```

### "Insufficient balance for gas"

**Problem**: Deployer doesn't have enough CELO

**Solution**: Transfer CELO to deployer address:
```bash
# Check balance
cast balance $DEPLOYER_ADDRESS --rpc-url $CELO_RPC_URL

# Need at least 0.1 CELO, recommended 1-2 CELO
```

### Deployment script timeout

**Problem**: RPC endpoint is slow or rate-limited

**Solution**:
1. Use a paid RPC endpoint (Alchemy, Infura Growth)
2. Increase timeout:
```bash
export FOUNDRY_ETH_RPC_TIMEOUT=300  # 5 minutes
```

## Security Considerations

### Before Mainnet Deployment

1. **Audit**: Have the system audited by professionals
2. **Test Coverage**: Ensure 100% test coverage (currently 465/465 tests passing)
3. **Testnet**: Deploy to Alfajores and test for at least 1 week
4. **Multisig**: Use a multisig for GOVERNANCE address
5. **Timelock**: Consider a timelock for governance actions

### During Deployment

1. **Verify Addresses**: Double-check all token and infrastructure addresses
2. **Test Transactions**: Use --broadcast only after successful dry-run
3. **Monitor**: Watch the deployment transaction closely
4. **Save Addresses**: Record all deployed contract addresses securely

### After Deployment

1. **Verify Source**: Verify all contracts on Celoscan
2. **Revoke Deployer**: Ensure deployer ROOT is revoked (if REVOKE_DEPLOYER=true)
3. **Test Small**: Test with small amounts before going live
4. **Monitor Oracle**: Set up 24/7 oracle price monitoring
5. **Monitor Vaults**: Track vault health and liquidation triggers
6. **Bug Bounty**: Consider a bug bounty program

## Pre-Deployment Validation

Before deploying to mainnet, validate the script thoroughly:

### 1. Dry-Run Simulation (No Broadcast)

```bash
source .env
forge script script/DeployMinimalCeloSystem.s.sol \
  --rpc-url $CELO_RPC_URL \
  -vvvv
```

This simulates the deployment without broadcasting transactions. Check that:
- All addresses resolve correctly
- Chain ID is 42220 (Celo mainnet)
- Oracle returns valid prices
- No revert errors

### 2. Mainnet Fork Simulation

```bash
forge script script/DeployMinimalCeloSystem.s.sol \
  --fork-url $CELO_RPC_URL \
  -vvvv
```

This runs the script against a fork of mainnet state, validating:
- Token contracts exist (CKES, USDT, wCELO)
- Oracle infrastructure is accessible (SortedOracles)
- Gas estimates are reasonable

### 3. Testnet Deployment (Alfajores)

If you have testnet addresses for CKES/USDT:

```bash
export CELO_RPC_URL="https://alfajores-forno.celo-testnet.org"
forge script script/DeployMinimalCeloSystem.s.sol \
  --rpc-url $CELO_RPC_URL \
  --broadcast \
  -vvvv
```

Test the full deployment flow on testnet before mainnet.

### 4. Run Test Suite

Ensure all tests pass before deployment:

```bash
source .env
./bin/test
```

Required environment variables:
- `ETH` - Ethereum mainnet RPC (for Ethereum fork tests)
- `CELO` - Celo mainnet RPC (for Celo fork tests, optional)

**Recommendation**: Have 1-2 CELO in deployer wallet for gas. Actual costs vary with network conditions.

## Network Information

### Celo Mainnet
- **Chain ID**: 42220
- **Currency**: CELO
- **Block Time**: ~5 seconds
- **Finality**: ~5-10 seconds
- **RPC**: https://forno.celo.org (public)
- **Explorer**: https://explorer.celo.org/mainnet

### Celo Alfajores (Testnet)
- **Chain ID**: 44787
- **Currency**: CELO (testnet)
- **Faucet**: https://faucet.celo.org
- **RPC**: https://alfajores-forno.celo-testnet.org
- **Explorer**: https://explorer.celo.org/alfajores

## Architecture Overview

```
┌─────────────┐
│   Users     │
└──────┬──────┘
       │
       ▼
┌─────────────┐      ┌──────────────┐
│    Ladle    │◄─────┤  fyUSDT      │
│  (Router)   │      │  (Series)    │
└──────┬──────┘      └──────────────┘
       │
       │ build(), pour(), etc.
       ▼
┌─────────────┐      ┌──────────────┐
│  Cauldron   │◄─────┤ MentoOracle  │
│  (Vaults)   │      │ (Prices)     │
└──────┬──────┘      └──────────────┘
       │
       │ liquidation
       ▼
┌─────────────┐      ┌──────────────┐
│    Witch    │      │    Joins     │
│ (Auctions)  │      │ (cKES, USDT) │
└─────────────┘      └──────────────┘
```

### User Flow: Borrow USDT with cKES

1. **User** approves cKES to cKES Join
2. **User** calls `Ladle.build()` to create vault
3. **User** calls `Ladle.pour()` to deposit cKES collateral
4. **Ladle** transfers cKES to cKES Join
5. **Ladle** calls `Cauldron.pour()` to update accounting
6. **User** calls `Ladle.pour()` again to borrow USDT
7. **Cauldron** checks collateralization via MentoOracle
8. **Ladle** mints fyUSDT to user
9. **User** can sell fyUSDT for USDT (if YieldSpace pools exist)
10. At maturity, **fyUSDT** redeems 1:1 for USDT

### Liquidation Flow

1. **Cauldron** vault becomes undercollateralized (price drops or debt grows)
2. **Anyone** calls `Witch.auction(vaultId)`
3. **Witch** runs Dutch auction (price decreases over time)
4. **Buyer** calls `Witch.buy()` to purchase collateral at auction price
5. **Witch** transfers collateral to buyer, debt repaid to Cauldron
6. **Original borrower** loses collateral, vault closed

## Resources

- **Yield v2 Documentation**: [Google Doc](https://docs.google.com/document/d/1WBrJx_5wxK1a4N_9b6IQV70d2TyyyFxpiTfjA6PuZaQ/edit)
- **Mento Protocol**: https://docs.mento.org/
- **Celo Documentation**: https://docs.celo.org/
- **Migration Guide**: [CELO_MIGRATION.md](../CELO_MIGRATION.md)
- **Test Documentation**: [src/test/README.md](../src/test/README.md)

## Support

- **GitHub Issues**: Report bugs or request features
- **Security**: security@yield.is (for security vulnerabilities)
- **Community**: Yield Protocol Discord

---

**Status**: ✅ Production-ready
**Last Updated**: December 2024
**Version**: 1.0.0
