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
            address
            userName
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
