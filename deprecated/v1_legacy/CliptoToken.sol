// SPDX-License-Identifier: None
pragma solidity 0.8.10;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, IERC165} from "./interfaces/IERC2981.sol";
import {IERC4494} from "./interfaces/IERC4494.sol";

contract CliptoToken is ERC721("", ""), ERC721Enumerable, ERC721URIStorage, IERC2981, IERC4494 {
    /// @dev Value is equal to keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    mapping(uint256 => uint256) private _nonces;

    uint256 public tokenIdCounter = 0;
    string internal _name;
    string internal _symbol;
    bool internal initalized;
    address public owner;
    uint256 public royaltyRate;
    uint256 public scale;

    event RoyaltyRateSet(uint256 newRate);

    /// @dev all variables must be set here so the minimal proxy will work
    function initialize(string memory _creatorName) external {
        require(!initalized);

        _name = string(abi.encodePacked("Clipto - ", _creatorName));
        _symbol = "CTO";
        initalized = true;

        owner = msg.sender;

        nameHash = keccak256(bytes(_name));
        versionHash = keccak256(bytes("0.0.1"));

        /// @notice rate * 1,000,000, default: 5%
        royaltyRate = 50_000;
        scale = 1e6;
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

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        // salePrice * royaltyRate will overflow as salePrice approaches uint256
        // but this is impossible as MATIC or AVAX tokens in circulation is < uint156
        tokenId;
        uint256 royaltyAmount = (salePrice * royaltyRate) / scale;
        return (owner, royaltyAmount);
    }

    /// @notice allows the contract owner to set the royalty rate
    /// @dev the rate should be represented scaled up by 10,000
    ///   for example, 10% would be input as 100,000
    function setRoyaltyRate(uint256 newRate) external {
        require(msg.sender == owner, "only owner may set rate");
        require(newRate <= 500_000, "royalty rate must be <50%");
        royaltyRate = newRate;
        emit RoyaltyRateSet(newRate);
    }

    function safeMint(address to, string memory _tokenURI) public {
        require(msg.sender == owner);
        _safeMint(to, tokenIdCounter);
        _setTokenURI(tokenIdCounter, _tokenURI);

        tokenIdCounter = tokenIdCounter + 1;
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC4494).interfaceId;
    }

    /*///////////////////////////////////////////////////////////////
                                PERMIT
    //////////////////////////////////////////////////////////////*/

    function transferWithPermit(
        address from,
        address to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory sig
    ) external {
        transferWithPermit(from, to, tokenId, deadline, sig, "");
    }

    function transferWithPermit(
        address from,
        address to,
        uint256 tokenId,
        uint256 deadline,
        bytes memory sig,
        bytes memory data
    ) public {
        permit(msg.sender, tokenId, deadline, sig);
        _safeTransfer(from, to, tokenId, data);
    }

    // permit stuff
    function nonces(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "nonces: query for nonexistent token");
        return _nonce(tokenId);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes memory sig
    ) public override {
        require(block.timestamp <= deadline, "Permit expired");

        bytes32 digest = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR(),
            keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, _nonces[tokenId], deadline))
        );

        (address recoveredAddress, ) = ECDSA.tryRecover(digest, sig);

        require(recoveredAddress != address(0), "Invalid signature");
        require(spender != owner, "ERC721Permit: approval to current owner");
        if (owner != recoveredAddress) {
            require(
                // checks for both EIP2098 sigs and EIP1271 approvals
                SignatureChecker.isValidSignatureNow(owner, digest, sig),
                "ERC721Permit: unauthorized"
            );
        }

        _approve(spender, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._transfer(from, to, tokenId);
        if (from != address(0)) {
            _nonces[tokenId]++;
        }
    }

    function _getChainId() internal view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    function _nonce(uint256 tokenId) internal view returns (uint256) {
        return _nonces[tokenId];
    }
}
