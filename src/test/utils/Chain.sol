// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

/// @dev Chain detection helper for skipping network-specific tests
library ChainHelpers {
    uint256 private constant ETHEREUM_MAINNET_CHAINID = 1;
    uint256 private constant CELO_MAINNET_CHAINID = 42220;

    function isCelo() internal view returns (bool) {
        return block.chainid == CELO_MAINNET_CHAINID;
    }

    function isEthMainnet() internal view returns (bool) {
        return block.chainid == ETHEREUM_MAINNET_CHAINID;
    }
}
