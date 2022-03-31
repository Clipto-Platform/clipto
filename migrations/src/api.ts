import axios from "axios";
import { minGraphRecords } from "./constants";

const fetch = async <T>(
  url: string,
  query: string,
  vars: any | undefined,
): Promise<any> => {
  return axios.post(url, {
    query: query,
    variables: vars,
  });
};

export const getCreators = async (url: string): Promise<any> => {
  const query = `
    query GetAllCreators (
        $first: Int!,
        $skip: Int!
    ) {
        creators(
            first: $first,
            skip: $skip,
            orderBy: timestamp
        ){
            id
            address
            tokenAddress
            twitterHandle
            bio
            deliveryTime
            demos
            profilePicture
            userName
            price
            txHash
            block
            timestamp
        }
    }
  `;

  const variables = {
    first: minGraphRecords,
    skip: 0,
  };

  return fetch(url, query, variables);
};

export const getRequests = async (url: string): Promise<any> => {
  const query = `
  query GetRequestById (
    $first: Int!,
    $skip: Int!
) {
    requests(
      first: $first,
      skip: $skip,
      orderBy: timestamp
    ){
      id
      requestId
      requester
      creator {
        id
      }
      amount
      description
      deadline
      delivered
      refunded
      tokenAddress
      tokenId
      tokenUri
      txHash
      block
      timestamp
    }
  }
  `;

  const variables = {
    first: minGraphRecords,
    skip: 0,
  };

  return fetch(url, query, variables);
};
