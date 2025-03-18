// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {ISuperToken} from '@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol';
import {ISystemCoin} from '@interfaces/tokens/ISystemCoin.sol';

/**
 * @title  ISystemCoinSuperToken
 * @notice Interface for the SystemCoin SuperToken
 * @dev    Extends the standard ISuperToken interface with SystemCoin-specific methods
 */
interface ISystemCoinSuperToken is ISuperToken {
  /**
   * @notice Returns the underlying SystemCoin token
   * @return The SystemCoin token address
   */
  function SYSTEM_COIN() external view returns (ISystemCoin);

  /**
   * @notice Initialize the SuperToken with necessary information
   * @param _name Name of the SuperToken
   * @param _symbol Symbol of the SuperToken
   */
  function initialize(string memory _name, string memory _symbol) external;
}
