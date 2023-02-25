import { Wallet } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { Turnstile, TurnstileBond, MockDEX } from "../typechain-types";

async function main() {
  let turnstile: Turnstile;
  let turnstileBond: TurnstileBond;

  const accounts = await ethers.getSigners();
  const [deployer, ...others] = accounts;

  const Turnstile = await ethers.getContractFactory("Turnstile");
  turnstile = await Turnstile.deploy();

  await turnstile.deployed();
  await turnstile.register(others[0].address);

  const TurnstileBond = await ethers.getContractFactory("TurnstileBond");
  turnstileBond = await TurnstileBond.deploy(
    turnstile.address,
    await turnstile.getTokenId(deployer.address)
  );

  await turnstileBond.deployed();

  const MockDEX = await ethers.getContractFactory("MockDEX");

  // scenario 1 - user0 add nft(1) to start funding, user1 fund nft
  console.log("Scenario1");
  let mockDEX = await MockDEX.connect(others[0]).deploy(turnstile.address, turnstileBond.address);
  await mockDEX.deployed();
  let tokenId = await turnstile.getTokenId(mockDEX.address);
  console.log("nft generated " + tokenId);

  await turnstile.connect(others[0]).approve(
    turnstileBond.address,
    tokenId
  );

  await turnstileBond.connect(others[0]).start(
    tokenId,
    parseEther("1"),
    parseEther("10"),
    parseEther("0.1")
  );

  await turnstile.connect(deployer).distributeFees(tokenId, {
    value: parseEther("3"),
  });


  // scenario 2
  // user1
  // - add nft(2) to start funding and reaches softCap
  // -- user2 has funded
  // - does not start funding for nft(3)
  // - add nft(4) to start funding but does not reaches softCap
  // - add nft(5) to start funding and cancel
  // -- user2 has funded
  console.log("Scenario2");
  // nft(2)
  mockDEX = await MockDEX.connect(others[1]).deploy(turnstile.address, turnstileBond.address);
  await mockDEX.deployed();
  tokenId = await turnstile.getTokenId(mockDEX.address);
  console.log("nft generated " + tokenId);

  await turnstile.connect(others[1]).setApprovalForAll(
    turnstileBond.address,
    true
  );

  await turnstileBond.connect(others[1]).start(
    tokenId,
    parseEther("100"),
    parseEther("10000"),
    parseEther("0.33")
  );

  await turnstile.connect(deployer).distributeFees(tokenId, {
    value: parseEther("3"),
  });

  await turnstileBond.connect(others[2]).fund(tokenId, {value : parseEther("3")});

  await turnstileBond.connect(deployer).harvest(tokenId);
 
  // nft(3)
  mockDEX = await MockDEX.connect(others[1]).deploy(turnstile.address, turnstileBond.address);
  await mockDEX.deployed();
  tokenId = await turnstile.getTokenId(mockDEX.address);

  await turnstile.connect(deployer).distributeFees(tokenId, {
    value: parseEther("3"),
  });
  
  // nft(4)
  mockDEX = await MockDEX.connect(others[1]).deploy(turnstile.address, turnstileBond.address);
  await mockDEX.deployed();
  tokenId = await turnstile.getTokenId(mockDEX.address);

  await turnstile.connect(deployer).distributeFees(tokenId, {
    value: parseEther("3"),
  });


  await turnstileBond.connect(others[1]).start(
    tokenId,
    parseEther("2"),
    parseEther("200"),
    parseEther("0.2")
  );

  await turnstileBond.connect(others[2]).fund(tokenId, {value : parseEther("1")});
  await turnstile.connect(deployer).distributeFees(tokenId, {
    value: parseEther("3"),
  });
  

  await turnstileBond.connect(deployer).harvest(tokenId);

  await turnstile.connect(deployer).distributeFees(tokenId, {
    value: parseEther("3"),
  }); // not harvested
  
  // nft(5)
  mockDEX = await MockDEX.connect(others[1]).deploy(turnstile.address, turnstileBond.address);
  await mockDEX.deployed();
  tokenId = await turnstile.getTokenId(mockDEX.address);

  await turnstile.connect(deployer).distributeFees(tokenId, {
    value: parseEther("3"),
  });


  await turnstileBond.connect(others[1]).start(
    tokenId,
    parseEther("2"),
    parseEther("200"),
    parseEther("0.2")
  );

  await turnstileBond.connect(others[2]).fund(tokenId, {value : parseEther("1")});

  await turnstileBond.connect(others[1]).cancel(tokenId);

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
