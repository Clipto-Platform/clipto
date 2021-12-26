# clipto

clipto is a decentralized service that lets users hire creators to make personalized videos.

## Contributing

### Contract Setup
Run `make` to install the needed dependencies
 - [Install dapptools](https://github.com/dapphub/dapptools)
 - nix-env is a prerequiste to dapptools so you may not need to install nix-env.
 - You need to install `nix-env`. [Mac install](https://wickedchicken.github.io/post/macos-nix-setup/)

 1. `dapp build`
   This will the abi for the contract in `./out`. If you make changes and you never build or test (testing automatically builds) and proceed to the next step, you might be using an older version of a contract resulting in inexpected behavior.
 2. Terminal 1: `dapp testnet`
  This will output your contract settings:
```
dapp-testnet:   RPC URL: http://127.0.0.1:8545
dapp-testnet:  TCP port: 38545
dapp-testnet:  Chain ID: 99
dapp-testnet:  Database: /Users/main/.dapp/testnet/8545
dapp-testnet:  Geth log: /Users/main/.dapp/testnet/8545/geth.log
dapp-testnet:   Account: 0x20c7ec45C46981fB1D10033c166D852EfFf206bc (default)
```

You want to copy the address of `Account` for the next step.
 3. Terminal 2: `export ETH_FROM=<Account address here>`
 4. Terminal 2: `./scripts/deploy.sh`. If it prompts you for a password, testnet password is always nothing. So just press enter. When the script is done and is successful, the green text
 ```
 CliptoExchange deployed at: <address>
 ``` 
 will appear. Save this address if you want to connect it to the frontend.
### Frontend Setup
 1. `./scripts/abi.sh CliptoExchange > ../clipto-frontend/src/abis/CliptoExchange.json`. Note that after the `>` is the relative path to the CliptoExchange.json file for the frontend.
 2. `npm run generate-types`
 3. Go to `Clipto-Platform/clipto-frontend/src/config/config.tsx` (different repo) and edit the value for the key `EXCHANGE_ADDRESS.[CHAIN_IDS.DAPPTOOLS]` with address in step 4 Contract Step.

## Useful commands
 ```seth send --value 5000000000000000000 <youraddress>```

 This will send 5 eth to the specified address.

## Useful links for getting started
[How to use dapptools](https://medium.com/coinmonks/use-dapp-tools-for-ethereum-contract-development-2775d8b2ba0)