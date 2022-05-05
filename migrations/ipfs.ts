import { PinataClient } from "@pinata/sdk";
import * as dotenv from "dotenv";
const pinataClient = require("@pinata/sdk");

dotenv.config();

const apiKey = process.env.PINATA_API_KEY || "";
const apiSecret = process.env.PINATA_API_SECRET || "";

const client: PinataClient = pinataClient(apiKey, apiSecret);

export const save = async (name: string, data: Object): Promise<string> => {
  const result = await client.pinJSONToIPFS(data, {
    pinataMetadata: {
      name: name,
    },
    pinataOptions: {
      cidVersion: 1,
    },
  });

  console.log(`ipfs results: ${name} ${result.IpfsHash}`);
  return `ipfs://${result.IpfsHash}`;
};
