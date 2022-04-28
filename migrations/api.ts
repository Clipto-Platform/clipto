import axios from "axios";

const fetch = async <T>(
  url: string,
  query: string,
): Promise<any> => {
    return await axios.post(url, {
      query: query,
    });
};

export const getCreators = async (url: string): Promise<any> => {
  const query = `
    query GetAllCreators 
    {
        creators
        {
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
  return fetch(url, query);
};

export const getRequests = async (url: string): Promise<any> => {
  const query = `
  query GetRequests
  {
    requests
    {
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

  return fetch(url, query);
};
