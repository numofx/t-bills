CELO_ORACLE="0x52e860327bCc464014259A7cD16DaA5763d7Dc99"

CELO_BASES=(\
    ["0x303000000000"]="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    ["0x313000000000"]="0x30D9410ED1D5DA1F6C8391af5338C93ab8d4035C"
)

export CI=false
export RPC="CELO"
export NETWORK="CELO"
export MOCK=false

for base in ${!CELO_BASES[@]}; do
    for quote in ${!CELO_BASES[@]}; do 
        if [ $base -ne $quote ]; then 
            echo     "Convex Oracle:  " $CELO_ORACLE
            printf   "Base:            %x\n" $base
            printf   "Quote:           %x\n" $quote
            echo     "Base Address:   " ${CELO_BASES[$base]}
            echo     "Quote Address:  " ${CELO_BASES[$quote]}
            ORACLE=$CELO_ORACLE \
            BASE=$(printf "%x" $base) \
            QUOTE=$(printf "%x" $quote) \
            BASE_ADDRESS=${CELO_BASES[$base]} \
            QUOTE_ADDRESS=${CELO_BASES[$quote]} \
            forge test -c contracts/test/oracles/ConvexOracle.t.sol -m testConversionHarness
        fi
    done
done 