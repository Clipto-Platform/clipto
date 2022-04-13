import * as api from "./api";
import {
  Config,
  Creator,
  MigrateCreatorArgs,
  MigrateRequestArgs,
  Request,
  ResponseRequest
} from "./types";

export const allCreators = async (config: Config): Promise<Creator[]> => {
  let res = await api.getCreators(config.graphAPI);
  let raw: [] = res.data.data.creators;

  if (raw.length !== config.numberOfCreators) {
    throw new Error(
      `number of creators mismatch: expected ${config.numberOfCreators} but got ${raw.length}`,
    );
  }

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
  const creatorAddresses = [];
  const tokenAddresses = [];
  const jsonData = [];

  const creators = await allCreators(config);
  creators.forEach((creator) => {
    creatorAddresses.push(creator.address.toLowerCase());
    tokenAddresses.push(creator.tokenAddress);
    jsonData.push(
      JSON.stringify({
        twitterHandle: creator.twitterHandle,
        bio: creator.bio,
        deliveryTime: creator.deliveryTime,
        demos: creator.demos,
        profilePicture: creator.profilePicture,
        userName: creator.userName,
        price: creator.price,
        txHash: creator.txHash,
        block: creator.block,
        timestamp: creator.timestamp,
      }),
    );
  });

  let args: MigrateCreatorArgs = {
    creatorAddresses,
    tokenAddresses,
    jsonData,
  };

  return args;
};

export const getRequestArgs = async (config: Config): Promise<MigrateRequestArgs> => {
  const creatorAddresses = [];
  const requesterAddresses = [];
  const amount = [];
  const fulfilled = [];
  const jsonData = [];

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
      }),
    );
  });

  let args: MigrateRequestArgs = {
    creatorAddresses,
    requesterAddresses,
    amount,
    fulfilled,
    jsonData,
  };

  return args;
};
