export interface Config {
  rpcUrl: string;
  graphAPI: string;
  address: string;
}

export interface Creator {
  id: string;
  address: string;
  tokenAddress: string;
  twitterHandle: string;
  bio: string;
  deliveryTime: number;
  demos: [string];
  profilePicture: string;
  userName: string;
  price: number;
  txHash: string;
  block: number;
  timestamp: number;
}

export interface Request {
  id: string;
  requestId: number;
  creator: string;
  requester: string;
  amount: number;
  tokenId: number;
  tokenUri: string;
  tokenAddress: string;
  refunded: boolean;
  delivered: boolean;
  description: string;
  deadline: number;
  txHash: string;
  block: number;
  timestamp: number;
}

export interface ResponseRequest {
  id: string;
  requestId: number;
  creator: {
    id: string;
  };
  requester: string;
  amount: number;
  tokenId: number;
  tokenUri: string;
  tokenAddress: string;
  refunded: boolean;
  delivered: boolean;
  description: string;
  deadline: number;
  txHash: string;
  block: number;
  timestamp: number;
}

export interface MigrateCreatorArgs {
  creatorAddresses: string[];
  creatorNames: string[];
  metadataUris: string[];
}

export interface MigrateRequestArgs {
  creatorAddresses: string[];
  requesterAddresses: string[];
  amount: number[];
  fulfilled: boolean[];
  metadataUris: string[];
}
