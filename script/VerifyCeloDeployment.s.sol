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
import "../src/interfaces/IRouter.sol";

/**
 * @title VerifyCeloDeployment
 * @notice Verification script for Yield Protocol v2 deployment on Celo mainnet
 * @dev Validates contract wiring, permissions, oracle configuration, and live pricing
 *
 * USAGE:
 *   forge script script/VerifyCeloDeployment.s.sol --rpc-url $CELO_RPC_URL -vv
 *
 * This script performs comprehensive validation:
 *   1. Contract existence checks
 *   2. Wiring validation (Ladle ↔ Cauldron, Witch ↔ Cauldron)
 *   3. Oracle configuration (source, maxAge, bounds)
 *   4. Live price validation
 *   5. Series and ilk registration
 *   6. Permission checks
 */
contract VerifyCeloDeployment is Script {
    // ========== CELO MAINNET DEPLOYMENT ADDRESSES ==========
    // Note: checksum vs lowercase in addresses does not matter on-chain; case is ignored.
    address constant CAULDRON = 0xdf9ce55F0389341221c70BbCe171bF5ab983c21F;
    address constant LADLE = 0x71dc46418a0b368618999FEd7fC1237a7720E662;
    address constant WITCH = 0xdF4Bc5bef2aAeF3D78ad0B9369f39C5ABdBe081E;
    address constant MENTO_ORACLE = 0xD89cF4B4c739a0100FC96d2Ab0167A081cc2bCEB;
    address constant CKES_JOIN = 0xA1f65d6B7FC4ABB1f7331cBBD441E478fb76E164;
    address constant USDT_JOIN = 0xCA12b75Bf6fb0A76b3B8D7Ed805071dBF6221A7d;
    address constant FYUSDT = 0x8d0c33Bf1CEbE94109dd10632dd4D03096cDDe7e;
    address constant ROUTER = 0x2bAC470895F7853E2030F801a36c38D267953602;

    // Asset IDs
    bytes6 constant CKES_ID = 0x634b45530000; // "cKES"
    bytes6 constant USDT_ID = 0x555344540000; // "USDT"

    // Oracle expected values
    address constant EXPECTED_RATE_FEED = 0xbAcEE37d31b9f022Ef5d232B9fD53F05a531c169;
    uint256 constant EXPECTED_MAX_AGE = 600;
    uint256 constant EXPECTED_MIN_PRICE = 3000000000000000; // 0.003e18
    uint256 constant EXPECTED_MAX_PRICE = 15000000000000000; // 0.015e18

    uint256 public checksPassed;
    uint256 public checksFailed;

    struct OracleConfig {
        address rateFeedID;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        bool inverse;
        uint256 maxAge;
        uint256 minPrice;
        uint256 maxPrice;
    }

    function run() external view {
        console2.log("============================================================");
        console2.log("Yield Protocol v2 - Celo Mainnet Deployment Verification");
        console2.log("============================================================");
        console2.log("");

        // Initialize counters (immutable in view context, so we'll use local vars)
        uint256 passed = 0;
        uint256 failed = 0;
        bool fatal = false;
        bool missingCode = false;

        console2.log("RPC sanity check");
        console2.log("  Chain ID:", block.chainid);
        console2.log("  Block number:", block.number);
        if (block.chainid != 42220) {
            console2.log("  [FAIL] Wrong chain id (expected 42220)");
            fatal = true;
        }
        console2.log("");

        // ========== STEP 1: CONTRACT EXISTENCE ==========
        console2.log("Step 1: Verifying Contract Deployments");
        console2.log("------------------------------------------------------------");
        (passed, failed, missingCode) = _verifyContractExistence(passed, failed, missingCode);
        console2.log("");

        // ========== STEP 2: WIRING VALIDATION ==========
        console2.log("Step 2: Verifying Contract Wiring");
        console2.log("------------------------------------------------------------");
        (passed, failed, missingCode) = _verifyWiring(passed, failed, missingCode);
        console2.log("");

        // ========== STEP 3: ORACLE CONFIGURATION ==========
        console2.log("Step 3: Verifying Oracle Configuration");
        console2.log("------------------------------------------------------------");
        (passed, failed, missingCode) = _verifyOracleConfig(passed, failed, missingCode);
        console2.log("");

        // ========== STEP 4: LIVE PRICE VALIDATION ==========
        console2.log("Step 4: Verifying Live Oracle Price");
        console2.log("------------------------------------------------------------");
        (passed, failed, missingCode) = _verifyLivePrice(passed, failed, missingCode);
        console2.log("");

        // ========== STEP 5: SERIES AND ILKS ==========
        console2.log("Step 5: Verifying Series and Ilks");
        console2.log("------------------------------------------------------------");
        (passed, failed, missingCode) = _verifySeriesAndIlks(passed, failed, missingCode);
        console2.log("");

        // ========== STEP 6: PERMISSIONS ==========
        console2.log("Step 6: Verifying Permissions");
        console2.log("------------------------------------------------------------");
        (passed, failed, missingCode) = _verifyPermissions(passed, failed, missingCode);
        console2.log("");

        // ========== FINAL REPORT ==========
        console2.log("============================================================");
        console2.log("VERIFICATION REPORT");
        console2.log("============================================================");
        console2.log("Checks Passed:", passed);
        console2.log("Checks Failed:", failed);
        console2.log("");

        if (failed == 0) {
            console2.log("STATUS: PASS - All checks passed!");
        } else {
            console2.log("STATUS: FAIL - Some checks failed. Review output above.");
        }
        console2.log("============================================================");
        if (failed > 0 || fatal || missingCode) {
            revert("Verification failed: missing code, wrong chain, or wiring mismatch");
        }
    }

    function _verifyContractExistence(
        uint256 passed,
        uint256 failed,
        bool missingCode
    ) internal view returns (uint256, uint256, bool) {
        (passed, failed, missingCode) = _checkCode("Cauldron", CAULDRON, passed, failed, missingCode);
        (passed, failed, missingCode) = _checkCode("Ladle", LADLE, passed, failed, missingCode);
        (passed, failed, missingCode) = _checkCode("Witch", WITCH, passed, failed, missingCode);
        (passed, failed, missingCode) = _checkCode("MentoOracle", MENTO_ORACLE, passed, failed, missingCode);
        (passed, failed, missingCode) = _checkCode("cKES Join", CKES_JOIN, passed, failed, missingCode);
        (passed, failed, missingCode) = _checkCode("USDT Join", USDT_JOIN, passed, failed, missingCode);
        (passed, failed, missingCode) = _checkCode("fyUSDT", FYUSDT, passed, failed, missingCode);
        (passed, failed, missingCode) = _checkCode("Router", ROUTER, passed, failed, missingCode);
        return (passed, failed, missingCode);
    }

    function _verifyWiring(
        uint256 passed,
        uint256 failed,
        bool missingCode
    ) internal view returns (uint256, uint256, bool) {
        Ladle ladle = Ladle(payable(LADLE));
        Witch witch = Witch(WITCH);

        // Ladle -> Cauldron reference
        if (_hasCode(LADLE)) {
            (passed, failed) = _check(
                "Ladle -> Cauldron reference",
                address(ladle.cauldron()) == CAULDRON,
                passed,
                failed
            );
        } else {
            console2.log("  [FAIL] Ladle has no code (wrong address or wrong chain/RPC)");
            failed++;
            missingCode = true;
        }

        // Witch -> Cauldron reference
        if (_hasCode(WITCH)) {
            (passed, failed) = _check(
                "Witch -> Cauldron reference",
                address(witch.cauldron()) == CAULDRON,
                passed,
                failed
            );
        } else {
            console2.log("  [FAIL] Witch has no code (wrong address or wrong chain/RPC)");
            failed++;
            missingCode = true;
        }

        // Witch -> Ladle reference
        if (_hasCode(WITCH)) {
            (passed, failed) = _check(
                "Witch -> Ladle reference",
                address(witch.ladle()) == LADLE,
                passed,
                failed
            );
        }

        // Ladle -> Router
        if (_hasCode(LADLE)) {
            (passed, failed) = _check(
                "Ladle -> Router reference",
                address(ladle.router()) == ROUTER,
                passed,
                failed
            );
        }

        // Joins registered in Ladle
        if (_hasCode(LADLE)) {
            (passed, failed) = _check(
                "cKES Join registered in Ladle",
                address(ladle.joins(CKES_ID)) == CKES_JOIN,
                passed,
                failed
            );

            (passed, failed) = _check(
                "USDT Join registered in Ladle",
                address(ladle.joins(USDT_ID)) == USDT_JOIN,
                passed,
                failed
            );
        }

        return (passed, failed, missingCode);
    }

    function _verifyOracleConfig(
        uint256 passed,
        uint256 failed,
        bool missingCode
    ) internal view returns (uint256, uint256, bool) {
        MentoSpotOracle oracle = MentoSpotOracle(MENTO_ORACLE);
        if (!_hasCode(MENTO_ORACLE)) {
            console2.log("  [FAIL] MentoOracle has no code (wrong address or wrong chain/RPC)");
            failed++;
            missingCode = true;
            return (passed, failed, missingCode);
        }

        // Read source configuration
        OracleConfig memory cfg;
        (
            cfg.rateFeedID,
            cfg.baseDecimals,
            cfg.quoteDecimals,
            cfg.inverse,
            cfg.maxAge,
            cfg.minPrice,
            cfg.maxPrice
        ) = oracle.sources(CKES_ID, USDT_ID);

        // Verify rate feed ID
        (passed, failed) = _check(
            "Oracle rate feed ID correct",
            cfg.rateFeedID == EXPECTED_RATE_FEED,
            passed,
            failed
        );

        if (cfg.rateFeedID != EXPECTED_RATE_FEED) {
            console2.log("  Expected:", EXPECTED_RATE_FEED);
            console2.log("  Got:     ", cfg.rateFeedID);
        }

        // Verify maxAge
        (passed, failed) = _check(
            "Oracle maxAge correct",
            cfg.maxAge == EXPECTED_MAX_AGE,
            passed,
            failed
        );

        if (cfg.maxAge != EXPECTED_MAX_AGE) {
            console2.log("  Expected:", EXPECTED_MAX_AGE);
            console2.log("  Got:     ", cfg.maxAge);
        }

        // Verify bounds
        (passed, failed) = _check(
            "Oracle min price correct",
            cfg.minPrice == EXPECTED_MIN_PRICE,
            passed,
            failed
        );

        if (cfg.minPrice != EXPECTED_MIN_PRICE) {
            console2.log("  Expected:", EXPECTED_MIN_PRICE);
            console2.log("  Got:     ", cfg.minPrice);
        }

        (passed, failed) = _check(
            "Oracle max price correct",
            cfg.maxPrice == EXPECTED_MAX_PRICE,
            passed,
            failed
        );

        if (cfg.maxPrice != EXPECTED_MAX_PRICE) {
            console2.log("  Expected:", EXPECTED_MAX_PRICE);
            console2.log("  Got:     ", cfg.maxPrice);
        }

        // Verify decimals and inverse flag
        (passed, failed) = _check("Oracle base decimals = 18", cfg.baseDecimals == 18, passed, failed);
        (passed, failed) = _check("Oracle quote decimals = 18", cfg.quoteDecimals == 18, passed, failed);
        (passed, failed) = _check("Oracle inverse = false", !cfg.inverse, passed, failed);

        return (passed, failed, missingCode);
    }

    function _verifyLivePrice(
        uint256 passed,
        uint256 failed,
        bool missingCode
    ) internal view returns (uint256, uint256, bool) {
        MentoSpotOracle oracle = MentoSpotOracle(MENTO_ORACLE);
        if (!_hasCode(MENTO_ORACLE)) {
            console2.log("  [FAIL] MentoOracle has no code (wrong address or wrong chain/RPC)");
            failed++;
            missingCode = true;
            return (passed, failed, missingCode);
        }

        // Try to get a live price
        try oracle.peek(USDT_ID, CKES_ID, 1e18) returns (uint256 amountOut, uint256 updateTime) {
            (passed, failed) = _check("Oracle price query succeeded", true, passed, failed);

            // Verify price is non-zero
            (passed, failed) = _check("Oracle price > 0", amountOut > 0, passed, failed);

            // Calculate implied USD price per cKES
            uint256 impliedPrice = (1e18 * 1e18) / amountOut;

            console2.log("  Price (USD/cKES):", impliedPrice);
            console2.log("  Update time:     ", updateTime);

            // Verify price is within bounds
            bool inBounds = impliedPrice >= EXPECTED_MIN_PRICE && impliedPrice <= EXPECTED_MAX_PRICE;
            (passed, failed) = _check("Oracle price within bounds", inBounds, passed, failed);

            if (!inBounds) {
                console2.log("  Min bound:", EXPECTED_MIN_PRICE);
                console2.log("  Max bound:", EXPECTED_MAX_PRICE);
                console2.log("  Actual:   ", impliedPrice);
            }

            // Verify update time is recent (not zero)
            (passed, failed) = _check("Oracle update time > 0", updateTime > 0, passed, failed);
        } catch Error(string memory reason) {
            console2.log("  FAIL: Oracle price query failed -", reason);
            failed++;
        } catch {
            console2.log("  FAIL: Oracle price query failed - unknown error");
            failed++;
        }

        return (passed, failed, missingCode);
    }

    function _verifySeriesAndIlks(
        uint256 passed,
        uint256 failed,
        bool missingCode
    ) internal view returns (uint256, uint256, bool) {
        Cauldron cauldron = Cauldron(CAULDRON);
        if (!_hasCode(CAULDRON)) {
            console2.log("  [FAIL] Cauldron has no code (wrong address or wrong chain/RPC)");
            failed++;
            missingCode = true;
            return (passed, failed, missingCode);
        }

        // Verify cKES asset registered
        address ckesAsset = cauldron.assets(CKES_ID);
        (passed, failed) = _check("cKES asset registered", ckesAsset != address(0), passed, failed);

        // Verify USDT asset registered
        address usdtAsset = cauldron.assets(USDT_ID);
        (passed, failed) = _check("USDT asset registered", usdtAsset != address(0), passed, failed);

        // Verify fyUSDT series exists (public mapping returns individual fields)
        (IFYToken fyToken, bytes6 baseId, uint32 maturity) = cauldron.series(USDT_ID);
        (passed, failed) = _check("fyUSDT series exists", address(fyToken) == FYUSDT, passed, failed);

        // Verify series baseId
        (passed, failed) = _check("Series baseId = USDT", baseId == USDT_ID, passed, failed);

        // Avoid unused variable warning
        maturity;

        // Verify cKES is approved as collateral (ilk) for USDT series
        bool ilkApproved = cauldron.ilks(USDT_ID, CKES_ID);
        (passed, failed) = _check("cKES approved as ilk for USDT", ilkApproved, passed, failed);

        return (passed, failed, missingCode);
    }

    function _verifyPermissions(
        uint256 passed,
        uint256 failed,
        bool missingCode
    ) internal view returns (uint256, uint256, bool) {
        Cauldron cauldron = Cauldron(CAULDRON);
        Join ckesJoin = Join(CKES_JOIN);
        Join usdtJoin = Join(USDT_JOIN);
        FYToken fyToken = FYToken(FYUSDT);

        // Ladle permissions on Cauldron
        if (_hasCode(CAULDRON)) {
            (passed, failed) = _check(
                "Ladle has build on Cauldron",
                cauldron.hasRole(Cauldron.build.selector, LADLE),
                passed,
                failed
            );

            (passed, failed) = _check(
                "Ladle has pour on Cauldron",
                cauldron.hasRole(Cauldron.pour.selector, LADLE),
                passed,
                failed
            );
        } else {
            console2.log("  [FAIL] Cauldron has no code (wrong address or wrong chain/RPC)");
            failed++;
            missingCode = true;
        }

        // Witch permissions on Cauldron
        if (_hasCode(CAULDRON)) {
            (passed, failed) = _check(
                "Witch has give on Cauldron",
                cauldron.hasRole(Cauldron.give.selector, WITCH),
                passed,
                failed
            );
        }

        // Ladle permissions on Joins
        if (_hasCode(CKES_JOIN)) {
            (passed, failed) = _check(
                "Ladle has join on cKES Join",
                ckesJoin.hasRole(Join.join.selector, LADLE),
                passed,
                failed
            );

            (passed, failed) = _check(
                "Ladle has exit on cKES Join",
                ckesJoin.hasRole(Join.exit.selector, LADLE),
                passed,
                failed
            );
        } else {
            console2.log("  [FAIL] cKES Join has no code (wrong address or wrong chain/RPC)");
            failed++;
            missingCode = true;
        }

        if (_hasCode(USDT_JOIN)) {
            (passed, failed) = _check(
                "Ladle has join on USDT Join",
                usdtJoin.hasRole(Join.join.selector, LADLE),
                passed,
                failed
            );

            (passed, failed) = _check(
                "Ladle has exit on USDT Join",
                usdtJoin.hasRole(Join.exit.selector, LADLE),
                passed,
                failed
            );
        } else {
            console2.log("  [FAIL] USDT Join has no code (wrong address or wrong chain/RPC)");
            failed++;
            missingCode = true;
        }

        // Ladle permissions on fyToken
        if (_hasCode(FYUSDT)) {
            (passed, failed) = _check(
                "Ladle has mint on fyUSDT",
                fyToken.hasRole(FYToken.mint.selector, LADLE),
                passed,
                failed
            );

            (passed, failed) = _check(
                "Ladle has burn on fyUSDT",
                fyToken.hasRole(FYToken.burn.selector, LADLE),
                passed,
                failed
            );
        } else {
            console2.log("  [FAIL] fyUSDT has no code (wrong address or wrong chain/RPC)");
            failed++;
            missingCode = true;
        }

        return (passed, failed, missingCode);
    }

    function _hasCode(address a) internal view returns (bool) {
        return a.code.length > 0;
    }

    function _codeSize(address a) internal view returns (uint256) {
        return a.code.length;
    }

    function _checkCode(
        string memory name,
        address a,
        uint256 passed,
        uint256 failed,
        bool missingCode
    ) internal view returns (uint256, uint256, bool) {
        if (_hasCode(a)) {
            string memory logMsg = string.concat("  [PASS] ", name);
            logMsg = string.concat(logMsg, " deployed (code size:");
            logMsg = string.concat(logMsg, _toString(_codeSize(a)));
            logMsg = string.concat(logMsg, " bytes)");
            console2.log(logMsg);
            return (passed + 1, failed, missingCode);
        }
        string memory failMsg = string.concat("  [FAIL] ", name);
        failMsg = string.concat(failMsg, " has no code (wrong address or wrong chain/RPC)");
        console2.log(failMsg);
        return (passed, failed + 1, true);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _check(
        string memory description,
        bool condition,
        uint256 passed,
        uint256 failed
    ) internal view returns (uint256, uint256) {
        if (condition) {
            console2.log("  [PASS]", description);
            return (passed + 1, failed);
        } else {
            console2.log("  [FAIL]", description);
            return (passed, failed + 1);
        }
    }
}
