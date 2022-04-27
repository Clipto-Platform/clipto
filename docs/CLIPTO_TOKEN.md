## Clipto Token

This contract is an `ERC721` contract, which is assigned to each creator on the `clipto` platoform.
For each new creator registered on the platform the `CliptoExchange` contract deployes a clone
of the `CliptoToken` contract.

The storage structure and its significance is discussed below.

### Notes

- the nft contract is `cloned` for each creator. see `CliptoExchange.sol` function `_deployCliptoFor`
- each creator has its own nft contract which is deployed when creator registers
- the nft contract address is stored in `CliptoExchangeStorage.sol`'s `Creator` struct's field `nft`
- the nft when minted is directly sent to the requester, so the transfer history will be `from 0x000... to 0x<requester address>`

### Roles

#### Minter

This role is given to the address who is responsible to mint an NFT token.

```
Assigned to: CliptoExchange Proxy Address
Where: function intialize
Name of argument: _minter
Name of variable: minter

Modifier available: onlyMinter
```

Functions that `minter` has special access to

```
Function name: setMinter(address)
How to call:
    since minter role is assigned to CliptoExchange this function is
    called from the CliptoExchange contract.
Significance:
    if for some reason, CliptoExchange contract is redeployed, this will
    help the new contract to be able to mint, for this all creators nft contracts
    needs to be updated with new minter address via calling setMinter function
    of CliptoExchange contract
```

```
Function name: setContractURI(string)
How to call:
    CliptoExchange will call this function
Significance:
    this will update the contract metadata uri from the old one, the input
    should be an ipfs link
```

```
Function name: setRoyaltyRate(uint256, uint256)
How to call:
    CliptoExchange will call this function
Significance:
    this will update the royalty rate for the contract. The default rate is 5%
Usage:
    CliptoExchange.setRoyaltyRate(nftContract, 10, 100) // 10% royalty
```

```
Function name: setFeeRecipient(address)
How to call:
    CliptoExchange will call this function
Significance:
    this will update the address where the royalty is sent to, ideally this is the
    platform's multisig wallet, used when the fee address or the owner of contracts
    changes.
```

```
Function name: safeMint(address, string)
How to call:
    CliptoExchange will call this function in its deliverRequest
Significance:
    this will allow only the exchange contract to mint an nft, which means a creator
    can only mint nft on the clipto platform and not on their own. Also, this will
    help exchange contract to mint without the permission from the owner of the
    NFT contract.
```

#### Owner

The owner of the `CliptoToken` contract is the creator

Owner makes sure that the nft minted from are minted by the creator and provides legimacy.
Also only owner can update the metadata on the OpenSea, which the creator can update to make
it as their own and still use the platform to mint and showcase.

```
Assigned to: Creator's address
Where: function intialize
Name of argument: _owner
Name of variable: owner
```

Functions that `owner` has special access to

```
Function name: transferOwnership(address)
How to call:
    this can be called on behalf of the creator.
Significance:
    this function will transfer the ownership of the nft contract to the address in the
    argument, even after the transfer of ownership the contract ensures that all mint
    functionality is only called by the exchange contract.
```

### Storage

The public values for the contract are stored in `CliptoTokenStorage.sol`.

```
Value: royaltyNumer and royaltyDenom
Use:
    these two values make up for the royalty rate for the NFT sales used along ERC2981

    royaltyRate = (salePrice * royaltyNumer) / royaltyDenom;

Default:
    royaltyRate =  royaltyNumer / royaltyDenom
    royaltyRate = 5 / 100 = 0.05 = 5%
```

```
Value: owner
Use:
    to manage ownership of the contract, has access to special function
Default:
    creator address is the owner
```

```
Value: minter
Use:
    to manage nft contract functionility of minting, has access to other functions too.
Default:
    CliptoExchange Proxy contract address
```

```
Value: feeRecipient
Use:
    to transfer all royalty fees to.
Default:
    platform multi sig wallet address
```

```
Value: contractMetadataURI
Use:
    ipfs link, which points to contract level metadata.
    see https://docs.opensea.io/docs/contract-level-metadata
Default:
    ipfs://QmdLjLZsrbHHeAYoJvJdUKCo77Qj4r1qxRPPX1vBA6LgqH
```
