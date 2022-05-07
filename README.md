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

### V1

V1 refers to graph based architecture

```
Mumbai
CliptoExchange : 0x307736eCecF51104a841CfF44A2508775878fe3f
CliptoToken    : 0x11FAEacaacf5a0Bfc3F581e8900D9448c2D466e4
```

```
Polygon
CliptoExchange : 0x36A9F25B8AA6b941B0c8177684E8ecff59376D9a
CliptoToken    : 0xa318A87Fd79d7cD91288b4C08896BebCd788Fac4
```

### Latest

```
Mumbai
CliptoExchange Proxy : 0x10970e6FD7545d24021c2dE1ee7963E6F3235df2
CliptoToken Beacon   : 0xFa0a1EaB48C7dB26F8021bD3291C534Ba8453123
```
