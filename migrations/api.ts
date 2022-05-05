import axios from "axios";

export const getCreators = async (
  url: string,
  first: number,
  skip: number
): Promise<any> => {
  const query = `
    query GetAllCreators (
      $first: Int!,
      $skip: Int!
    )
    {
        creators(
          first: $first,
          skip: $skip,
          orderBy: timestamp
        )
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
  return await axios.post(url, {
    query: query,
    variables: {
      first: first,
      skip: skip,
    },
  });
};
