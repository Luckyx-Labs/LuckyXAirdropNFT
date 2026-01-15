// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BaseAirdropNFT is ERC721, ERC2981, Ownable {
    using Strings for uint256;

    bytes32 public merkleRoot;
    uint256 public totalSupply;
    mapping(uint256 => uint256) public mintedBitMap;
    bool public mintActive = false;

    string private _baseTokenURI;
    string private _contractURI;

    event MerkleRootUpdated(bytes32 indexed newRoot);
    event BaseURIUpdated(string newBaseURI);
    event ContractURIUpdated(string newContractURI);

    error MintNotActive();
    error MerkleRootNotSet();
    error AlreadyMinted(uint256 index);
    error InvalidProof(address caller, uint256 index);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory contractURI_,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _baseTokenURI = baseTokenURI;
        _contractURI = contractURI_;
        _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
    }

    function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
        emit MerkleRootUpdated(_newRoot);
    }

    function setMintActive(bool _active) external onlyOwner {
        mintActive = _active;
    }

    function isMinted(uint256 index) public view returns (bool) {
        uint256 mintedWordIndex = index / 256;
        uint256 mintedBitIndex = index % 256;
        uint256 mintedWord = mintedBitMap[mintedWordIndex];
        uint256 mask = 1 << mintedBitIndex;
        return mintedWord & mask == mask;
    }

    function _setMinted(uint256 index) private {
        uint256 mintedWordIndex = index / 256;
        uint256 mintedBitIndex = index % 256;
        mintedBitMap[mintedWordIndex] |= 1 << mintedBitIndex;
    }

    function mint(uint256 index, bytes32[] calldata merkleProof) external {
        if (!mintActive) revert MintNotActive();
        if (merkleRoot == bytes32(0)) revert MerkleRootNotSet();
        if (isMinted(index)) revert AlreadyMinted(index);

        bytes32 leaf = keccak256(abi.encodePacked(index, msg.sender));
        if (!MerkleProof.verify(merkleProof, merkleRoot, leaf)) {
            revert InvalidProof(msg.sender, index);
        }

        _setMinted(index);
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
    }


    /**
     * @dev Returns the metadata URI for a token. OpenSea calls this function to get NFT info.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        
        return _baseTokenURI;
    }

    /**
     * @dev Returns the contract-level metadata URI, used by OpenSea to display collection info.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns the base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Sets the base URI
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /**
     * @dev Sets the contract URI
     */
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractURI = newContractURI;
        emit ContractURIUpdated(newContractURI);
    }

    /**
     * @dev Sets the default royalty
     * @param receiver The address to receive royalties
     * @param feeNumerator The royalty fee numerator (in basis points, 500 = 5%)
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Deletes the default royalty
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev Supports ERC165 interface detection
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}