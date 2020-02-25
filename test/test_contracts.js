const { assert } = require("chai");
const Taxicab = artifacts.require("Taxicab");
const NumerNFT = artifacts.require("NumerNFT");

let taxicab;
contract("Taxicab", () => {
  it("should initialize", async () => {
    taxicab = await Taxicab.deployed();
    console.log("Taxicab Address:", taxicab.address);
  });
});

contract("NumerNFT", accounts => {
  const [k0, k1] = accounts;
  let numerNFT;

  it("should initialize", async () => {
    numerNFT = await NumerNFT.deployed();
    console.log("NumerNFT Address:", numerNFT.address);

    await taxicab.updateNNFTContract(numerNFT.address, { from: k0 });
  });

  it("should add taxicab challenge", async () => {
    await numerNFT.addChallenge("taxicab", taxicab.address);
  });

  it("should enumeratea challenges", async () => {
    const totalChallenges = (await numerNFT.challenges()).toNumber();
    assert(totalChallenges == 1);
  });

  it("should return challenge metadata", async () => {
    const challenge = (await numerNFT.challenge("taxicab")).toNumber();
    const challengeName = await numerNFT.challengeName(1);
    const challengeAddress = await numerNFT.challengeAddress(1);
    assert(challenge == 1);
    assert(challengeName == "taxicab");
    assert(challengeAddress == taxicab.address);
  });

  it("should add taxicab rewards", async () => {
    await numerNFT.addReward(1, 3, 1, {
      from: k0,
      value: web3.utils.toWei("1.0", "ether").toString()
    });

    await numerNFT.addReward(1, 3, 2, {
      from: k0,
      value: web3.utils.toWei("2.0", "ether").toString()
    });

    const reward1 = (await numerNFT.reward(1, 3, 1)).toString();
    assert(web3.utils.fromWei(reward1, "ether") == "1");

    const reward2 = (await numerNFT.reward(1, 3, 2)).toString();
    assert(web3.utils.fromWei(reward2, "ether") == "2");
  });

  it("should catch overflow values", async () => {
    try {
      await taxicab.numerNFT(
        1,
        [
          "1552518092300708935148979488462502555256886017116696611139052038026050952686336662907088581037347755875493113158748635108709802863981643707113121982950960845650317065074935465980150216120762546482655734466972747413805569646186725375",
          "1552518092300708935148979488462502555256886017116696611139052038026050952686336662907088581037347755875493113158748635108709802863981643707113121982950960845650317065074935465980150216120762546482655734466972747413805569646186725375"
        ],
        { from: k0 }
      );
    } catch (err) {
      return 1;
    }
  });

  it("should not accept a malformed solution", async () => {
    const solution = [1, 2, 3];

    try {
      await numerNFT.solve(1, 1, solution, { from: k1 });
    } catch (err) {
      return 1;
    }
  });

  it("should not accept invalid solution: 1", async () => {
    const solution = [1, 2, 3, 4];
    await numerNFT.commit(1, 2, web3.utils.soliditySha3(...solution), {
      from: k0
    });

    const { logs } = (
      await numerNFT.solve(1, 2, solution, { from: k0 })
    ).receipt;
    assert.isEmpty(logs);
  });

  it("should not accept invalid solution: 2", async () => {
    const solution = [12, 1, 9, 10];
    await numerNFT.commit(1, 2, web3.utils.soliditySha3(...solution), {
      from: k0
    });

    const { logs } = (
      await numerNFT.solve(1, 2, solution, { from: k0 })
    ).receipt;
    assert.isEmpty(logs);
  });

  it("should not accept invalid solution: 3", async () => {
    const solution = [9, 10, 9, 10];
    await numerNFT.commit(1, 2, web3.utils.soliditySha3(...solution), {
      from: k0
    });

    const { logs } = (
      await numerNFT.solve(1, 2, solution, { from: k0 })
    ).receipt;
    assert.isEmpty(logs);
  });

  it("should not accept invalid solution: 4", async () => {
    const solution = [1, 1, 1, 1];
    await numerNFT.commit(1, 2, web3.utils.soliditySha3(...solution), {
      from: k0
    });

    console.log("Ta(1) Hash:", web3.utils.soliditySha3(...solution));

    const { logs } = (
      await numerNFT.solve(1, 2, solution, { from: k0 })
    ).receipt;
    assert.isEmpty(logs);
  });

  it("should accept valid solution: 1", async () => {
    const solution = [1, 1];
    await numerNFT.commit(1, 1, web3.utils.soliditySha3(...solution), {
      from: k0
    });

    const { logs } = (
      await numerNFT.solve(1, 1, solution, { from: k0 })
    ).receipt;
    assert.isNotEmpty(logs);
  });

  it("should accept valid solution: 2", async () => {
    const solution = [1, 12, 9, 10];
    await numerNFT.commit(1, 2, web3.utils.soliditySha3(...solution), {
      from: k0
    });

    console.log("Ta(2) Hash:", web3.utils.soliditySha3(...solution));

    const { logs } = (
      await numerNFT.solve(1, 2, solution, { from: k0 })
    ).receipt;
    assert.isNotEmpty(logs);
  });

  it("should accept valid solution: 3", async () => {
    const solution = [11, 493, 90, 492, 346, 428];
    await numerNFT.commit(1, 3, web3.utils.soliditySha3(...solution), {
      from: k0
    });

    const { logs } = (
      await numerNFT.solve(1, 3, solution, { from: k0 })
    ).receipt;
    assert.isNotEmpty(logs);

    const reward1 = (await numerNFT.reward(1, 3, 1)).toString();
    assert(web3.utils.fromWei(reward1, "ether") == "0");

    const reward2 = (await numerNFT.reward(1, 3, 2)).toString();
    assert(web3.utils.fromWei(reward2, "ether") == "2");
  });

  it("should not accept a worse solution: 3", async () => {
    const solution = [111, 522, 359, 460, 408, 423];
    await numerNFT.commit(1, 3, web3.utils.soliditySha3(...solution), {
      from: k0
    });

    const { logs } = (
      await numerNFT.solve(1, 3, solution, { from: k0 })
    ).receipt;
    assert.isEmpty(logs);
  });

  it("should accept a better solution: 3", async () => {
    const solution = [167, 436, 228, 423, 255, 414];
    await numerNFT.commit(1, 3, web3.utils.soliditySha3(...solution), {
      from: k0
    });

    const { logs } = (
      await numerNFT.solve(1, 3, solution, { from: k0 })
    ).receipt;
    assert.isNotEmpty(logs);

    const reward = (await numerNFT.reward(1, 3, 2)).toString();
    assert(web3.utils.fromWei(reward, "ether") == "0");
  });

  it("should not accept duplicate", async () => {
    const solution = [1, 12, 9, 10];

    try {
      await numerNFT.commit(1, 2, web3.utils.soliditySha3(...solution), {
        from: k0
      });
    } catch (err) {
      return 1;
    }
  });

  it("should mint NFTs", async () => {
    const totalSupply = (await numerNFT.totalSupply.call()).toNumber();
    assert(totalSupply == 4);

    const tkn1 = (await numerNFT.tokenIdToId(1)).toNumber();
    const tkn1Cid = (await numerNFT.tokenIdToCid(1)).toNumber();
    const tkn1Place = (await numerNFT.tokenIdToPlace(1)).toNumber();
    assert(tkn1 == 1 && tkn1Cid == 1 && tkn1Place == 1);

    const tkn3Place = (await numerNFT.tokenIdToPlace(3)).toNumber();
    assert(tkn3Place == 2);

    const tkn4Place = (await numerNFT.tokenIdToPlace(4)).toNumber();
    assert(tkn4Place == 1);

    const tkn4Name = await numerNFT.tokenIdToName(4);
    assert(tkn4Name == "taxicab");
  });

  it("should not update the numerNFT operator", async () => {
    try {
      await numerNFT.updateNumerNFTOperator(k0, { from: k1 });
    } catch (err) {
      return 1;
    }
  });

  it("should update the numerNFT operator", async () => {
    await numerNFT.updateNumerNFTOperator(k1, { from: k0 });
  });

  it("should not update the operator", async () => {
    try {
      await numerNFT.updateOperator(k0, { from: k1 });
    } catch (err) {
      return 1;
    }

    try {
      await taxicab.updateOperator(k0, { from: k1 });
    } catch (err) {
      return 1;
    }
  });

  it("should update the operator", async () => {
    await numerNFT.updateOperator(1, k1, { from: k0 });
    await taxicab.updateOperator(k1, { from: k0 });
  });
});
