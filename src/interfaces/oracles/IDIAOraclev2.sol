// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IDIAOraclev2 {
  function getValue(
    string memory _key
  ) external view returns (uint128 _value, uint128 _timestamp);
  function values(
    string memory _key
  ) external view returns (uint256 _value);
  function oracleUpdaters(
    string memory _key
  ) external view returns (address _updater);
}
