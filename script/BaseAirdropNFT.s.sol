// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/BaseAirdropNFT.sol";

contract BaseAirdropNFTDeploy is Script {
    function run() external {
        string memory baseTokenURI = vm.envOr("BASE_TOKEN_URI", string("https://arweave.net/D4BS3fBggu98YFFlwDsSGJP-tCWOXzzS9mFiE0vNcdM"));
        string memory contractURI = vm.envOr("CONTRACT_URI", string("https://arweave.net/1TGmYVSlLZy-UKFuIiSNQPBObqUbcD2z-HYv42yjN6g"));
        
        vm.startBroadcast();
        BaseAirdropNFT nft = new BaseAirdropNFT(
            "FreemintNFT",                                          // name
            "FMNFT",                                                // symbol
            baseTokenURI,                                           // baseTokenURI 
            contractURI,                                            // contractURI
            msg.sender,                                             // royaltyReceiver 
            0                                                       // royaltyFeeNumerator
        );
        vm.stopBroadcast();
        
        console.log("BaseAirdropNFT deployed at:", address(nft));
    }
}