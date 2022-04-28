# Clipto

Clipto is a decentralized service that lets users hire creators to make personalized videos.

## Set up

1. Install dependencies

```
npm install
```

2. Update the env variables

```
cp .env.example .env
```

3. Run tests

```
npm run test

# to run tests on localhost
npm run node
npm run test:localhost
```

4. Deploy

```
# to compile the contracts
npm run compile

# to deploy to localhost, or polygon
# for local start a node in separate console
npm run node
npm run deploy:local

# mainnet
npm run deploy:mainnet

# testnet
npm run deploy:testnet

# to view all available commands
npm run
```

- To setup git pre-commit hook

```
npm run hooks
```

## Deployments

### Mumbai

```
CliptoExchange : 0x1E425016eb93ec7a3811Cca76a64A80B0129AEdb
CliptoToken    : 0xF6505f3D0C5998b13b48B9f4bDB28df71916779e
```

### Polygon

```

```
