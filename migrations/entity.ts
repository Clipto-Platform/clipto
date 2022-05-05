import * as api from "./api";
import * as ipfs from "./ipfs";
import { Config, Creator, MigrateCreatorArgs } from "./types";

export const getCreatorArgs = async (
  config: Config,
  first: number,
  skip: number
): Promise<MigrateCreatorArgs> => {
  const creatorAddresses: string[] = [];
  const creatorNames: string[] = [];
  const jsonData: any[] = [];

  let res = await api.getCreators(config.graphAPI, first, skip);
  const creators: Creator[] = res.data.data.creators;

  creators.forEach((creator) => {
    creatorAddresses.push(creator.address.toLowerCase());
    creatorNames.push(creator.userName);

    jsonData.push({
      userName: creator.userName,
      twitterHandle: creator.twitterHandle,
      profilePicture: creator.profilePicture,
      bio: creator.bio,
      deliveryTime: creator.deliveryTime,
      demos: creator.demos,
      price: creator.price,
    });
  });

  const promises = jsonData.map(async (json: Creator) => {
    return await ipfs.save(json.userName, json);
  });

  const metadatURI = await Promise.all(promises);

  const args: MigrateCreatorArgs = {
    creatorAddresses,
    creatorNames,
    metadatURI,
  };

  return args;
};
