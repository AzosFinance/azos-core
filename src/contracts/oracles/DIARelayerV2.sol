// SPDX-License-Identifier: GPL-3.0
//                      OO
//                     OOOO
//                    OOOOOO
//                   OOO  OOO
//                 +OOO    OOO
//                ,OOO     ,OOO,
//               ~OOO       ~OOO.
//        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
//       AAAAAAAAAAAAA AZOS AAAAAAAAAAAAA
//            ZZZZZ            SSSSS
//           ZZZZZ              SSSSS   @Azos Labs 2025
//          ZZZZZ                SSSSS  @author penguin@azos.tech
//         ZZZZZ                  SSSSS
//        ZZZZZZZZZZZZZ    SSSSSSSSSSSSS
//       ZZZZZZZZZZZZZZ    SSSSSSSSSSSSSS
//
pragma solidity ^0.8.20;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {IDIAOraclev2} from '@interfaces/oracles/IDIAOracleV2.sol';

/// @title DIA Oracle V2 Relayer
/// @notice Relays and validates price data from DIA Oracle V2 while ensuring freshness and proper decimal conversion
/// @dev Implements price staleness checks and converts DIA's 8 decimal precision to 18 decimals
/// @custom:security-contact security@azos.tech
contract DIARelayerV2 is IBaseOracle {
  /// @notice The DIA Oracle V2 contract reference
  /// @dev Immutable reference to the main DIA price feed contract
  IDIAOraclev2 public immutable DIA_ORACLE;

  /// @notice Maximum age of price data before it's considered stale
  /// @dev Time in seconds after which price data is considered invalid
  uint256 public immutable STALE_THRESHOLD;

  /// @notice The price feed identifier used in DIA Oracle
  /// @dev Format should be "TOKEN/DENOMINATION" (e.g., "KLIMA/USD")
  string public key;

  /// @notice Mapping of price feed keys to their current values
  /// @dev Values are stored with 18 decimal precision
  mapping(bytes32 => uint256) public values;

  /// @notice Mapping of price feed keys to their last update timestamps
  mapping(bytes32 => uint256) public timestamps;

  /// @notice Mapping of price feed keys to their authorized updaters
  mapping(bytes32 => address) public oracleUpdaters;

  /// @notice Emitted when the stale threshold is updated
  /// @param _threshold New threshold value in seconds
  event NewStaleThreshold(uint256 _threshold);

  /// @notice Initializes the relayer with a specific DIA Oracle feed
  /// @param _diaOracle Address of the DIA Oracle V2 contract
  /// @param _key The price feed identifier (e.g., "KLIMA/USD")
  /// @param _staleThreshold Maximum age of price data in seconds
  /// @dev Validates inputs and sets up initial state
  constructor(address _diaOracle, string memory _key, uint256 _staleThreshold) {
    require(_diaOracle != address(0), 'Invalid oracle address');
    require(_staleThreshold > 0, 'Invalid stale threshold');
    DIA_ORACLE = IDIAOraclev2(_diaOracle);
    STALE_THRESHOLD = _staleThreshold;
    oracleUpdaters[keccak256(abi.encodePacked(_key))] = msg.sender;
  }

  /// @notice Retrieves the latest price and validates its freshness
  /// @dev Converts DIA's 8 decimal precision to 18 decimals and checks staleness
  /// @return _price The current price with 18 decimal precision
  /// @return _validity True if the price is fresh and valid, false otherwise
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

  /// @notice Reads the current price, reverting if invalid
  /// @dev This is a convenience wrapper around getResultWithValidity
  /// @return _price The current price with 18 decimal precision
  /// @custom:throws If price is stale or invalid
  function read() external view returns (uint256 _price) {
    bool _validity;
    (_price, _validity) = this.getResultWithValidity();
    require(_validity, 'Price is stale');
    return _price;
  }

  /// @notice Returns the symbol/key of this price feed
  /// @return _symbol The price feed identifier (e.g., "KLIMA/USD")
  function symbol() external view returns (string memory _symbol) {
    return key;
  }
}
