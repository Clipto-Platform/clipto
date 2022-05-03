export interface Config {
  rpcUrl: string;
  graphAPI: string;
  address: string;
}

export interface Creator {
  address: string;
  userName: string;
}

export interface MigrateCreatorArgs {
  creatorAddresses: string[];
  creatorNames: string[];
}
