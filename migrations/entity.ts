import * as api from "./api";
import * as ipfs from "./ipfs";
import {
  Config,
  Creator,
  MigrateCreatorArgs,
  MigrateRequestArgs,
  Request,
  ResponseRequest,
} from "./types";

export const allCreators = async (config: Config): Promise<Creator[]> => {
  let res = await api.getCreators(config.graphAPI);
  let raw: [] = res.data.data.creators;
  return raw;
};

export const allRequests = async (url: string): Promise<Request[]> => {
  let res = await api.getRequests(url);
  let raw: ResponseRequest[] = res.data.data.requests;

  const requests: Request[] = raw.map((r) => {
    return {
      ...r,
      creator: r.creator.id,
    };
  });

  return requests;
};

export const getCreatorArgs = async (config: Config): Promise<MigrateCreatorArgs> => {
  const creatorAddresses: string[] = [];
  const creatorNames: string[] = [];
  const jsonData: any[] = [];

  const creators = await allCreators(config);

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
      txHash: creator.txHash,
      block: creator.block,
      timestamp: creator.timestamp,
    });
  });

  const promises = jsonData.map(async (json: Creator) => {
    return await ipfs.save(json.userName, json);
  });

  const metadataUris = await Promise.all(promises);

  const args: MigrateCreatorArgs = {
    creatorAddresses,
    creatorNames,
    metadataUris: metadataUris,
  };

  return args;
};

export const getRequestArgs = async (config: Config): Promise<MigrateRequestArgs> => {
  const creatorAddresses: string[] = [];
  const requesterAddresses: string[] = [];
  const amount: number[] = [];
  const fulfilled: boolean[] = [];
  const jsonData: any[] = [];

  const requests = await allRequests(config.graphAPI);
  requests.forEach((request) => {
    creatorAddresses.push(request.creator.toLowerCase());
    requesterAddresses.push(request.requester.toLowerCase());
    amount.push(request.amount);
    fulfilled.push(request.delivered || request.refunded);

    jsonData.push(
      JSON.stringify({
        tokenId: request.tokenId,
        tokenUri: request.tokenUri,
        tokenAddress: request.tokenAddress,
        refunded: request.refunded,
        description: request.description,
        deadline: request.deadline,
        txHash: request.txHash,
        block: request.block,
        timestamp: request.timestamp,
      })
    );
  });

  const promises = jsonData.map(async (json: Request) => {
    return ipfs.save(json.creator.concat("-").concat(json.requestId.toString()), json);
  });
  const metadataUris = await Promise.all(promises);

  let args: MigrateRequestArgs = {
    creatorAddresses,
    requesterAddresses,
    amount,
    fulfilled,
    metadataUris,
  };

  return args;
};
