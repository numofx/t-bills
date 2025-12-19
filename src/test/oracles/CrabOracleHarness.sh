CELO_ORACLE="0x35d753A30a750C0291CD86baEDef7d27d55879F9"

CELO_BASES=(\
    ["0x303000000000"]="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    ["0x333800000000"]="0x3B960E47784150F5a63777201ee2B15253D713e8"
)

export CI=false
export RPC="CELO"
export NETWORK="CELO"
export MOCK=false

for base in ${!CELO_BASES[@]}; do
    for quote in ${!CELO_BASES[@]}; do 
        if [ $base -ne $quote ]; then 
            echo     "Crab Oracle:   " $CELO_ORACLE
            printf   "Base:           %x\n" $base
            printf   "Quote:          %x\n" $quote
            echo     "Base Address:  " ${CELO_BASES[$base]}
            echo     "Quote Address: " ${CELO_BASES[$quote]}
            ORACLE=$CELO_ORACLE \
            BASE=$(printf "%x" $base) \
            QUOTE=$(printf "%x" $quote) \
            BASE_ADDRESS=${CELO_BASES[$base]} \
            QUOTE_ADDRESS=${CELO_BASES[$quote]} \
            forge test -c contracts/test/oracles/CrabOracle.t.sol -m testConversionHarness
        fi
    done
done 