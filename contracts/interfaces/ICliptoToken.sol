// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

interface ICliptoToken {
    function initialize(
        address _owner,
        address _minter,
        string memory _creatorName
    ) external;

    function name() external view returns (string memory);

    function symbol() external pure returns (string memory);

    function totalSupply() external view returns (uint256);

    function contractURI() external pure returns (string memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function safeMint(address to, string memory _tokenURI) external;

    function burn(uint256 _tokenId) external;

    function transferOwnership(address newOwner) external;

    function setMinter(address _minter) external;
}
