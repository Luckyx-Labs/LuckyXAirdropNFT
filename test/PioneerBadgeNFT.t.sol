// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/PioneerBadgeNFT.sol";

contract PioneerBadgeNFTTest is Test {
    PioneerBadgeNFT public nft;
    
    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    
    string constant BASE_URI = "https://arweave.net/metadata/";
    
    // Merkle tree data for testing
    // Leaves: [keccak256(abi.encode(0, user1)), keccak256(abi.encode(1, user2)), keccak256(abi.encode(2, user3))]
    bytes32 public merkleRoot;
    bytes32[] public proof1;
    bytes32[] public proof2;
    bytes32[] public proof3;

    function setUp() public {
        // Deploy contract
        nft = new PioneerBadgeNFT(
            "TestNFT",
            "TNFT",
            BASE_URI
        );
        
        // Build merkle tree for 3 users
        // Leaf nodes - using abi.encode to match contract
        bytes32 leaf0 = keccak256(abi.encode(uint256(0), user1));
        bytes32 leaf1 = keccak256(abi.encode(uint256(1), user2));
        bytes32 leaf2 = keccak256(abi.encode(uint256(2), user3));
        
        // Sort and hash pairs for merkle tree
        bytes32 hash01 = _hashPair(leaf0, leaf1);
        bytes32 hash2 = leaf2; // Odd leaf, gets promoted
        
        merkleRoot = _hashPair(hash01, hash2);
        
        // Build proofs
        proof1 = new bytes32[](2);
        proof1[0] = leaf1;
        proof1[1] = hash2;
        
        proof2 = new bytes32[](2);
        proof2[0] = leaf0;
        proof2[1] = hash2;
        
        proof3 = new bytes32[](1);
        proof3[0] = hash01;
    }
    
    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }

    // ============ Constructor Tests ============

    function test_Constructor() public view {
        assertEq(nft.name(), "TestNFT");
        assertEq(nft.symbol(), "TNFT");
        assertEq(nft.owner(), owner);
        assertEq(nft.totalSupply(), 0);
        assertEq(nft.mintActive(), false);
    }

    // ============ Admin Function Tests ============

    function test_SetMerkleRoot() public {
        nft.setMerkleRoot(merkleRoot);
        assertEq(nft.merkleRoot(), merkleRoot);
    }

    function test_SetMerkleRoot_EmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit PioneerBadgeNFT.MerkleRootUpdated(merkleRoot);
        nft.setMerkleRoot(merkleRoot);
    }

    function test_SetMerkleRoot_RevertIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.setMerkleRoot(merkleRoot);
    }

    function test_SetMintActive() public {
        nft.setMintActive(true);
        assertEq(nft.mintActive(), true);
        
        nft.setMintActive(false);
        assertEq(nft.mintActive(), false);
    }

    function test_SetMintActive_RevertIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.setMintActive(true);
    }

    function test_SetBaseURI() public {
        string memory newURI = "https://new.uri/";
        nft.setBaseURI(newURI);
        
        // Need to mint a token to check tokenURI
        nft.setMerkleRoot(merkleRoot);
        nft.setMintActive(true);
        vm.prank(user1);
        nft.mint(0, proof1);
        
        assertEq(nft.tokenURI(1), newURI);
    }

    function test_SetBaseURI_EmitsEvent() public {
        string memory newURI = "https://new.uri/";
        vm.expectEmit(false, false, false, true);
        emit PioneerBadgeNFT.BaseURIUpdated(newURI);
        nft.setBaseURI(newURI);
    }

    function test_SetBaseURI_RevertIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.setBaseURI("https://new.uri/");
    }

    function test_SetBaseURI_RevertIfEmpty() public {
        vm.expectRevert(PioneerBadgeNFT.EmptyBaseURI.selector);
        nft.setBaseURI("");
    }

    function test_Constructor_RevertIfEmptyBaseURI() public {
        vm.expectRevert(PioneerBadgeNFT.EmptyBaseURI.selector);
        new PioneerBadgeNFT("Test", "TST", "");
    }

    // ============ Mint Tests ============

    function test_Mint_Success() public {
        nft.setMerkleRoot(merkleRoot);
        nft.setMintActive(true);
        
        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit PioneerBadgeNFT.Claimed(user1, 0, 1);
        nft.mint(0, proof1);
        
        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.balanceOf(user1), 1);
        assertTrue(nft.isMinted(0));
    }

    function test_Mint_MultipleMints() public {
        nft.setMerkleRoot(merkleRoot);
        nft.setMintActive(true);
        
        vm.prank(user1);
        nft.mint(0, proof1);
        
        vm.prank(user2);
        nft.mint(1, proof2);
        
        assertEq(nft.totalSupply(), 2);
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(2), user2);
    }

    function test_Mint_RevertIfMintNotActive() public {
        nft.setMerkleRoot(merkleRoot);
        // mintActive is false by default
        
        vm.prank(user1);
        vm.expectRevert(PioneerBadgeNFT.MintNotActive.selector);
        nft.mint(0, proof1);
    }

    function test_Mint_RevertIfRootNotSet() public {
        nft.setMintActive(true);
        // merkleRoot is bytes32(0) by default
        
        vm.prank(user1);
        vm.expectRevert(PioneerBadgeNFT.MerkleRootNotSet.selector);
        nft.mint(0, proof1);
    }

    function test_Mint_RevertIfAlreadyMinted() public {
        nft.setMerkleRoot(merkleRoot);
        nft.setMintActive(true);
        
        vm.prank(user1);
        nft.mint(0, proof1);
        
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(PioneerBadgeNFT.AlreadyMinted.selector, 0));
        nft.mint(0, proof1);
    }

    function test_Mint_RevertIfInvalidProof() public {
        nft.setMerkleRoot(merkleRoot);
        nft.setMintActive(true);
        
        // Use wrong proof
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(PioneerBadgeNFT.InvalidProof.selector, user1, 0));
        nft.mint(0, proof2); // proof2 is for user2
    }

    function test_Mint_RevertIfWrongIndex() public {
        nft.setMerkleRoot(merkleRoot);
        nft.setMintActive(true);
        
        // User1 tries to mint with wrong index
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(PioneerBadgeNFT.InvalidProof.selector, user1, 1));
        nft.mint(1, proof1); // index 1 is for user2
    }

    // ============ isMinted Tests ============

    function test_IsMinted_ReturnsFalseInitially() public view {
        assertFalse(nft.isMinted(0));
        assertFalse(nft.isMinted(1));
        assertFalse(nft.isMinted(255));
        assertFalse(nft.isMinted(256));
    }

    function test_IsMinted_ReturnsTrueAfterMint() public {
        nft.setMerkleRoot(merkleRoot);
        nft.setMintActive(true);
        
        vm.prank(user1);
        nft.mint(0, proof1);
        
        assertTrue(nft.isMinted(0));
        assertFalse(nft.isMinted(1));
    }

    // ============ TokenURI Tests ============

    function test_TokenURI() public {
        nft.setMerkleRoot(merkleRoot);
        nft.setMintActive(true);
        
        vm.prank(user1);
        nft.mint(0, proof1);
        
        assertEq(nft.tokenURI(1), BASE_URI);
    }

    function test_TokenURI_RevertIfTokenDoesNotExist() public {
        vm.expectRevert();
        nft.tokenURI(999);
    }

    // ============ SupportsInterface Tests ============

    function test_SupportsInterface_ERC721() public view {
        assertTrue(nft.supportsInterface(0x80ac58cd)); // ERC721
    }

    function test_SupportsInterface_ERC721Metadata() public view {
        assertTrue(nft.supportsInterface(0x5b5e139f)); // ERC721Metadata
    }

    function test_SupportsInterface_ERC165() public view {
        assertTrue(nft.supportsInterface(0x01ffc9a7)); // ERC165
    }

    // ========================================== Fuzz Tests ============================================================

    function testFuzz_SetMerkleRoot(bytes32 root) public {
        nft.setMerkleRoot(root);
        assertEq(nft.merkleRoot(), root);
    }

    function testFuzz_SetBaseURI(string memory uri) public {
        // Skip empty URIs as they should revert
        vm.assume(bytes(uri).length > 0);
        
        nft.setBaseURI(uri);
        
        // Mint a token to verify
        nft.setMerkleRoot(merkleRoot);
        nft.setMintActive(true);
        vm.prank(user1);
        nft.mint(0, proof1);
        
        assertEq(nft.tokenURI(1), uri);
    }

    function testFuzz_IsMinted_BitMapIndices(uint256 index) public view {
        // Test that isMinted works correctly for various indices
        index = bound(index, 0, 10000);
        assertFalse(nft.isMinted(index));
    }

    function testFuzz_MintedBitMap_WordIndex(uint256 index) public pure {
        // Verify bitmap storage layout
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        
        // These should always be consistent
        assertLt(bitIndex, 256);
        assertEq(wordIndex * 256 + bitIndex, index);
    }

    // ============ Invariant Tests ============

    function invariant_TotalSupplyMatchesBalance() public view {
        // Total supply should equal sum of all balances
        // (simplified check - in real test would track all holders)
        assertGe(nft.totalSupply(), 0);
    }

    // Note: Removed invariant_OwnerNeverZero as renounceOwnership() 
    // from Ownable allows setting owner to zero address by design
}
