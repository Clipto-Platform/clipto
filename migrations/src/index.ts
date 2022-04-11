import { intializeContract } from "./blockchain";
import * as constants from "./constants";
import { getCreatorArgs, getRequestArgs } from "./entity";
import { Config } from "./types";

const functionSignature = [
  "function migrateCreator(address [], address [], string [])",
  "function migrateRequest(address [], address [], uint256 [], bool [], string [])",
];

const config: Config = {
  rpcUrl: constants.rpcUrl,
  graphAPI: constants.graphAPI,
  contractAddress: constants.contractAddress,
  numberOfCreators: constants.numberOfCreators,
  abi: functionSignature,
};

const migrate = async () => {
  const contract = intializeContract(config);

  // creator migrations
  const creatorArgs = await getCreatorArgs(config);
  console.log(`Migrating ${creatorArgs.creatorAddresses.length} creators ...`);
  let transaction = await contract.migrateCreator(
    creatorArgs.creatorAddresses,
    creatorArgs.tokenAddresses,
    creatorArgs.jsonData,
  );

  let receipt = await transaction.wait();
  console.log(`Migration of creators complete.`);

  // request migrations
  const requestArgs = await getRequestArgs(config);
  console.log(`Migrating ${requestArgs.requesterAddresses.length} requests ...`);
  transaction = await contract.migrateRequest(
    requestArgs.creatorAddresses,
    requestArgs.requesterAddresses,
    requestArgs.amount,
    requestArgs.fulfilled,
    requestArgs.jsonData,
  );

  receipt = await transaction.wait();
  console.log(`Migration of requests complete.`);
};

migrate().catch((err) => console.log(err));