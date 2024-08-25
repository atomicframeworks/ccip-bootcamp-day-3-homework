# CCIP Bootcamp Day 3 Homework

## Task

Following the [https://docs.chain.link/ccip/tutorials/ccipreceive-gaslimit](https://docs.chain.link/ccip/tutorials/ccipreceive-gaslimit) guide measure the gas consumption of the ccipReceive function. Once you have the number, increase it by 10% and provide as gasLimit parameter of the transferUsdc function instead of the currently hard-coded 500.000

CCIP Bootcamp Day 3 Homework Task: 
https://cll-devrel.gitbook.io/ccip-bootcamp/day-3/day-3-homework

Masterclass #4: 
https://cll-devrel.gitbook.io/ccip-masterclass-4/ccip-masterclass/exercise-2-deposit-transferred-usdc-to-compound-v3#step-7-on-avalanchefuji-call-transferusdc-function



## Task Completed via #1 Local Environment

Using the CCIP Local Forked Simulator: The TransferUsdc.t.sol test file in /test folder contains a sample test to do a number of things.

1) Start up forked chains (you will need a .env file with both ETHEREUM_SEPOLIA_RPC_URL and AVALANCHE_FUJI_RPC_URL rpc urls set)
2) On the source chain (AVALANCHE_FUJI_RPC_URL) we prank as a wallet address that has USDC on Avalanche
3) Deploy transferUsdc contract as this wallet (so that it is the owner and can call transferUsdc on it)
4) Still pranked, so we are the owner, we call allowlistDestinationChain on the transferUsdc to whitelist the destination chain
5) Send some Link token to the transferUsdc contract, so that it can pay it's fees when sending CCIP messages
6) Approve/allow the transferUsdc to use some of our USDC (1000000)
7) Swtich to the destination chain to set up the CrossChainReceiver
8) On the destination chain, we deploy swapTestnetUsdc (so CrossChainReceiver can call it to swap to testnet Usdc)
9) On the destination chain, we deploy crossChainReceiver
10) Call allowlistSender on crossChainReceiver: passing in the transferUsdc address. This is so that crossChainReceiver has whitelisted the transferUsdc address and can accept messages from transferUsdc
11) Call allowlistSourceChain on crossChainReceiver: passing the sourceChainSelector. This is so that crossChainReceiver has whitelisted the sourceChain and can accept messages from that chain
12) Switch back to the source chain, because that's where the transferUsdc is deployed and where we will send our message
13) Prank as the wallet address that has USDC on Avalanche (like we did earlier), and call the transferUsdc function on our transferUsdc contract

Note: To run this project you will need to clone it with the git submodules using the --recursive flag. This will automatically download the dependencies in to the lib folder for you.
```
git clone https://github.com/atomicframeworks/ccip-bootcamp-day-3-homework.git --recursive
```

```
cd cd ccip-bootcamp-day-3-homework/
```

```
forge test
```


## Task Completed via #2 Onchain Methods
In the url [https://docs.chain.link/ccip/tutorials/ccipreceive-gaslimit](https://docs.chain.link/ccip/tutorials/ccipreceive-gaslimit) it mentions a way to testing onchain

"Testnet: You can precisely determine the required gas limit by deploying your CCIP Sender and Receiver on a testnet and transmitting several CCIP messages with the previously estimated gas. Although this approach is more time-intensive, especially if testing across multiple blockchains, it offers enhanced accuracy."

The following steps and transcations show the testing onchain using testnets & then Tenderly to view the results.

### 1) Deploy TransferUSDC.sol to Avalanche Fuji

We need to deploy the TransferUSDC contract to Avalance.

Transaction: https://testnet.snowtrace.io/tx/0x165510ca391590b7ae5b85cd07406b81a87c807c63eb05e73140b4797e12524b
Resulting contract address: 0x5C3F7052E0e4181888ddfc221892fC6C52f9803C


### 2) On AvalancheFuji, call allowlistDestinationChain function on the TransferUSDC contract

We need to allowlist the destination chain of Sepolia on our TransferUSDC contract.

Transaction:
https://testnet.snowtrace.io/tx/0x12c07121e41eb65cb014e3bb516c3821a8aa967332b47cd27b016df6ea472aa6


### 3) On AvalancheFuji, fund TransferUSDC.sol with 3 LINK

We need to give our TransferUSDC contract some LINK to pay for the CCIP transactions.

Transaction:
https://testnet.snowtrace.io/tx/0xa0334ceafc3e0062a3b203fe6acea336d9b7843767dafc6bb818c0562c13d182


### 4) On Ethereum Sepolia, deploy SwapTestnetUSDC.sol contract

We need to deploy on Sepolia our SwapTestnetUSDC contract (to manage getting the proper USDC token on the testnet). Note this is only necessary on testnets because of differing USDC tokens.

Transaction: 
https://sepolia.etherscan.io/tx/0x66b12fcd93b97bc2aeb907e0d65fec963239518e9a04f5b2ca341b86b9e56196


### 5) On Ethereum Sepolia, deploy the CrossChainReceiver.sol contract

We need to deploy on Sepolia our CrossChainReceiver contract so that we can send USDC to it from Avalance Fuji testnet.

Transaction:
https://sepolia.etherscan.io/tx/0x0651b5d613c939d0eb15491c18517f7e53492f88e7e0c2afd3d02233029d8184

### 6) On Ethereum Sepolia, call allowlistSourceChain function on CrossChainReceiver.sol 

We need to allowlist the source chain (Avalanche Fuji) for our CrossChainReceiver to accept messages from the chain.

Transaction:
https://sepolia.etherscan.io/tx/0x1f0180cc7e2877dd35226a1c8d1ab69f520d94cfd164c295ad1a6e68321fff02

### 7) On Ethereum Sepolia, call allowlistSender function on CrossChainReceiver.sol

We need to allowlist the sender (our TransferUSDC contract on Avalanche Fuji) for our CrossChainReceiver to accept messages sent from this address).

Transaction:
https://sepolia.etherscan.io/tx/0xff79ad57af2c02bc02c7c1b0f61da3491a3d213d8a03e6320b8e7a539b7f8829

### 8) On Avalanche Fuji, call approve function on USDC.sol on our TransferUSDC contract

We need to 'approve' our TransferUSDC contract to spend $1 of our USDC.

https://testnet.snowtrace.io/tx/0xa60d1a3fc21cbd9304b9ad7bcbeaeb6d76e8380c4af0fde9d12d720324fa93da

### 9) On AvalancheFuji, call transferUsdc function on our TransferUSDC contract

We need to now actually transfer the USDC by calling transferUsdc on the contract. This will send a cross chain message which we can view in the CCIP Explorer

https://testnet.snowtrace.io/tx/0xfbbc499ec716fdbe3b28f1ca5a6020e679c3a562f312545c557865b9a305408b

CCIP Explorer msg:
https://ccip.chain.link/msg/0x784f2205c06ad38ae766907130e33d6306bb9dfc05a78ebd43d90bd86e902476

### 10) Optimizing Gas - Open Tenderly for the destination transaction hash

Lookup the destination txn in Tenderly:
https://dashboard.tenderly.co/tx/sepolia/0x692d40f1f84330d159c160e71fb03eac2ea3656941c7bfe76acc624035c8ceda

Search for _callWithExactGasSafeReturnData with a payload containing the messageId (**without the 0x in front**)

Message Id:
0x784f2205c06ad38ae766907130e33d6306bb9dfc05a78ebd43d90bd86e902476

### 11) Debugger in Tenderly

Below the payload with the messageId, find the call trace from the Router to your Receiver contract. Click on the _Debugger_ tab and you'll get the gas details.

Tenderly Trace:
https://dashboard.tenderly.co/tx/sepolia/0x692d40f1f84330d159c160e71fb03eac2ea3656941c7bfe76acc624035c8ceda/debugger?trace=0.0.0.7.0.0.2

Results: 
```
"gas": {
	"gas_left": 7780172,
	gas_used": 162100,
	total_gas_used": 219828
}
```

### 12)  Increase gas used by 10% and provide as gasLimit parameter of the transferUsdc function instead of the currently hard-coded 500,000

Gas used:
219828 * 1.1 = 241811

## 13) On Avalanche Fuji, Approve USDC (again)

We gotta approve more USDC for use with the new call, since we only approved $1 before and sent it all.

Transaction:

https://testnet.snowtrace.io/tx/0x71a7c8452ae79ba07c212bd08358dec38e46570784df4ff8dca3ef67b4d1efff

## 14) On AvalancheFuji, call transferUsdc function with the new gasLimit

Call the transferUsdc function on our TransferUSDC contract with the new gasLimit.

Transaction:
https://testnet.snowtrace.io/tx/0x0fdd8025783f346d746c2ae94ce594c6a81c08ca1a952fb3140fb1a933c31bae

CCIP Explorer msg:
https://ccip.chain.link/msg/0x6a82a676789b1d73a5a5b4f2321ad007502fdcf67d6d98c7b1863b2f9918c8c2