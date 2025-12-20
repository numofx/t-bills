CELO_ORACLE="0xC597E9cA52Afc13F7F5EDdaC9e53DEF569236016"

CELO_BASES=(\
    ["0x303200000000"]="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
    ["0x303900000000"]="0xa354F35829Ae975e850e23e9615b11Da1B3dC4DE"
)

export CI=false
export RPC="CELO"
export NETWORK="CELO"
export MOCK=false

for base in ${!CELO_BASES[@]}; do
    for quote in ${!CELO_BASES[@]}; do 
        if [ $base -ne $quote ]; then 
            echo     "Yearn Oracle:   " $CELO_ORACLE
            printf   "Base:            %x\n" $base
            printf   "Quote:           %x\n" $quote
            echo     "Base Address:   " ${CELO_BASES[$base]}
            echo     "Quote Address:  " ${CELO_BASES[$quote]}
            ORACLE=$CELO_ORACLE \
            BASE=$(printf "%x" $base) \
            QUOTE=$(printf "%x" $quote) \
            BASE_ADDRESS=${CELO_BASES[$base]} \
            QUOTE_ADDRESS=${CELO_BASES[$quote]} \
            ./bin/test -c contracts/test/oracles/YearnVaultMultiOracle.t.sol -m testConversionHarness
        fi
    done
done 