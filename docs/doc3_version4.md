todo list :
1. every creator can have multiple contracts
2. the name of contracts is equal to the first tag to string
3. use internal simple functions to reduce complexity
4. update compiler 17 => 19
5. update the ethers library to version 6
6. use gasEstimator
7. rewrite javascript test in ethers_v6 format to run functions
8. optimize 1155 functionality to decrease the gas on mainnet
    - optimizer runs 200 => 10000

    firstFreeCollect() 
        - default 396611
        - first internal function 397285
        - edit one if 396803
        - optimization 10000 => 200   398047
        - optimization 10000 => 1000000 396716
        - 396779