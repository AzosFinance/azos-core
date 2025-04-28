// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {IDIAOraclev2} from '@interfaces/oracles/IDIAOracleV2.sol';

/**
 * @title  DIARelayerV2
 * @notice This contract relays prices from DIA Oracle V2
 */
contract DIARelayerV2 is IBaseOracle {
  // --- Immutable Variables ---
  IDIAOraclev2 public immutable DIA_ORACLE;
  uint256 public immutable STALE_THRESHOLD;
  string public key;

  // --- State Variables ---
  mapping(bytes32 => uint256) public values;
  mapping(bytes32 => uint256) public timestamps;
  mapping(bytes32 => address) public oracleUpdaters;

  // --- Events ---
  event NewStaleThreshold(uint256 _threshold);

  /**
   * @param  _diaOracle The address of the DIA Oracle V2 contract
   * @param  _key The key for the DIA price feed (e.g., 'WBTC/USD')
   * @param  _staleThreshold The threshold in seconds after which the price is considered stale
   */
  constructor(address _diaOracle, string memory _key, uint256 _staleThreshold) {
    require(_diaOracle != address(0), 'Invalid oracle address');
    require(_staleThreshold > 0, 'Invalid stale threshold');
    DIA_ORACLE = IDIAOraclev2(_diaOracle);
    STALE_THRESHOLD = _staleThreshold;
    oracleUpdaters[keccak256(abi.encodePacked(_key))] = msg.sender;
  }

  /// @inheritdoc IBaseOracle
  function getResultWithValidity() external view returns (uint256 _price, bool _validity) {
    uint128 _value;
    uint128 _timestamp;
    (_value, _timestamp) = DIA_ORACLE.getValue(key);

    // Check if the price is valid (non-zero)
    require(_value > 0, 'Invalid price');

    // Convert the price to 18 decimals (DIA uses 8 decimals)
    _price = uint256(_value) * 10 ** 10;

    // Check if the price is stale
    _validity = block.timestamp <= uint256(_timestamp) + STALE_THRESHOLD;

    return (_price, _validity);
  }

  /// @inheritdoc IBaseOracle
  function read() external view returns (uint256 _price) {
    bool _validity;
    (_price, _validity) = this.getResultWithValidity();
    require(_validity, 'Price is stale');
    return _price;
  }

  /// @inheritdoc IBaseOracle
  function symbol() external view returns (string memory _key) {
    return key;
  }
}
