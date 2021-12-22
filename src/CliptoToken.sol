// SPDX-License-Identifier: None
pragma solidity 0.8.10;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";

import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

contract CliptoToken is ERC721Upgradeable {
    // using Counters for Counters.Counter;

    // Counters.Counter private _tokenIdCounter;

    function initialize(string memory _creatorName) external {
        __ERC721_init(string(abi.encodePacked("Clipto - ", _creatorName)), "CTO");
    }

    function safeMint(address to, string memory data) external {
        _safeMint(to, 0);
    }

    // // See https://docs.opensea.io/docs/contract-level-metadata
    // function contractURI() public pure returns (string memory) {
    //     return "https://clipto.io/contract-metadata.json";
    // }

    // function safeMint(address to, string memory _tokenURI) public onlyOwner {
    //     _safeMint(to, _tokenIdCounter.current());
    //     _setTokenURI(_tokenIdCounter.current(), _tokenURI);

    //     _tokenIdCounter.increment();
    // }

    // /*
    //  * The following functions are overrides required by Solidity.
    //  */
    // function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    //     super._burn(tokenId);
    // }

    // function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    //     return super.tokenURI(tokenId);
    // }

    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal override(ERC721, ERC721Enumerable) {
    //     super._beforeTokenTransfer(from, to, tokenId);
    // }

    // function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    //     return super.supportsInterface(interfaceId);
    // }
}
