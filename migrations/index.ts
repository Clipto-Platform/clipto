import { expect } from "chai";
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

  console.log(`Migrating ${args.creatorAddresses.length} creators ...`);
  const tx = await contract.migrateCreator(args.creatorAddresses, args.creatorNames);
  await tx.wait();
  console.log(`Migrations complete`);
};

const migrate = async () => {
  const contract = await intializeContract(config);
  await migrateCreators(contract, config);
};

const verify = async () => {
  const args = await getCreatorArgs(config);
  const contract = await intializeContract(config);

  const promises = args.creatorAddresses.map(async (creator) => {
    const onChainCreator = await contract.getCreator(creator);

    console.log(`Fetching creator data for address ${creator} :`);
    console.log(JSON.stringify(onChainCreator, null, 3));

    expect(onChainCreator.nft).not.eql(constants.NULL_ADDR);
    expect(onChainCreator.metadataURI).to.eql("");
  });

  await Promise.all(promises);
};

// To migrate all data
// migrate().catch((err) => console.log(err));

// To verify all data
// verify().catch((err) => console.log(err));
