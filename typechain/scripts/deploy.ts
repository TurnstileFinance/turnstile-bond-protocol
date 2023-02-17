import { Wallet } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { Turnstile, TurnstileBond, MockDEX } from "../typechain-types";

async function main() {
  let turnstile: Turnstile;
  let turnstileBond: TurnstileBond;
  let mockDEX: MockDEX;

  const accounts = await ethers.getSigners();
  const deployer = accounts[0];
  const other = accounts[1];

  const Turnstile = await ethers.getContractFactory("Turnstile");
  turnstile = await Turnstile.deploy();

  await turnstile.deployed();
  await turnstile.register(other.address);

  const TurnstileBond = await ethers.getContractFactory("TurnstileBond");
  turnstileBond = await TurnstileBond.deploy(
    turnstile.address,
    await turnstile.getTokenId(deployer.address)
  );

  await turnstileBond.deployed();

  const MockDEX = await ethers.getContractFactory("MockDEX");
  mockDEX = await MockDEX.deploy(turnstile.address, turnstileBond.address);

  await mockDEX.deployed();

  await turnstile.approve(
    turnstileBond.address,
    await turnstile.getTokenId(mockDEX.address)
  );

  await turnstileBond.start(
    await turnstile.getTokenId(mockDEX.address),
    parseEther("1"),
    parseEther("10"),
    10
  );

  await turnstile.distributeFees(await turnstile.getTokenId(mockDEX.address), {
    value: parseEther("10"),
  });

  console.log(
    `Contracts Deployed at\n
    Turnstile: ${turnstile.address}\n
    TurnstileBond: ${turnstileBond.address}\n
    MockDEX: ${mockDEX.address}\n
    `
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
