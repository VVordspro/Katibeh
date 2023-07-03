this is the last research to find best ways to optimize contracts in gas fees.
we have some documentations that suggest solutions.

1. https://www.linkedin.com/pulse/optimizing-smart-contract-gas-cost-harold-achiando

- this linkedin post suggests 40 Tips to Optimize Smart Contract Gas Cost.
    1. Uncheck arithmetics operations that can’t underflow/overflow
        Solidity version 0.8+ comes with implicit overflow and underflow checks on unsigned integers. When an overflow or an underflow isn’t possible (as an example, when a comparison is made before the arithmetic operation), some gas can be saved by using an unchecked block
        
        Replace this:
        
        uint256 value = yield(a, b, c - totalFee(c), address(this));
        with this:
        
        unchecked {uint256 value = yield(a, b, c - totalFee(c), address(this));}

    2. Cach storage values in memory
        SLOADs(storage loads) are very expensive for example (100 gas after the 1st one) compared to MLOADs(memory loads) (3 gas each). Storage values read multiple times should instead be cached in memory the first time (costing just 1 SLOAD) and then read from this cache to avoid multiple SLOADs.

    3. Deployment Through Clones
        There’s a way to save a significant amount of gas on deployment using Clones:
        
        This is a solution that was adopted, as an example, by https://github.com/porter-finance/v1-core/issues/15#issuecomment-1035639516. They realized that deploying using clones was 10x cheaper:
        
        Consider applying a similar pattern.

    5. <array>.length should not be looked up in every loop of a for-loop
        Reading array length at each iteration of the loop consumes more gas than necessary.
        
        In the best-case scenario (length read on a memory variable), caching the array length in the stack saves around 3 gas per iteration. In the worst-case scenario (external calls at each iteration), the amount of gas wasted can be massive.
        
        Consider storing the array’s length in a variable before the for-loop, and use this new variable instead.
        
        Excluding the first loop costs, you also incur gas as follows:
        
        storage arrays incur (100 gas)
        memory arrays use MLOAD (3 gas)
        calldata arrays use CALLDATALOAD (3 gas)

    6. ++i costs less gas compared to i++ or i += 1
        Pre-increments and pre-decrements are cheaper.
        
        Increment:
        
        i += 1 is the most expensive form
        i++ costs 6 gas less than i += 1
        ++i costs 5 gas less than i++ (11 gas less than i += 1)
        Decrement:
        
        i -= 1 is the most expensive form
        i-- costs 11 gas less than i -= 1
        --i costs 5 gas less than i-- (16 gas less than i -= 1)
        Note that post-increments (or post-decrements) return the old value before incrementing or decrementing, hence the name post-increment:
        
        uint i = 1; 
        uint j = 2;
        require(j == i++, "This will be false as i is incremented after the comparison"); 
        However, pre-increments (or pre-decrements) return the new value:
        
        uint i = 1; 
        uint j = 2;
        require(j == ++i, "This will be true as i is incremented before the comparison"); 
        In the pre-increment case, the compiler has to create a temporary variable (when used) for returning 1 instead of 2.
        
        Consider using pre-increments and pre-decrements where they are logically relevant.

    7. Initialize variables with no default value
        If a variable is not set/initialized, it is assumed to have the default value (0 for uint, false for bool, address(0) for address…). Explicitly initializing it with its default value is an anti-pattern and wastes gas.
        
        As an example:
        
        for (uint256 i = 0; i < num.length; ++i) {};
        should be replaced with
        
        for (uint256 i; i < num.length; ++i) {};
        Consider removing explicit initializations for default values.

    8. Some variables should be immutable
        For example, variables that are only set in the constructor and never edited after that, consider marking them as immutable, as it would avoid the expensive storage-writing operations.

    10. Struct packing
        We can use the uint types uint8, uint16, uint32, etc, though Solidity reserves 256 bits of storage regardless of the uint type meaning, in normal instances, there's no cost saving. However, if you have multiple uints inside a struct, using a smaller-sized uint when possible will allow Solidity to pack these variables together to take up less storage. For example:

        struct NormalStruct {
        uint a;
        uint b;
        uint c;
        }

        struct MiniMe {
        uint32 a;
        uint32 b;
        uint c;
        }
        `mini` will cost less gas than `normal` because of struct packing

        NormalStruct normal = NormalStruct(10, 20, 30);

        MiniMe mini = MiniMe(10, 20, 30);
        For this reason, inside a struct you'll want to use the smallest integer sub-types you can get away with.
    
    14. Add unchecked {} for subtractions where the operands cannot underflow
        In a case where there's previous require and it is certain there will be no underflow, use the unchecker.
        
        require(a <= b); x = b - a
        
        //Change as shown below
        
        require(a <= b); unchecked { x = b - a }

    15. Use shorter require()/revert() strings
        When these strings get longer than 32 bytes, they cost more gas.
        
        require(msg.sender == destination, 'Can only initialize your own tranche');

    16. Use named variables in function returns
        When you don;t use the named variables in your return statement, you waste deployment gas.
        
        return numGates;

    17. Don't use bools for storage
        Booleans are more expensive compared to uint256 or any other type that takes up a full word. This is because the write operation emits an extra SLOAD that first reads the slot contents and then replaces the bits the boolean has taken up, it then writes this back. This is how the compiler defends against contract upgrades and pointer aliasing.
        
        Use uint256(1) and uint256(2) for true/false

    26. Use a more recent version of solidity
        Use a solidity version of at least 0.8.0 to get overflow protection without SafeMath.
        Use a solidity version of at least 0.8.2 to get compiler automatic inlining.
        Use a solidity version of at least 0.8.3 to get better struct packing and cheaper multiple storage reads.
        Use a solidity version of at least 0.8.4 to get custom errors, which are cheaper at deployment than revert()/require() strings.
        Use a solidity version of at least 0.8.10 to have external calls skip contract existence checks if the external call has a return value.

2. https://www.alchemy.com/overviews/solidity-gas-optimization

        1. Use Mappings Instead of Arrays
            There are two data types to describe lists of data in Solidity, arrays and maps, and their syntax and structure are quite different, allowing each to serve a distinct purpose. While arrays are packable and iterable, mappings are less expensive.

            For example, creating an array of cars in Solidity might look like this:



            string cars[];
            cars = ["ford", "audi", "chevrolet"];

            Let’s see how to create a mapping for cars:



            mapping(uint => string) public cars

            When using the mapping keyword, you will specify the data type for the key (uint) and the value (string). Then you can add some data using the constructor function.



            constructor() public {
                    cars[101] = "Ford";
                    cars[102] = "Audi";
                    cars[103] = "Chevrolet";
                }
            }

            Except where iteration is required or data types can be packed, it is advised to use mappings to manage lists of data in order to conserve gas. This is beneficial for both memory and storage.

            An integer index can be used as a key in a mapping to control an ordered list. Another advantage of mappings is that you can access any value without having to iterate through an array as would otherwise be necessary. 

        2. Enable the Solidity Compiler Optimizer
            The Solidity compiler optimizer works to make complex expressions simpler, which minimizes the size of the code and the cost of execution via inline operations, deployments costs, and function call costs.

            The Solidity optimizer specializes in inline operations. Even though an action like inlining functions can result in significantly larger code, it is frequently used because it creates the potential for additional simplifications.

            Deployment costs and function call costs are two more areas where the compiler optimizer impacts your smart contracts’ gas. 

            For example, deployment costs decrease with the decrease in "runs"—which specifies how often each opcode will be executed over the life of a contract. The impact on function call costs, however, increases with the number of runs. That’s because code optimized for more runs costs more to deploy and less after deployment.

            In the examples below, runs are set at 200 and 10,000: 



            module.exports = {
            solidity: {
                version: "0.8.9",
                settings: {
                optimizer: {
                    enabled: false,
                    runs: 200,
                },
                },
            },
            };

            Increasing runs to 10,000 and setting the default value to true:



            module.exports = {
            solidity: {
                version: "0.8.9",
                settings: {
                optimizer: {
                    enabled: true,
                    runs: 10000,
                },
                },
            },
            };

        3. Minimize On-Chain Data
            Because on-chain data is limited to what can be created natively inside a blockchain network (e.g. state, account addresses, balances, etc.), you can reduce unnecessary operations and complex computations by saving less data in storage variables, batching operations, and avoiding looping.

            The less data you save in storage variables, the less gas you'll need. Keep all data off-chain and only save the smart contract’s critical info on-chain. Developers can create more complex applications, including prediction markets, stablecoins, and parametric insurance, by integrating off-chain data into a blockchain network. 

            Using events to store data is a popular, but ill-advised method for gas optimization because, while it is less expensive to store data in events relative to variables, the data in events cannot be accessed by other smart contracts on-chain. 

            Batching Operations
            Batching operations enables developers to batch actions by passing dynamically sized arrays that can execute the same functionality in a single transaction, rather than requiring the same method several times with different values. 

            Consider the following scenario: a user wants to call getData() with five different inputs. In the streamlined form, the user would only need to pay the transaction's fixed gas cost and the gas for the msg.sender check once.



            function batchSend(Call[] memory _calls) public payable {
                for(uint256 i = 0; i < _calls.length; i++) {
                    (bool _success, bytes memory _data) = _calls[i].recipient.call{gas: _calls[i].gas, value: _calls[i].value}(_calls[i].data);
                    if (!_success) {
                        
                        assembly { revert(add(0x20, _data), mload(_data)) }
                    }
                }
            }

            Looping
            Avoid looping through lengthy arrays; not only will it consume a lot of gas, but if gas prices rise too much, it can even prevent your contract from being carried out beyond the block gas limit.

            ‍Instead of looping over an array until you locate the key you need, use mappings, which are hash tables that enable you to retrieve any value using its key in a single action.

        4. Use Indexed Events 
            Events are used to let users know when something occurs on the blockchain, as smart contracts cannot hear events on their own because contract data lives in the States trie, and event data is stored in the Transaction Receipts trie.

            ‍Events in Solidity are a shortcut to speed up the development of external systems working in combination with smart contracts. All information in the blockchain is public, and any activity can be detected by closely examining the transactions.

            Including a mechanism to keep track of a smart contract's activity after it is deployed is helpful in reducing overall gas. While looking at all of the contract's transactions is one way to keep track of the activity, because message calls between contracts are not recorded on the blockchain, that approach might not be sufficient. 



            event myFirstEvent(address indexed sender, uint256 indexed amount, string message);

            You can search for logged events using the indexed parameters as filters for those events.

            5. Use uint8 Can Increase Gas Cost
            A smart contract's gas consumption can be higher if developers use items that are less than 32 bytes in size because the Ethereum Virtual Machine can only handle 32 bytes at a time. In order to increase the element's size to the necessary size, the EVM has to perform additional operations. 



            contract A { uint8 a = 0; }

            The cost in the above example is 22,150 + 2,000 gas, compared with 7,050 gas when using a type higher than 32 bytes.



            contract A { uint a = 0; // or uint256 }

            Only when you’re working with storage values is it advantageous to utilize reduced-size parameters because the compiler will compress several elements into one storage slot, combining numerous reads or writes into a single operation.

            Smaller-size unsigned integers, such as uint8, are only more effective when multiple variables can be stored in the same storage space, like in structs. Uint256 uses less gas than uint8 in loops and other situations.

        6. Pack Your Variables 
            When processing data, the EVM adopts a novel approach: each contract has a storage location where data is kept permanently, as well as a persistent storage space where data can be read, written, and updated.

            There are 2,256 slots in the storage, each of which holds 32 bytes. Depending on their particular nature, the "state variables," or variables declared in a smart contract that are not within any function, will be stored in these slots. 

            Smaller-sized state variables (i.e. variables with less than 32 bytes in size), are saved as index values in the sequence in which they were defined, with 0 for position 1, 1 for position 2, and so on. If small values are stated sequentially, they will be stored in the same slot, including very small values like uint64.

            Consider the following example:

            Before
            Small values are not stored sequentially and use unnecessary storage space.



            contract MyContract {
            uint128 c; 
            uint256 b; 
            uint128 a;
            }

            After
            Small values are stored sequentially and use less storage space because they are packed together.



            contract Leggo {
            uint128 a;  
            uint128 c;  
            uint256 b; 
            }

        7. Free Up Unused Storage
            Deleting your unused variables helps free up space and earns a gas refund. Deleting unused variables has the same effect as reassigning the value type with its default value, such as the integer's default value of 0, or the address zero for addresses.



            //Using delete keyword
            delete myVariable;

            //Or assigning the value 0 if integer
            myInt = 0;

            Mappings, however, are unaffected by deletion, as the keys of mappings may be arbitrary and are generally unknown. Therefore, if you delete a struct, all of its members that are not mappings will reset and also recurse into its members. However, individual keys and the values they relate to can be removed.

            8. Store Data in calldata Instead of Memory for Certain Function Parameters 
            Instead of copying variables to memory, it is typically more cost-effective to load them immediately from calldata. If all you need to do is read data, you can conserve gas by saving the data in calldata.



            // calldata
            function func2 (uint[] calldata nums) external {
            for (uint i = 0; i < nums.length; ++i) {
                ...
            }
            }

            // Memory
            function func1 (uint[] memory nums) external {
            for (uint i = 0; i < nums.length; ++i) {
                ...
            }
            }

            Because the values in calldata cannot be changed while the function is being executed, if the variable needs to be updated when calling a function, use memory instead.

        9. Use immutable and constant
            Immutable and constant are keywords that can be used on state variables to limit changes to their state. Constant variables cannot be changed after being compiled, whereas immutable variables can be set within the constructor. Constant variables can also be declared at the file level, such as in the example below:



            contract MyContract {
                uint256 constant b = 10;
                uint256 immutable a;

                constructor() {
                    a = 5;
                } 
            }

        10. Use the external Visibility Modifier
            Use the external function visibility for gas optimization because the public visibility modifier is equivalent to using the external and internal visibility modifier, meaning both public and external can be called from outside of your contract, which requires more gas.

            Remember that of these two visibility modifiers, only the public modifier can be called from other functions inside of your contract.



            function one() public view returns (string memory){
                    return message;
                }

            
                function two() external view returns  (string memory){
                    return message;
                }
