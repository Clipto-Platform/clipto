import * as api from "./api";
import { Config, Creator, MigrateCreatorArgs } from "./types";

export const allCreators = async (config: Config): Promise<Creator[]> => {
  let res = await api.getCreators(config.graphAPI);
  let raw: [] = res.data.data.creators;
  return raw;
};

export const getCreatorArgs = async (config: Config): Promise<MigrateCreatorArgs> => {
  const creatorAddresses: string[] = [];
  const creatorNames: string[] = [];
  const creators = await allCreators(config);

  creators.forEach((creator) => {
    creatorAddresses.push(creator.address.toLowerCase());
    creatorNames.push(creator.userName);
  });

  const args: MigrateCreatorArgs = {
    creatorAddresses,
    creatorNames,
  };

  return args;
};
