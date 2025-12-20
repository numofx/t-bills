# Celo Quick Start Guide

Get started with Yield Protocol on Celo in 5 minutes.

## Prerequisites

1. **Foundry installed**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Celo wallet with CELO for gas**
   - Minimum: 0.1 CELO for testing
   - Recommended: 1 CELO for deployment

3. **Environment variables**
   ```bash
   export PRIVATE_KEY="0x..."
   export GOVERNANCE="0x..."  # Your governance address
   export CELO="https://celo-mainnet.g.alchemy.com/v2/YOUR_API_KEY"
   ```

## Option 1: Full Deployment (Recommended)

Deploy everything in one transaction:

```bash
# Clone and install
git clone <repo>
cd manager

# Set up environment
cp .env.example .env
# Edit .env with your values

# Load environment
source .env

# Deploy all contracts
forge script script/DeployAll.s.sol \
  --rpc-url $CELO \
  --broadcast \
  --verify \
  -vvvv
```

**What gets deployed:**
- ✅ Cauldron (vault system)
- ✅ Ladle (router with wCELO)
- ✅ MentoSpotOracle (price feeds)
- ✅ cKES Join (collateral adapter)
- ✅ All permissions configured
- ✅ Governance roles transferred

**Deployment time:** ~2-3 minutes

## Option 2: Step-by-Step Deployment

For more control, deploy contracts individually:

### 1. Deploy Cauldron
```bash
forge script script/DeployCauldron.s.sol \
  --rpc-url $CELO \
  --broadcast \
  --verify
```

Copy the Cauldron address and export it:
```bash
export CAULDRON="0x..."
```

### 2. Deploy Ladle
```bash
forge script script/DeployLadle.s.sol \
  --rpc-url $CELO \
  --broadcast \
  --verify
```

### 3. Deploy MentoOracle
```bash
forge script script/DeployMentoOracle.s.sol \
  --rpc-url $CELO \
  --broadcast \
  --verify
```

### 4. Deploy and Configure cKES Join
```bash
# Deploy
forge script script/DeployCkesJoin.s.sol \
  --rpc-url $CELO \
  --broadcast

# Grant permissions
export LADLE="0x..."  # From step 2
forge script script/GrantCkesJoinPermissions.s.sol \
  --rpc-url $CELO \
  --broadcast

# Finalize
forge script script/FinalizeCkesJoin.s.sol \
  --rpc-url $CELO \
  --broadcast
```

## Testing

### Run All Tests
```bash
source .env
./bin/test
```

### Run Only Celo Tests
```bash
./bin/test \
  --match-path "src/test/oracles/MentoSpotOracle.t.sol" \
  --match-path "src/test/oracles/VariableIR*.sol" \
  -vvv
```

### Test Specific Function
```bash
./bin/test \
  --match-contract MentoSpotOracleTest \
  --match-test testGetConversion \
  -vvvv
```

## Verify Deployment

After deployment, verify everything works:

```bash
# Test oracle
forge script script/TestMentoOracle.s.sol \
  --rpc-url $CELO \
  -vvv

# Check contracts on Celoscan
open "https://explorer.celo.org/mainnet/address/YOUR_CAULDRON_ADDRESS"
```

## Common Operations

### Create a Vault
```solidity
// Using Ladle
bytes12 vaultId = ladle.build(seriesId, ilkId, salt);
```

### Add Collateral
```solidity
// Approve cKES to Join
IERC20(cKES).approve(address(ckesJoin), amount);

// Pour collateral via Ladle
ladle.pour(vaultId, address(this), int128(amount), 0);
```

### Borrow
```solidity
// Pour to borrow (negative art = borrow)
ladle.pour(vaultId, address(this), 0, -int128(borrowAmount));
```

### Check Vault Health
```solidity
DataTypes.Vault memory vault = cauldron.vaults(vaultId);
int256 level = cauldron.level(vaultId);
// level > 0 means healthy, < 0 means undercollateralized
```

## Troubleshooting

### "environment variable 'CELO' not found"
```bash
source .env  # Load environment variables
```

### "Tests timeout after 120s"
```bash
# Always use dev profile for fast compilation
./bin/test
```

### "block is out of range"
Your RPC endpoint doesn't have archive access. Use Alchemy Growth plan or higher.

### "Price out of bounds"
The Mento oracle has safety bounds. Check current cKES/USD price on Mento:
```bash
forge script script/TestMentoOracle.s.sol --rpc-url $CELO
```

## Network Information

### Celo Mainnet
- **Chain ID**: 42220
- **RPC**: https://forno.celo.org (public) or Alchemy (recommended)
- **Explorer**: https://explorer.celo.org/mainnet
- **Currency**: CELO

### Key Contracts (Celo Mainnet)
- **wCELO**: 0x471EcE3750Da237f93B8E339c536989b8978a438
- **SortedOracles**: 0xefB84935239dAcdecF7c5bA76d8dE40b077B7b33
- **cKES**: 0x456a3D042C0DbD3db53D5489e98dFb038553B0d0
- **cUSD**: 0x765DE816845861e75A25fCA122bb6898B8B1282a

## Next Steps

1. **Test on Alfajores** (Celo testnet)
   ```bash
   export CELO="https://alfajores-forno.celo-testnet.org"
   # Deploy using same scripts
   ```

2. **Monitor Deployment**
   - Set up oracle price monitoring
   - Monitor vault health
   - Track liquidations

3. **Add More Assets**
   - Deploy additional Joins (cUSD, cEUR, etc.)
   - Configure oracle pairs
   - Set debt limits

4. **Integrate with Frontend**
   - Use ethers.js or viem
   - Connect to Celo network
   - Build vault management UI

## Resources

- **Full Documentation**: [CELO_MIGRATION.md](./CELO_MIGRATION.md)
- **Test Documentation**: [src/test/README.md](./src/test/README.md)
- **Yield V2 Docs**: [Google Doc](https://docs.google.com/document/d/1WBrJx_5wxK1a4N_9b6IQV70d2TyyyFxpiTfjA6PuZaQ/edit)
- **Mento Docs**: https://docs.mento.org/
- **Celo Docs**: https://docs.celo.org/

## Support

- **Issues**: Open a GitHub issue
- **Security**: security@yield.is
- **Community**: Join Yield Protocol Discord

---

**Status**: ✅ Ready for deployment
**Last Updated**: December 2024
