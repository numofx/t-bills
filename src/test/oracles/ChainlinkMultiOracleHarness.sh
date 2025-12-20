CELO_ORACLE="0xcDCe5C87f691058B61f3A65913f1a3cBCbAd9F52"

CELO_BASE="0x303000000000"

CELO_BASE_ADDRESS="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

CELO_QUOTES=(\
    ["0x303100000000"]="0x6B175474E89094C44Da98b954EedeAC495271d0F"
    ["0x303200000000"]="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
    ["0x303300000000"]="0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"
    ["0x303500000000"]="0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84"
    ["0x303600000000"]="0x514910771AF9Ca656af840dff83E8264EcF986CA"
    ["0x313000000000"]="0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"
    ["0x313800000000"]="0x853d955aCEf822Db058eb8505911ED77F175b99e"
)

export CI=false
export RPC="CELO"
export NETWORK="CELO"
export MOCK=false

for quote in ${!CELO_QUOTES[@]}; do
    echo     "Oracle:         " $CELO_ORACLE
    printf   "Base:            %x\n" $CELO_BASE
    printf   "Quote:           %x\n" $quote
    echo     "Base Address:   " ${CELO_BASE_ADDRESS}
    echo     "Quote Address:  " ${CELO_QUOTES[$quote]}
    ORACLE=$CELO_ORACLE \
    BASE=$(printf "%x" $CELO_BASE) \
    QUOTE=$(printf "%x" $quote) \
    BASE_ADDRESS=${CELO_BASE_ADDRESS} \
    QUOTE_ADDRESS=${CELO_QUOTES[$quote]} \
    ./bin/test -c contracts/test/oracles/ChainlinkMultiOracle.t.sol -m testConversionHarness
done
