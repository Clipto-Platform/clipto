// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IERC2981.sol";
import "./utils/Ownable.sol";

contract CliptoTokenV2 is ERC721("", ""), IERC2981 {
    using Counters for Counters.Counter;

    mapping(uint256 => string) private _tokenURIs;

    Counters.Counter private _currentTokenId;
    bool private _initialized;
    string private _name;

    uint256 public royaltyNumer;
    uint256 public royaltyDenom;
    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "not the owner");
        _;
    }

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    function initialize(address _owner, string memory _creatorName) public {
        require(!_initialized, "error: pre initialized contract");

        _currentTokenId.increment();

        owner = _owner;
        _name = _creatorName;

        royaltyNumer = 5;
        royaltyDenom = 100;
        _initialized = true;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return "CTO";
    }

    function totalSupply() public view returns (uint256) {
        return _currentTokenId.current() - 1;
    }

    function contractURI() public pure returns (string memory) {
        return "https://clipto.io/contract-metadata.json";
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
        require(_exists(_tokenId), "error: royalty info query of nonexistent token");
        uint256 royaltyAmount = (_salePrice * royaltyNumer) / royaltyDenom;
        return (owner, royaltyAmount);
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(_tokenId), "error: uri query of nonexistent token");
        return _tokenURIs[_tokenId];
    }

    function setRoyaltyRate(uint256 _royaltyNumer, uint256 _royaltyDenom) public onlyOwner {
        require(royaltyDenom >= 1, "error: denominator should be non zero");
        royaltyNumer = _royaltyNumer;
        royaltyDenom = _royaltyDenom;
    }

    function safeMint(address to, string memory _tokenURI) public onlyOwner {
        uint256 tokenId = _currentTokenId.current();
        _currentTokenId.increment();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function burn(uint256 _tokenId) public {
        require(_exists(_tokenId), "error: burn on nonexistent token");
        require(ERC721.ownerOf(_tokenId) == _msgSender(), "error: only owner can call burn");
        _burn(_tokenId);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal {
        require(_exists(_tokenId), "error: setting uri on nonexistent token");
        _tokenURIs[_tokenId] = _tokenURI;
    }

    function _burn(uint256 _tokenId) internal override(ERC721) {
        super._burn(_tokenId);
        if (bytes(_tokenURIs[_tokenId]).length != 0) {
            delete _tokenURIs[_tokenId];
        }
    }
}
