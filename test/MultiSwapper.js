const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiSwapper contract", function () {
  it("should open a swap with one NFT", async function () {
    const [owner, tester] = await ethers.getSigners();

    const Swapper = await ethers.getContractFactory("MultiSwapper");
    const NFT = await ethers.getContractFactory("NFT");

    const nft = await NFT.deploy(tester.address);
    const swapper = await Swapper.deploy(nft.address);

    await nft.approve(swapper.address, [0]);

    const items = [
      {
        contractAddress: `${owner.address}`,
        standard: 0,
        tokenId: 1,
        tokenAmount: 0
      },
      {
        contractAddress: `${owner.address}`,
        standard: 0,
        tokenId: 0,
        tokenAmount: 0
      },
      {
        contractAddress: `${owner.address}`,
        standard: 0,
        tokenId: 1,
        tokenAmount: 0
      }
    ]

    // { value: ethers.utils.parseEther("5") }
    await swapper.openSwap([ethers.utils.parseEther("0.1"), 1, 0, owner.address, tester.address, "0"], items, items, { value: ethers.utils.parseEther("0.1") });
    // .to.emit(swapper, 'Opened')
    // .withArgs(owner.address, [nft.address], [0]);
  });

  it("should close swap with three nfts (721) from party one, and 1 ETH/MATIC from counterparty", async function () {
    const [owner, tester] = await ethers.getSigners();

    const Swapper = await ethers.getContractFactory("MultiSwapper");
    const NFT = await ethers.getContractFactory("NFT");

    const nft = await NFT.deploy(tester.address);
    const swapper = await Swapper.deploy(nft.address);

    await nft.setApprovalForAll(swapper.address, true);

    const items = [
      {
        contractAddress: `${nft.address}`,
        standard: 1,
        tokenId: 0,
        tokenAmount: 0
      },
      {
        contractAddress: `${nft.address}`,
        standard: 1,
        tokenId: 1,
        tokenAmount: 0
      },
      {
        contractAddress: `${nft.address}`,
        standard: 1,
        tokenId: 2,
        tokenAmount: 0
      }
    ]

    const blank = [
      {
        contractAddress: "0x0000000000000000000000000000000000000000",
        standard: 0,
        tokenId: 0,
        tokenAmount: 0
      }
    ]

    expect(await nft.balanceOf(owner.address)).to.equal(3);

    // { value: ethers.utils.parseEther("5") }
    await expect(swapper.openSwap([0, ethers.utils.parseEther("1"), 0, owner.address, tester.address, "0"], items, blank))
    .to.emit(swapper, 'Opened')
    .withArgs(owner.address, tester.address, 0);

    await expect(swapper.connect(tester).closeSwap(0, { value: ethers.utils.parseEther("1") }))
    .to.emit(swapper, 'Closed')
    .withArgs(owner.address, tester.address, 0);

    expect(await nft.balanceOf(tester.address)).to.equal(4);
    expect(await nft.balanceOf(owner.address)).to.equal(0);
  });

  it("should close swap with no tokens from party one just one ETH, and NFTs from counterparty", async function () {
    const [owner, tester] = await ethers.getSigners();

    const Swapper = await ethers.getContractFactory("MultiSwapper");
    const NFT = await ethers.getContractFactory("NFT");

    const nft = await NFT.deploy(tester.address);
    const swapper = await Swapper.deploy(nft.address);

    await nft.connect(tester).setApprovalForAll(swapper.address, true);

    const items = [
      {
        contractAddress: `${nft.address}`,
        standard: 1,
        tokenId: 3,
        tokenAmount: 0
      }
    ]

    const blank = [
      {
        contractAddress: "0x0000000000000000000000000000000000000000",
        standard: 0,
        tokenId: 0,
        tokenAmount: 0
      }
    ]

    expect(await nft.balanceOf(tester.address)).to.equal(1);

    await expect(swapper.openSwap([ethers.utils.parseEther("1"), 0, 0, owner.address, tester.address, "0"], blank, items, { value: ethers.utils.parseEther("1") }))
    .to.emit(swapper, 'Opened')
    .withArgs(owner.address, tester.address, 0);

    await expect(swapper.connect(tester).closeSwap(0))
    .to.emit(swapper, 'Closed')
    .withArgs(owner.address, tester.address, 0);

    expect(await nft.balanceOf(tester.address)).to.equal(0);
    expect(await nft.balanceOf(owner.address)).to.equal(4);
  });

  it("should only swap NFTs between both parties", async function () {
    const [owner, tester] = await ethers.getSigners();

    const Swapper = await ethers.getContractFactory("MultiSwapper");
    const NFT = await ethers.getContractFactory("NFT");

    const nft = await NFT.deploy(tester.address);
    const swapper = await Swapper.deploy(nft.address);

    await nft.connect(tester).setApprovalForAll(swapper.address, true);
    await nft.setApprovalForAll(swapper.address, true);

    const items = [
      {
        contractAddress: `${nft.address}`,
        standard: 1,
        tokenId: 3,
        tokenAmount: 0
      }
    ]

    const itemsTwo = [
      {
        contractAddress: `${nft.address}`,
        standard: 1,
        tokenId: 2,
        tokenAmount: 0
      },
      {
        contractAddress: `${nft.address}`,
        standard: 1,
        tokenId: 1,
        tokenAmount: 0
      }
    ]

    expect(await nft.balanceOf(tester.address)).to.equal(1);

    await expect(swapper.openSwap([0, 0, 0, owner.address, tester.address, "0"], itemsTwo, items))
    .to.emit(swapper, 'Opened')
    .withArgs(owner.address, tester.address, 0);

    await expect(swapper.connect(tester).closeSwap(0))
    .to.emit(swapper, 'Closed')
    .withArgs(owner.address, tester.address, 0);

    expect(await nft.balanceOf(tester.address)).to.equal(2);
    expect(await nft.balanceOf(owner.address)).to.equal(2);
  });

  // repeat tests without accounts that have trade pass

  // revert test if user on either side removes approval(s) from tokens

  // cancel swap

  // should take swap fee, and should revert if not paid

  // test with banned contract
});
