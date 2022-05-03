import * as dotenv from "dotenv";
import { ethers, upgrades } from "hardhat";
dotenv.config();

/*
 * this scripts updates the beacon implementation
 * of the clipto token, the beacon address should remain
 * same after the upgrade
 */
async function main() {
  const beaconAddress = "";
  const newImpl = "";

  if (beaconAddress.length === 0 || newImpl.length === 0) {
    throw new Error("Update the proxy address, add implementation name");
  }

  const cliptoToken = await ethers.getContractFactory(newImpl);
  let beacon = await upgrades.upgradeBeacon(beaconAddress, cliptoToken);
  beacon = await beacon.deployed();

  console.log("\n");
  console.log("Clipto token beacon old address     : ", beaconAddress);
  console.log("Clipto token beacon updated address : ", beacon.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
