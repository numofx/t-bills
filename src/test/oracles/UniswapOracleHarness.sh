ARBITRUM_ORACLE=""

CELO_ORACLE="0x358538ea4F52Ac15C551f88C701696f6d9b38F3C"

CELO_BASE="0x303000000000"

CELO_BASE_ADDRESS="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

CELO_QUOTES=(\
    ["0x303700000000"]="0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72"
    ["0x333900000000"]="0x4d19F33948b99800B6113Ff3e83beC9b537C85d2"
)

export CI=false
export RPC="CELO"
export NETWORK="CELO"
export MOCK=false

for quote in ${!CELO_QUOTES[@]}; do 
    echo     "Uniswap Oracle:   " $CELO_ORACLE
    printf   "Base:              %x\n" $CELO_BASE
    printf   "Quote:             %x\n" $quote
    echo     "Base Address:     " $CELO_BASE_ADDRESS
    echo     "Quote Address:    " ${CELO_QUOTES[$quote]}
    ORACLE=$CELO_ORACLE \
    BASE=$(printf "%x" $CELO_BASE) \
    QUOTE=$(printf "%x" $quote) \
    BASE_ADDRESS=$CELO_BASE_ADDRESS \
    QUOTE_ADDRESS=${CELO_QUOTES[$quote]} \
    forge test -c contracts/test/oracles/UniswapOracle.t.sol -m testConversionHarness
done
