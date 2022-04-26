// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./CliptoTokenStorage.sol";
import "./interfaces/IERC2981.sol";

contract CliptoToken is CliptoTokenStorage, Initializable, ERC721Upgradeable, IERC2981 {
    using Counters for Counters.Counter;
    string private _name;
    mapping(uint256 => string) private _tokenURIs;
    Counters.Counter private _currentTokenId;

    modifier onlyOwner() {
        require(owner == msg.sender, "not the owner");
        _;
    }

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    function initialize(address _owner, string memory _creatorName) public initializer {
        ERC721Upgradeable.__ERC721_init(string(abi.encodePacked("Clipto Creator - ", _creatorName)), "CTO");

        _currentTokenId.increment();

        owner = _owner;
        royaltyNumer = 5;
        royaltyDenom = 100;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

    function tokenURI(uint256 _tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        require(_exists(_tokenId), "error: uri query of nonexistent token");
        return _tokenURIs[_tokenId];
    }

    function setRoyaltyRate(uint256 _royaltyNumer, uint256 _royaltyDenom) public onlyOwner {
        require(_royaltyDenom != 0, "error: denom should be non zero");
        require(_royaltyDenom >= _royaltyNumer, "error: donom should be greater than numer");
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
        require(ownerOf(_tokenId) == _msgSender(), "error: only owner can call burn");
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

    function _burn(uint256 _tokenId) internal override(ERC721Upgradeable) {
        super._burn(_tokenId);
        if (bytes(_tokenURIs[_tokenId]).length != 0) {
            delete _tokenURIs[_tokenId];
        }
    }
}
