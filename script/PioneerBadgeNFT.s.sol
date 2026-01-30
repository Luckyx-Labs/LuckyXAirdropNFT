// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PioneerBadgeNFT.sol";

contract PioneerBadgeNFTDeploy is Script {
    function run() external {
        string memory baseTokenURI = vm.envOr("BASE_TOKEN_URI", string("https://arweave.net/FEc0iKFOO7Lsc5NwidILWztVzyGfRPnMKKEZQR23_WI"));
        
        vm.startBroadcast();
        PioneerBadgeNFT nft = new PioneerBadgeNFT(
            "PioneerBadge",                                         // name
            "PB",                                                   // symbol
            baseTokenURI                                            // baseTokenURI
        );
        vm.stopBroadcast();
        
        console.log("PioneerBadgeNFT deployed at: ", address(nft));
    }
}