import { ethers } from "hardhat";
import { CliptoExchange } from "../typechain";
import * as constants from "./constants";
import { getCreatorArgs } from "./entity";
import { Config } from "./types";

const config: Config = {
  rpcUrl: constants.rpcUrl,
  graphAPI: constants.graphAPI,
  address: constants.contractAddress,
};

const intializeContract = async (config: Config): Promise<CliptoExchange> => {
  return await ethers.getContractAt("CliptoExchange", config.address);
};

const migrateCreators = async (contract: CliptoExchange, config: Config) => {
  const args = await getCreatorArgs(config);
  console.log(args);
};

const migrate = async () => {
  const contract = await intializeContract(config);
  await migrateCreators(contract, config);
};

migrate().catch((err) => console.log(err));
