const { expect } = require("chai");

describe("NFT contract", function () {
  it("should mint token to deployer", async function () {
    const [owner] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("NFT");

    const hardhatToken = await Token.deploy(owner.address);
    
    expect(await hardhatToken.ownerOf(0)).to.equal(owner.address);
  });
});
