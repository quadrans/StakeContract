async function main() {
  // We get the contract to deploy
  
  /*const Token = await ethers.getContractFactory("IronToken");
  console.log("Deploying Token...");
  const token = await Token.deploy(BigInt(1000000000) * BigInt(Math.pow(10, 18)));
  await token.deployed();
  console.log("Token deployed to:", token.address);*/
  
  const address = "0x07aB348180d9a199E6B72F217021d49725246f91";
  
  const Token = await ethers.getContractFactory("IronToken");
  const token = await Token.attach(address);
  
  const Locker = await ethers.getContractFactory("TokenTimelock");
  console.log("Deploying Locker...");
  const locker = await Locker.deploy(token.address, "0x8598B3E931AacB7C1C708427702fa419b0762d57", 1620813390);
  await locker.deployed();
  console.log("Locker deployed to:", locker.address);
  
  //0xF456B0f2A1aA76043095C584d03401045520784F
  
  //await token.transfer(locker.address, BigInt(1000) * BigInt(Math.pow(10, 18)));
  
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
