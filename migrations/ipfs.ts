import { PinataClient } from "@pinata/sdk";
import * as dotenv from "dotenv";
import * as ipfs from "ipfs-http-client";

const pinataClient = require("@pinata/sdk");

dotenv.config();

const apiKey = process.env.PINATA_API_KEY || "";
const apiSecret = process.env.PINATA_API_SECRET || "";

const client: PinataClient = pinataClient(apiKey, apiSecret);
const graph = ipfs.create({
  url: "https://api.thegraph.com/ipfs/api/v0",
});

const pin = async (hash: string) => {
  const response = await graph.pin.add(hash);
  console.log(`response from graph pin ${response.toV0()}`);
};

export const save = async (name: string, data: Object): Promise<string> => {
  const result = await client.pinJSONToIPFS(data, {
    pinataMetadata: {
      name: name,
    },
    pinataOptions: {
      cidVersion: 1,
    },
  });

  // pinning to graph
  pin(result.IpfsHash);

  console.log(`ipfs results: ${name} ${result.IpfsHash}`);
  return `ipfs://${result.IpfsHash}`;
};
