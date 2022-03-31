import * as dotenv from "dotenv";
import { ethers } from "ethers";
import { Config } from "./types";
dotenv.config();

const getWallet = (): ethers.Wallet => {
  const privateKey = process.env.PRIVATE_KEY;

  if (!privateKey) {
    throw new Error("requires PRIVATE_KEY env var for intializing wallet");
  }

  const wallet = new ethers.Wallet(privateKey);
  return wallet;
};

const getProvider = (config: Config): ethers.providers.Provider => {
  const provider = new ethers.providers.JsonRpcProvider(config.rpcUrl);
  return provider;
};

export const intializeContract = (config: Config): ethers.Contract => {
  const provider = getProvider(config);

  let wallet = getWallet();
  wallet = wallet.connect(provider);

  const contract = new ethers.Contract(config.contractAddress, config.abi, wallet);

  return contract;
};
