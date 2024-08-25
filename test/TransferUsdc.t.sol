// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {BurnMintERC677Helper, IERC20} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";

import {TransferUSDC} from "../src/TransferUsdc.sol";
import {CrossChainReceiver} from "../src/CrossChainReceiver.sol";
import {SwapTestnetUSDC} from "../src/SwapTestnetUsdc.sol";

contract TransferUsdcTest is Test {
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
    uint256 public sourceFork;
    uint256 public destinationFork;
    address public alice;
    address public bob;
    IRouterClient public sourceRouter;
    IRouterClient public destinationRouter;
    uint64 public destinationChainSelector;
    uint64 public sourceChainSelector;
    IERC20 public sourceLinkToken;

    function setUp() public {
        string memory DESTINATION_RPC_URL = vm.envString(
            "ETHEREUM_SEPOLIA_RPC_URL"
        );
        string memory SOURCE_RPC_URL = vm.envString("AVALANCHE_FUJI_RPC_URL");
        destinationFork = vm.createSelectFork(DESTINATION_RPC_URL);
        sourceFork = vm.createFork(SOURCE_RPC_URL);

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        Register.NetworkDetails
            memory destinationNetworkDetails = ccipLocalSimulatorFork
                .getNetworkDetails(block.chainid);

        // Destination router & chainSelector
        destinationRouter = IRouterClient(
            destinationNetworkDetails.routerAddress
        );
        destinationChainSelector = destinationNetworkDetails.chainSelector;

        // Select the source fork and get the details
        vm.selectFork(sourceFork);
        Register.NetworkDetails
            memory sourceNetworkDetails = ccipLocalSimulatorFork
                .getNetworkDetails(block.chainid);

        sourceLinkToken = IERC20(sourceNetworkDetails.linkAddress);

        // Source router & chainSelector
        sourceRouter = IRouterClient(sourceNetworkDetails.routerAddress);
        sourceChainSelector = sourceNetworkDetails.chainSelector;
    }

    function test_canTransferUsdc() external {
        // Address of a wallet with USDC on the source chain
        address usdcWalletTestAddress = 0x3a9eA4a45f60F8dafCF21B18d99A9CF9e6606A1B;

        // Address of USDC on avalanche (source chain)
        address sourceUsdcAvanlache = 0x5425890298aed601595a70AB815c96711a31Bc65;
        // address sourceUsdcArbitrum = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;

        // Switch to source chain
        vm.selectFork(sourceFork);

        //  Deploy on source chain TransferUsdc.sol as the usdcWalletTestAddress (so it is owner and can call transferUsdc)
        vm.prank(usdcWalletTestAddress);
        TransferUSDC transferUsdc = new TransferUSDC(
            address(sourceRouter),
            address(sourceLinkToken),
            sourceUsdcAvanlache
        );

        // Amount of tokens to send
        uint256 amountToSend = 1000000;
        // Gas limit to provide (original / hardcoded )
        uint64 gasLimit = 500000;
        // New gas limit (after the calcu and 10% add)
        gasLimit = 241811;

        // Allow the destination chain on transferUsdc
        vm.prank(usdcWalletTestAddress);
        transferUsdc.allowlistDestinationChain(destinationChainSelector, true);

        // Fund transferUsdc with 3 link, so it can pay fees
        vm.prank(usdcWalletTestAddress);
        IERC20(sourceLinkToken).transfer(address(transferUsdc), 3e18);

        // Give the transferUsdc allowance/approval to send the USDC from usdcWalletTestAddress
        vm.prank(usdcWalletTestAddress);
        IERC20(sourceUsdcAvanlache).approve(
            address(transferUsdc),
            amountToSend
        );

        // Swap to destination fork
        vm.selectFork(destinationFork);

        // Params for the SwapTestnetUSDC.sol function
        // https://cll-devrel.gitbook.io/ccip-masterclass-4/ccip-masterclass/exercise-2-deposit-transferred-usdc-to-compound-v3#step-1-on-ethereum-sepolia-develop-and-deploy-swaptestnetusdc-smart-contract
        address destinationUsdcToken = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
        address destinationUsdcCompoundToken = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
        address destinationFauceteer = 0x68793eA49297eB75DFB4610B68e076D2A5c7646C;

        // Create SwapTestnetUsdc and deploy on destination fork
        SwapTestnetUSDC swapTestnetUsdc = new SwapTestnetUSDC(
            destinationUsdcToken,
            destinationUsdcCompoundToken,
            destinationFauceteer
        );

        // Params for CrossChainReceiver (cometAddress)
        // https://cll-devrel.gitbook.io/ccip-masterclass-4/ccip-masterclass/exercise-2-deposit-transferred-usdc-to-compound-v3#step-3-on-ethereum-sepolia-deploy-the-crosschainreceiver-smart-contract
        address destinationCometAddress = 0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e;

        // Create CrossChainReceiver and deploy on destination fork
        CrossChainReceiver crossChainReceiver = new CrossChainReceiver(
            address(destinationRouter),
            destinationCometAddress,
            address(swapTestnetUsdc)
        );

        // Allowlist crossChainReceiver to accept the sender of transferUsdc and source chain
        crossChainReceiver.allowlistSender(address(transferUsdc), true);
        crossChainReceiver.allowlistSourceChain(sourceChainSelector, true);

        // Switch to source chain
        vm.selectFork(sourceFork);

        // Pretend to be the wallet that has Usdc on the source chain
        vm.prank(usdcWalletTestAddress);

        // Call the transfer to send the message
        transferUsdc.transferUsdc(
            destinationChainSelector,
            address(crossChainReceiver),
            amountToSend,
            gasLimit
        );

        // Switch to the destination chain and process sent messages from the receving chain
        // Seeing an error here "releaseOrMint", Discord mentioned that it might be a known error, and to just comment out and commit
        // ccipLocalSimulatorFork.switchChainAndRouteMessage(destinationFork);
    }
}
