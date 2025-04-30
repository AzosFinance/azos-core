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

/// @title DIA Oracle V2 Interface
/// @notice Interface for interacting with DIA's decentralized oracle network
/// @dev All prices are expected to be returned with 8 decimals of precision
interface IDIAOraclev2 {
  /// @notice Retrieves the latest price and timestamp for a given asset pair
  /// @param _key The identifier for the price feed (e.g., "KLIMA/USD")
  /// @return _value The price value with 8 decimals of precision
  /// @return _timestamp The Unix timestamp when the price was last updated
  function getValue(
    string memory _key
  ) external view returns (uint128 _value, uint128 _timestamp);

  /// @notice Gets the current price value without timestamp
  /// @param _key The identifier for the price feed
  /// @return _value The current price value with 8 decimals of precision
  function values(
    string memory _key
  ) external view returns (uint256 _value);

  /// @notice Returns the authorized updater address for a specific price feed
  /// @param _key The identifier for the price feed
  /// @return _updater The address authorized to update this price feed
  function oracleUpdaters(
    string memory _key
  ) external view returns (address _updater);
}
