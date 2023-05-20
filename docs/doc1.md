we need to know the contract deployment timestamp or block number for to explore blocks for events until that specific block. 

first of all we want to try if we can get it from web3.

so here is the result from the stackexchange: https://ethereum.stackexchange.com/questions/24310/how-to-find-contract-creation-block-time-with-web3

and here is the answer: If you have the transaction hash that created the contract, do a web3.eth.getTransactionReceipt(*hash*). The resulting object will contain a blockNumber.

so we can get it from web3.eth.getTransactionReceipt and we do not need to store the creation timestamp or block number in the contract itself.