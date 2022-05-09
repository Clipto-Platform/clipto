import { ethers } from "hardhat";
import { CliptoExchange } from "../typechain";
import * as constants from "./constants";
import { getCreatorArgs } from "./entity";
import { Config } from "./types";

const TOTAL_CREATORS = 105;
const BATCH_SIZE = 10;
const EPOCHS = 11;

const config: Config = {
  rpcUrl: constants.rpcUrl,
  graphAPI: constants.graphAPI,
  address: constants.contractAddress,
};

const intializeContract = async (config: Config): Promise<CliptoExchange> => {
  return await ethers.getContractAt("CliptoExchange", config.address);
};

const migrateCreators = async (
  contract: CliptoExchange,
  config: Config,
  batch: number
) => {
  const first = BATCH_SIZE;
  const skip = (batch - 1) * BATCH_SIZE;
  const args = await getCreatorArgs(config, first, skip);

  console.log(`Migrating ${args.creatorAddresses.length} creators ...`);
  const tx = await contract.migrateCreator(args.creatorAddresses, args.creatorNames);
  await tx.wait();
  console.log(`Migrations complete`);
};

const migrate = async () => {
  const contract = await intializeContract(config);
  for (let i = 0; i < EPOCHS; i++) {
    try {
      await migrateCreators(contract, config, i + 1);
    } catch (err) {
      console.log(`Error with batch ${i + 1}`);
      console.log(err);
    }
  }
};

const verifyCreators = async () => {
  const first = TOTAL_CREATORS;
  const skip = 0;

  const args = await getCreatorArgs(config, first, skip);
  const contract = await intializeContract(config);
  const tokenContract = await ethers.getContractAt("CliptoToken", "");
  const pending: any[] = [];

  const promises = args.creatorAddresses.map(async (creator, index) => {
    const onChainCreator = await contract.getCreator(creator);

    if (onChainCreator === constants.NULL_ADDR) {
      console.log(`Creator ${creator} was not migrated`);
      pending.push(creator);
    }

    const name = await tokenContract.attach(onChainCreator).name();
    const owner = await tokenContract.attach(onChainCreator).owner();

    console.log(name, args.creatorNames[index]);
    console.log(owner, args.creatorAddresses[index]);
    console.log("\n");
  });

  await Promise.all(promises);
  console.log("Pending creators");
  console.log(pending);
};

const verify = async () => {
  try {
    await verifyCreators();
  } catch (err) {
    console.log(err);
  }
};

// To migrate all data
migrate().catch((err) => console.log(err));

// To verify all data
// verify().catch((err) => console.log(err));
