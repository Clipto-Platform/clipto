import * as api from "./api";
import { Config, Creator, MigrateCreatorArgs } from "./types";

export const getCreatorArgs = async (
  config: Config,
  first: number,
  skip: number
): Promise<MigrateCreatorArgs> => {
  const creatorAddresses: string[] = [];
  const creatorNames: string[] = [];

  let res = await api.getCreators(config.graphAPI, first, skip);
  const creators: Creator[] = res.data.data.creators;

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
