// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "forge-std/src/Script.sol";
import "forge-std/src/console2.sol";
import "../src/oracles/mento/MentoSpotOracle.sol";
import "../src/oracles/mento/ISortedOracles.sol";
import "@yield-protocol/utils-v2/src/token/IERC20Metadata.sol";

/**
 * @title ConfigureOracleManually
 * @notice Configure a reused MentoSpotOracle with the cKES/USD source
 *
 * USAGE:
 *   source .env
 *   forge script script/ConfigureOracleManually.s.sol \
 *     --rpc-url "$CELO_RPC_URL" \
 *     --broadcast \
 *     -vvvv
 */
contract ConfigureOracleManually is Script {
    bytes6 constant CKES_ID = 0x634b45530000; // "cKES"
    bytes6 constant USDT_ID = 0x555344540000; // "USDT"

    uint256 constant ORACLE_MAX_AGE = 600;        // 10 minutes
    uint256 constant CKES_MIN_PRICE = 0.003e18;   // 0.003 USD
    uint256 constant CKES_MAX_PRICE = 0.015e18;   // 0.015 USD

    address constant DEFAULT_CUSD = 0x765DE816845861e75A25fCA122bb6898B8B1282a;
    address constant DEFAULT_KES_USD_RATE_FEED = 0xbAcEE37d31b9f022Ef5d232B9fD53F05a531c169;

    function run() external {
        console2.log("============================================================");
        console2.log("Configure MentoSpotOracle - cKES/USD Source");
        console2.log("============================================================");
        console2.log("");

        // Load environment
        address oracleAddress = vm.envAddress("MENTO_ORACLE");
        address ckesToken = vm.envAddress("CKES");
        address cusdToken = vm.envOr("CUSD", DEFAULT_CUSD);
        address kesUsdRateFeed = vm.envOr("KES_USD_RATE_FEED", DEFAULT_KES_USD_RATE_FEED);
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deployer:      ", deployer);
        console2.log("Oracle:        ", oracleAddress);
        console2.log("cKES Token:    ", ckesToken);
        console2.log("cUSD Token:    ", cusdToken);
        console2.log("Rate Feed:     ", kesUsdRateFeed);
        console2.log("");

        MentoSpotOracle oracle = MentoSpotOracle(oracleAddress);

        // Check current configuration
        console2.log("Checking current configuration...");
        (
            address currentRateFeed,
            uint8 baseDecimals,
            uint8 quoteDecimals,
            bool inverse,
            uint256 maxAge,
            uint256 minPrice,
            uint256 maxPrice
        ) = oracle.sources(CKES_ID, USDT_ID);

        if (currentRateFeed != address(0)) {
            console2.log("ALREADY CONFIGURED:");
            console2.log("  Rate Feed:    ", currentRateFeed);
            console2.log("  Base Decimals:", baseDecimals);
            console2.log("  Quote Decimals:", quoteDecimals);
            console2.log("  Inverse:      ", inverse);
            console2.log("  Max Age:      ", maxAge);
            console2.log("  Min Price:    ", minPrice);
            console2.log("  Max Price:    ", maxPrice);
            console2.log("");
            console2.log("No action needed - oracle is already configured");
            return;
        }

        console2.log("NOT CONFIGURED - proceeding with configuration");
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Grant configuration roles
        console2.log("Granting configuration roles...");
        if (!oracle.hasRole(oracle.setSource.selector, deployer)) {
            oracle.grantRole(oracle.setSource.selector, deployer);
        }
        if (!oracle.hasRole(oracle.setMaxAge.selector, deployer)) {
            oracle.grantRole(oracle.setMaxAge.selector, deployer);
        }
        if (!oracle.hasRole(oracle.setBounds.selector, deployer)) {
            oracle.grantRole(oracle.setBounds.selector, deployer);
        }
        console2.log("  Roles granted");

        // Configure source
        console2.log("Setting source...");
        IERC20Metadata cKES = IERC20Metadata(ckesToken);
        IERC20Metadata cUSD = IERC20Metadata(cusdToken);

        oracle.setSource(
            CKES_ID,
            cKES,
            USDT_ID,  // Use USDT as USD proxy
            cUSD,
            kesUsdRateFeed,
            false  // not inverse
        );
        console2.log("  Source set: cKES/USD");

        // Set safety parameters
        console2.log("Setting safety parameters...");
        oracle.setMaxAge(CKES_ID, USDT_ID, ORACLE_MAX_AGE);
        console2.log("  Max age set:", ORACLE_MAX_AGE, "seconds");

        oracle.setBounds(CKES_ID, USDT_ID, CKES_MIN_PRICE, CKES_MAX_PRICE);
        console2.log("  Bounds set: min=", CKES_MIN_PRICE, "max=", CKES_MAX_PRICE);

        vm.stopBroadcast();

        // Verify configuration
        console2.log("");
        console2.log("Verifying configuration...");
        (
            address newRateFeed,
            uint8 newBaseDecimals,
            uint8 newQuoteDecimals,
            bool newInverse,
            uint256 newMaxAge,
            uint256 newMinPrice,
            uint256 newMaxPrice
        ) = oracle.sources(CKES_ID, USDT_ID);

        require(newRateFeed == kesUsdRateFeed, "Rate feed not set correctly");
        require(newMaxAge == ORACLE_MAX_AGE, "Max age not set correctly");
        require(newMinPrice == CKES_MIN_PRICE, "Min price not set correctly");
        require(newMaxPrice == CKES_MAX_PRICE, "Max price not set correctly");

        console2.log("  Configuration verified!");
        console2.log("");

        // Test price
        console2.log("Testing price query...");
        try oracle.peek(USDT_ID, CKES_ID, 1e18) returns (uint256 amountOut, uint256 updateTime) {
            uint256 impliedPrice = (1e18 * 1e18) / amountOut;
            console2.log("  Price query SUCCESS");
            console2.log("  cKES price:   ", impliedPrice, "USD");
            console2.log("  Update time:  ", updateTime);
        } catch Error(string memory reason) {
            console2.log("  Price query FAILED:", reason);
        }

        console2.log("");
        console2.log("============================================================");
        console2.log("CONFIGURATION COMPLETE");
        console2.log("============================================================");
    }
}
