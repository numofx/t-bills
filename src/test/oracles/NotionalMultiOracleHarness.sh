CELO_ORACLE="0x660bB2F1De01AacA46FCD8004e852234Cf65F3fb"

CELO_BASES=(\
    "0x303000000000"
    "0x303100000000"
    "0x303200000000"
)

CELO_BASE_ADDRESSES=(\
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    "0x6B175474E89094C44Da98b954EedeAC495271d0F"
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
)

CELO_FCASH=(\
    "0x40301200028b"
    "0x40311200028b"
    "0x40321200028b"
)

export CI=false
export RPC="CELO"
export NETWORK="CELO"
export MOCK=false

for i in {0..2}; do
    echo     "Notional Oracle:   " $CELO_ORACLE
    printf   "Base:               %x\n" ${CELO_BASES[$i]}
    printf   "Quote:              %x\n" ${CELO_FCASH[$i]}
    echo     "Base Address:      " ${CELO_BASE_ADDRESSES[$i]}
    ORACLE=$CELO_ORACLE \
    BASE=$(printf "%x" ${CELO_BASES[$i]}) \
    QUOTE=$(printf "%x" ${CELO_FCASH[$i]}) \
    BASE_ADDRESS=${CELO_BASE_ADDRESSES[$i]} \
    ./bin/test -c contracts/test/oracles/NotionalMultiOracle.t.sol -m testConversionHarness
done 