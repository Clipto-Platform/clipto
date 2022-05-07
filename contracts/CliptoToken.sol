// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./CliptoTokenStorage.sol";

contract CliptoToken is CliptoTokenStorage, Initializable, ERC721Upgradeable {
    using Counters for Counters.Counter;

    Counters.Counter private _currentTokenId;

    mapping(uint256 => string) private _tokenURIs;

    modifier onlyMinter() {
        require(minter == msg.sender, "error: not the minter");
        _;
    }

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    function initialize(
        address _owner,
        address _minter,
        string memory _creatorName
    ) public initializer {
        ERC721Upgradeable.__ERC721_init(string(abi.encodePacked("Clipto Creator - ", _creatorName)), "CTO");
        _currentTokenId.increment();

        owner = _owner;
        minter = _minter;
    }

    function totalSupply() external view returns (uint256) {
        return _currentTokenId.current() - 1;
    }

    function contractURI() external pure returns (string memory) {
        return "ipfs://QmfAAJSnwWpTKNPyYSu1Lir9LZ1LVcBrC4WoMhxZC7K1ys";
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        require(_exists(_tokenId), "error: uri query of nonexistent token");
        return _tokenURIs[_tokenId];
    }

    function setMinter(address _minter) external onlyMinter {
        minter = _minter;
    }

    function safeMint(address to, string memory _tokenURI) external onlyMinter {
        uint256 tokenId = _currentTokenId.current();
        _currentTokenId.increment();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function transferOwnership(address newOwner) external {
        require(owner == msg.sender, "error: not the owner");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function burn(uint256 _tokenId) external {
        require(_exists(_tokenId), "error: burn on nonexistent token");
        require(ownerOf(_tokenId) == _msgSender(), "error: only owner can call burn");
        _burn(_tokenId);
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
