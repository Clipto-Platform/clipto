## Clipto Exchange

This contract manages the userflow on the platform. The contract is responsible
to keep track of `creators` and their `requests` which are stored on chain and
other metadata is stored by ipfs

Roles:

- Creators: creators are content creators who mint NFT for completion of a requests.
- Requests: A request made to creator with minimal instructions and incentives, which is then fulfilled by creators by minting a video nft based
  on the instructions.

## Storage structures

### Creator

Stores the data of creator who is registered on the platform.

```solidity

struct Creator {

  // nft contract address cloned for the creator, a separate collection
  address nft;

  // metadata uri storing profile, twitter, pictures, work details
  // accepts: ipfs link
  string metadataURI;

}

// stores all creators on the platform
// key = creators' public address
mapping(address => Creator) public creators;

```

Function that adds a new record.

```solidity
function registerCreator(string calldata _creatorName, string calldata _metadataURI)
```

### Request

Stores the data of all the requests made to the creators.

```solidity

struct Request {

    // address of the requester
    address requester;

    // address of the nft receiver, this address is used to mint to
    // useful when someone wants to gift an nft
    address nftReceiver;

    // address of erc20 token type being used for payments
    address erc20;

    // amount of erc20 used for the request
    uint256 amount;

    // status of the request, completed = 1, pending = 0
    bool fulfilled;

    // extra metadata of the request
    string metadataURI;

}

// stores all requests for the creator
// key = creators' address
mapping(address => Request[]) public requests;

```

Function that adds a new record. Here one function is payable which is used to request using
native erc20 i.e.`MATIC` for polygon, while the other function accepts erc20 of a kind.

```solidity

function newRequest(
    address _creator,
    address _nftReceiver,
    address _erc20,
    uint256 _amount,
    string calldata _metadataURI
)

function nativeNewRequest(
    address _creator,
    address _nftReceiver,
    string calldata _metadataURI
)

```
