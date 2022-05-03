import axios from "axios";

const fetch = async <T>(url: string, query: string): Promise<any> => {
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
            address
            userName
        }
    }
  `;
  return fetch(url, query);
};
