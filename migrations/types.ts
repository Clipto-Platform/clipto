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

export interface MigrateCreatorArgs {
  creatorAddresses: string[];
  creatorNames: string[];
}
