// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title PioneerBadgeNFT
 * @author LuckyX-Labs
 * @dev A gas-efficient NFT airdrop contract using Merkle Tree verification.
 * Supports ERC721 standard with bitmap-based claim tracking to prevent double claims.
 * @notice This contract allows whitelisted users to claim NFTs using Merkle proofs.
 */
contract PioneerBadgeNFT is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    /// @notice The Merkle root used for whitelist verification
    bytes32 public merkleRoot;
    
    /// @notice Total number of NFTs minted
    uint256 public totalSupply;
    
    /// @notice Bitmap to track claimed indices efficiently
    mapping(uint256 => uint256) public mintedBitMap;
    
    /// @notice Whether minting is currently active
    bool public mintActive = false;

    /// @dev Base URI for token metadata
    string private _baseTokenURI;

    /// @notice Emitted when the Merkle root is updated
    event MerkleRootUpdated(bytes32 indexed newRoot);
    
    /// @notice Emitted when the base URI is updated
    event BaseURIUpdated(string newBaseURI);
    
    /// @notice Emitted when a user claims an NFT
    event Claimed(address indexed account, uint256 indexed index, uint256 indexed tokenId);

    /// @dev Thrown when minting is not active
    error MintNotActive();
    
    /// @dev Thrown when Merkle root is not set
    error MerkleRootNotSet();
    
    /// @dev Thrown when the index has already been claimed
    error AlreadyMinted(uint256 index);
    
    /// @dev Thrown when the Merkle proof is invalid
    error InvalidProof(address caller, uint256 index);
    
    /// @dev Thrown when an empty base URI is provided
    error EmptyBaseURI();

    /**
     * @dev Initializes the contract with the given parameters.
     * @param name The name of the NFT collection
     * @param symbol The symbol of the NFT collection
     * @param baseTokenURI The base URI for token metadata
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) Ownable(msg.sender) {
        if (bytes(baseTokenURI).length == 0) revert EmptyBaseURI();
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @dev Sets the Merkle root for whitelist verification.
     * @param _newRoot The new Merkle root
     */
    function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
        emit MerkleRootUpdated(_newRoot);
    }

    /**
     * @dev Enables or disables minting.
     * @param _active Whether minting should be active
     */
    function setMintActive(bool _active) external onlyOwner {
        mintActive = _active;
    }

    /**
     * @dev Checks if a given index has already been claimed.
     * @param index The index to check
     * @return True if the index has been claimed, false otherwise
     */
    function isMinted(uint256 index) public view returns (bool) {
        uint256 mintedWordIndex = index / 256;
        uint256 mintedBitIndex = index % 256;
        uint256 mintedWord = mintedBitMap[mintedWordIndex];
        uint256 mask = 1 << mintedBitIndex;
        return mintedWord & mask == mask;
    }

    /**
     * @dev Marks an index as claimed in the bitmap.
     * @param index The index to mark as claimed
     */
    function _setMinted(uint256 index) private {
        uint256 mintedWordIndex = index / 256;
        uint256 mintedBitIndex = index % 256;
        mintedBitMap[mintedWordIndex] |= 1 << mintedBitIndex;
    }

    /**
     * @dev Allows a whitelisted user to claim their NFT.
     * @param index The index of the user in the whitelist
     * @param merkleProof The Merkle proof for verification
     */
    function mint(uint256 index, bytes32[] calldata merkleProof) external nonReentrant {
        if (!mintActive) revert MintNotActive();
        if (merkleRoot == bytes32(0)) revert MerkleRootNotSet();
        if (isMinted(index)) revert AlreadyMinted(index);

        bytes32 leaf = keccak256(abi.encode(index, msg.sender));
        if (!MerkleProof.verify(merkleProof, merkleRoot, leaf)) {
            revert InvalidProof(msg.sender, index);
        }

        _setMinted(index);
        unchecked {
            ++totalSupply;
        }
        uint256 tokenId = totalSupply;
        _safeMint(msg.sender, tokenId);
        emit Claimed(msg.sender, index, tokenId);
    }


    /**
     * @dev Returns the metadata URI for a token.
     * @param tokenId The token ID to query
     * @return The token metadata URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        
        return _baseTokenURI;
    }

    /**
     * @dev Returns the base URI for token metadata.
     * @return The base URI string
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Sets the base URI for token metadata.
     * @param newBaseURI The new base URI to set
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        if (bytes(newBaseURI).length == 0) revert EmptyBaseURI();
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }
}