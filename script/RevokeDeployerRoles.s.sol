// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "forge-std/src/Script.sol";
import "forge-std/src/console2.sol";
import "../src/Cauldron.sol";
import "../src/Ladle.sol";
import "../src/Witch.sol";
import "../src/Join.sol";
import "../src/FYToken.sol";
import "../src/oracles/mento/MentoSpotOracle.sol";

/**
 * @title RevokeDeployerRoles
 * @notice Idempotent script to revoke deployer privileges and transfer governance
 * @dev Transfers ROOT and admin roles from deployer to governance address
 *
 * SECURITY:
 *   - Refuses to run if GOVERNANCE is unset or equals deployer
 *   - Only revokes roles that the deployer still has
 *   - Idempotent: safe to rerun multiple times
 *
 * USAGE:
 *   # Dry-run (simulation):
 *   GOVERNANCE=0x... forge script script/RevokeDeployerRoles.s.sol --rpc-url $CELO_RPC_URL -vv
 *
 *   # Broadcast (actual transaction):
 *   GOVERNANCE=0x... forge script script/RevokeDeployerRoles.s.sol \
 *     --rpc-url $CELO_RPC_URL \
 *     --broadcast \
 *     --slow \
 *     -vvvv
 *
 * WHAT IT DOES:
 *   1. Grants ROOT to governance on all contracts (if not already granted)
 *   2. Revokes deployer's ROOT on all contracts (if governance != deployer)
 *   3. Revokes deployer's operational roles (configuration functions)
 *   4. Prints detailed report of changes
 */
contract RevokeDeployerRoles is Script {
    // ========== CELO MAINNET DEPLOYMENT ADDRESSES ==========
    address constant CAULDRON = 0xdf9ce55F0389341221c70BbCe171bF5ab983c21F;
    address constant LADLE = 0x71dc46418a0b368618999FEd7fC1237a7720E662;
    address constant WITCH = 0xdF4Bc5bef2aAeF3D78ad0B9369f39C5ABdBe081E;
    address constant MENTO_ORACLE = 0xD89cF4B4c739a0100FC96d2Ab0167A081cc2bCEB;
    address constant CKES_JOIN = 0xA1f65d6B7FC4ABB1f7331cBBD441E478fb76E164;
    address constant USDT_JOIN = 0xCA12b75Bf6fb0A76b3B8D7Ed805071dBF6221A7d;
    address constant FYUSDT = 0x8d0c33Bf1CEbE94109dd10632dd4D03096cDDe7e;

    bytes4 constant ROOT = 0x00000000;

    function run() external {
        console2.log("============================================================");
        console2.log("Yield Protocol v2 - Revoke Deployer Roles");
        console2.log("============================================================");
        console2.log("");

        // Load environment
        address governance = vm.envAddress("GOVERNANCE");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deployer:   ", deployer);
        console2.log("Governance: ", governance);
        console2.log("");

        // Safety checks
        require(governance != address(0), "GOVERNANCE not set");
        require(governance != deployer, "GOVERNANCE cannot be deployer (use a multi-sig or separate governance address)");

        console2.log("Safety checks passed.");
        console2.log("");

        // Check if broadcast mode
        uint64 nonceBefore = vm.getNonce(deployer);

        vm.startBroadcast(deployerPrivateKey);

        // ========== STEP 1: GRANT ROOT TO GOVERNANCE ==========
        console2.log("Step 1: Granting ROOT to Governance");
        console2.log("------------------------------------------------------------");
        _grantRootToGovernance(governance);
        console2.log("");

        // ========== STEP 2: REVOKE DEPLOYER ROOT ==========
        console2.log("Step 2: Revoking Deployer ROOT");
        console2.log("------------------------------------------------------------");
        _revokeDeployerRoot(deployer);
        console2.log("");

        // ========== STEP 3: REVOKE DEPLOYER OPERATIONAL ROLES ==========
        console2.log("Step 3: Revoking Deployer Operational Roles");
        console2.log("------------------------------------------------------------");
        _revokeDeployerOperationalRoles(deployer);
        console2.log("");

        vm.stopBroadcast();

        bool didBroadcast = vm.getNonce(deployer) > nonceBefore;

        // ========== FINAL REPORT ==========
        console2.log("============================================================");
        console2.log("ROLE REVOCATION COMPLETE");
        console2.log("============================================================");

        if (!didBroadcast) {
            console2.log("MODE: DRY-RUN (simulation only, no transactions sent)");
        } else {
            console2.log("MODE: BROADCAST (transactions sent to chain)");
        }

        console2.log("");
        console2.log("Governance now has ROOT on all contracts.");
        console2.log("Deployer has been revoked from all privileged roles.");
        console2.log("");
        console2.log("Next steps:");
        console2.log("1. Verify governance has ROOT using VerifyCeloDeployment script");
        console2.log("2. Ensure governance multi-sig is properly configured");
        console2.log("3. Test governance can perform admin operations");
        console2.log("============================================================");
    }

    function _grantRootToGovernance(address governance) internal {
        Cauldron cauldron = Cauldron(CAULDRON);
        Ladle ladle = Ladle(payable(LADLE));
        Witch witch = Witch(WITCH);
        MentoSpotOracle oracle = MentoSpotOracle(MENTO_ORACLE);
        Join ckesJoin = Join(CKES_JOIN);
        Join usdtJoin = Join(USDT_JOIN);
        FYToken fyToken = FYToken(FYUSDT);

        // Grant ROOT to governance (idempotent)
        _grantRoleIfNeeded(cauldron, ROOT, governance, "Cauldron");
        _grantRoleIfNeeded(ladle, ROOT, governance, "Ladle");
        _grantRoleIfNeeded(witch, ROOT, governance, "Witch");
        _grantRoleIfNeeded(oracle, ROOT, governance, "MentoOracle");
        _grantRoleIfNeeded(ckesJoin, ROOT, governance, "cKES Join");
        _grantRoleIfNeeded(usdtJoin, ROOT, governance, "USDT Join");
        _grantRoleIfNeeded(fyToken, ROOT, governance, "fyUSDT");
    }

    function _revokeDeployerRoot(address deployer) internal {
        Cauldron cauldron = Cauldron(CAULDRON);
        Ladle ladle = Ladle(payable(LADLE));
        Witch witch = Witch(WITCH);
        MentoSpotOracle oracle = MentoSpotOracle(MENTO_ORACLE);
        Join ckesJoin = Join(CKES_JOIN);
        Join usdtJoin = Join(USDT_JOIN);
        FYToken fyToken = FYToken(FYUSDT);

        // Revoke ROOT from deployer (idempotent)
        _revokeRoleIfNeeded(cauldron, ROOT, deployer, "Cauldron");
        _revokeRoleIfNeeded(ladle, ROOT, deployer, "Ladle");
        _revokeRoleIfNeeded(witch, ROOT, deployer, "Witch");
        _revokeRoleIfNeeded(oracle, ROOT, deployer, "MentoOracle");
        _revokeRoleIfNeeded(ckesJoin, ROOT, deployer, "cKES Join");
        _revokeRoleIfNeeded(usdtJoin, ROOT, deployer, "USDT Join");
        _revokeRoleIfNeeded(fyToken, ROOT, deployer, "fyUSDT");
    }

    function _revokeDeployerOperationalRoles(address deployer) internal {
        Cauldron cauldron = Cauldron(CAULDRON);
        Ladle ladle = Ladle(payable(LADLE));
        Witch witch = Witch(WITCH);
        MentoSpotOracle oracle = MentoSpotOracle(MENTO_ORACLE);

        // Revoke Cauldron operational roles
        _revokeRoleIfNeeded(cauldron, Cauldron.addAsset.selector, deployer, "Cauldron::addAsset");
        _revokeRoleIfNeeded(cauldron, Cauldron.setLendingOracle.selector, deployer, "Cauldron::setLendingOracle");
        _revokeRoleIfNeeded(cauldron, Cauldron.addSeries.selector, deployer, "Cauldron::addSeries");
        _revokeRoleIfNeeded(cauldron, Cauldron.addIlks.selector, deployer, "Cauldron::addIlks");
        _revokeRoleIfNeeded(cauldron, Cauldron.setSpotOracle.selector, deployer, "Cauldron::setSpotOracle");
        _revokeRoleIfNeeded(cauldron, Cauldron.setDebtLimits.selector, deployer, "Cauldron::setDebtLimits");

        // Revoke Ladle operational roles
        _revokeRoleIfNeeded(ladle, Ladle.addJoin.selector, deployer, "Ladle::addJoin");

        // Revoke Witch operational roles
        _revokeRoleIfNeeded(witch, witch.setLineAndLimit.selector, deployer, "Witch::setLineAndLimit");

        // Revoke Oracle operational roles
        _revokeRoleIfNeeded(oracle, oracle.setSource.selector, deployer, "MentoOracle::setSource");
        _revokeRoleIfNeeded(oracle, oracle.setMaxAge.selector, deployer, "MentoOracle::setMaxAge");
        _revokeRoleIfNeeded(oracle, oracle.setBounds.selector, deployer, "MentoOracle::setBounds");
    }

    function _grantRoleIfNeeded(
        AccessControl target,
        bytes4 role,
        address account,
        string memory contractName
    ) internal {
        if (!target.hasRole(role, account)) {
            target.grantRole(role, account);
            console2.log("  [GRANTED] ", contractName, "ROOT to governance");
        } else {
            console2.log("  [SKIPPED] ", contractName, "ROOT already granted");
        }
    }

    function _revokeRoleIfNeeded(
        AccessControl target,
        bytes4 role,
        address account,
        string memory roleName
    ) internal {
        if (target.hasRole(role, account)) {
            target.revokeRole(role, account);
            console2.log("  [REVOKED] ", roleName);
        } else {
            console2.log("  [SKIPPED] ", roleName, "already revoked");
        }
    }
}
