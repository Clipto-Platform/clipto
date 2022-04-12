## Migrations
This repo has scripts to make migrations from older contracts to new contracts
by fetching data from the subgraph of the old contract

## Set up
1. Install all dependencies
```
npm install
```

2. Make sure to update `constants.ts` 
```
contractAddress   # new contract deployed address
graphAPI          # old contract's subgraph api url
rpcUrl            # rpc url of the network you want to make migrations to
numberOfCreators  # no of creators on old contract, for validation purposes
```

3. Run the migrations
```
npm run start
```