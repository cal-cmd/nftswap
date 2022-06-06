async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Token = await ethers.getContractFactory("NFT");
  const Vendor = await ethers.getContractFactory("Swapper");
  const token = await Token.deploy({ gasLimit: 4000000});
  const vendor = await Vendor.deploy({ gasLimit: 4000000});

  console.log("Token address:", token.address);
  console.log("Vendor address:", vendor.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
