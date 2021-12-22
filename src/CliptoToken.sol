// SPDX-License-Identifier: None
pragma solidity 0.8.10;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

contract CliptoToken is ERC721("", ""), ERC721Enumerable, ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string internal _name;
    string internal _symbol;
    bool internal initalized;
    address owner;
    /// @notice represents 5% given a scale of 10,000
    uint256 royaltyRate = 500;
    uint256 scale = 1e5;

    event RoyaltyRateSet(uint256 newRate);

    function initialize(string memory _creatorName) external {
        require(!initalized);

        _name = string(abi.encodePacked("Clipto - ", _creatorName));
        _symbol = "CTO";
        initalized = true;

        owner = msg.sender;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    // See https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public pure returns (string memory) {
        return "https://clipto.io/contract-metadata.json";
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns(address, uint256) {
        uint256 royaltyAmount = (salePrice * royaltyRate) / scale;
        return (owner, royaltyAmount);
    }

    /// @notice allows the contract owner to set the royalty rate
    /// @dev the rate should be represented scaled up by 10,000
    ///   for example, 10% would be input as 100,000
    function setRoyaltyRate(uint256 newRate) external {
        require(msg.sender == owner, "only owner may set rate");
        royaltyRate = newRate;
        emit RoyaltyRateSet(newRate);
    }

    function safeMint(address to, string memory _tokenURI) public {
        require(msg.sender == owner);
        _safeMint(to, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current(), _tokenURI);

        _tokenIdCounter.increment();
    }

    /*
     * The following functions are overrides required by Solidity.
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @dev 0x2a55205a is the interfaceId for ERC2981
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == 0x2a55205a;
    }
}
