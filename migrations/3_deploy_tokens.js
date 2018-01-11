var tokenInfo               = require("./config/tokens.js");
var erc223TokenInfo         = require("./config/erc223_tokens.js");
var Bluebird                = require("bluebird");
var _                       = require("lodash");
var DummyToken              = artifacts.require("./test/DummyToken");
var DummyERC223Token        = artifacts.require("./test/DummyERC223Token");
var TokenRegistry           = artifacts.require("./TokenRegistry");

module.exports = function(deployer, network, accounts) {
  if (network === "live") {
    // ignore
  } else {
    var devTokenInfos = tokenInfo.development;
    var dummyErc223TokenInfos = erc223TokenInfo.development;
    var totalSupply = 1e+26;
    deployer.then(() => {
      return TokenRegistry.deployed();
    }).then((tokenRegistry) => {
      return Bluebird.each(devTokenInfos.map(token => DummyToken.new(
        token.name,
        token.symbol,
        token.decimals,
        totalSupply,
      )), _.noop).then(dummyTokens => {
        return Bluebird.each(dummyTokens.map((tokenContract, i) => {
          var token = devTokenInfos[i];
          return tokenRegistry.registerToken(tokenContract.address, token.symbol);
        }), _.noop);
      });
    });

    deployer.then(() => {
      return TokenRegistry.deployed();
    }).then((tokenRegistry) => {
      return Bluebird.each(dummyErc223TokenInfos.map(token => DummyERC223Token.new(
        token.name,
        token.symbol,
        token.decimals,
        totalSupply,
      )), _.noop).then(dummyErc223Tokens => {
        return Bluebird.each(dummyErc223Tokens.map((tokenContract, i) => {
          var token = dummyErc223TokenInfos[i];
          return tokenRegistry.registerStandardToken(tokenContract.address, token.symbol, 1);
        }), _.noop);
      });
    });
  }

};
