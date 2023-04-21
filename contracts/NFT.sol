// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is ERC721, ERC721URIStorage {
    using Strings for uint256;
    // string private ipfsHost = "https://ipfs.infura.io/"; // this ipfsHost in infura 
    string private ipfsHost = "https://ipfs.io/"; // this ipfsHost public

    constructor() ERC721("HoBiNFT", "HBNFT") {}

    function mintAndApprovalNFT(address bidNowContract, uint256 tokenId, string memory ipfsHash) public {
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _generateTokenURI(ipfsHash));
        _setApprovalForAll(msg.sender, bidNowContract, true);
    }

    function _generateTokenURI(string memory ipfsHash) internal view returns (string memory) {
        return string(abi.encodePacked(ipfsHost, "ipfs/", ipfsHash));
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
