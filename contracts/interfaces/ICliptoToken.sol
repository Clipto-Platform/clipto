// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

interface ICliptoToken {
    function initialize(
        address _owner,
        address _minter,
        address _feeRecipient,
        string memory _creatorName
    ) external;

    function name() external view returns (string memory);

    function symbol() external pure returns (string memory);

    function totalSupply() external view returns (uint256);

    function contractURI() external pure returns (string memory);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function setRoyaltyRate(uint256 _royaltyNumer, uint256 _royaltyDenom) external;

    function safeMint(address to, string memory _tokenURI) external;

    function burn(uint256 _tokenId) external;

    function transferOwnership(address newOwner) external;

    function setFeeRecipient(address _feeRecipient) external;

    function setMinter(address _minter) external;

    function setContractURI(string calldata _contractURI) external;
}
