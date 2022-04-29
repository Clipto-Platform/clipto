// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./CliptoTokenStorage.sol";
import "./interfaces/IERC2981.sol";

contract CliptoToken is CliptoTokenStorage, Initializable, ERC721Upgradeable, IERC2981 {
    using Counters for Counters.Counter;

    Counters.Counter private _currentTokenId;

    mapping(uint256 => string) private _tokenURIs;

    string private _name;

    modifier onlyMinter() {
        require(minter == msg.sender, "error: not the minter");
        _;
    }

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    function initialize(
        address _owner,
        address _minter,
        address _feeRecipient,
        string memory _creatorName
    ) public initializer {
        ERC721Upgradeable.__ERC721_init(string(abi.encodePacked("Clipto Creator - ", _creatorName)), "CTO");

        _currentTokenId.increment();

        owner = _owner;
        minter = _minter;
        feeRecipient = _feeRecipient;
        royaltyNumer = 5;
        royaltyDenom = 100;
        contractMetadataURI = "ipfs://QmdLjLZsrbHHeAYoJvJdUKCo77Qj4r1qxRPPX1vBA6LgqH";
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

    function totalSupply() external view returns (uint256) {
        return _currentTokenId.current() - 1;
    }

    function contractURI() external view returns (string memory) {
        return contractMetadataURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
        require(_exists(_tokenId), "error: royalty info query of nonexistent token");
        uint256 royaltyAmount = (_salePrice * royaltyNumer) / royaltyDenom;
        return (feeRecipient, royaltyAmount);
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        require(_exists(_tokenId), "error: uri query of nonexistent token");
        return _tokenURIs[_tokenId];
    }

    function setFeeRecipient(address _feeRecipient) external onlyMinter {
        feeRecipient = _feeRecipient;
    }

    function setMinter(address _minter) external onlyMinter {
        minter = _minter;
    }

    function setContractURI(string calldata _contractURI) external onlyMinter {
        contractMetadataURI = _contractURI;
    }

    function setRoyaltyRate(uint256 _royaltyNumer, uint256 _royaltyDenom) external onlyMinter {
        require(_royaltyDenom != 0, "error: denom should be non zero");
        require(_royaltyDenom >= _royaltyNumer, "error: denom should be greater than numer");
        royaltyNumer = _royaltyNumer;
        royaltyDenom = _royaltyDenom;
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
