// SPDX-License-Identifier: GPL-3.0
//
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
    uint256 public constant MAX_STALE_THRESHOLD_SECONDS = 86_400; // 1 day

    /// @notice Maximum age of price data before it's considered stale
    /// @dev Time in seconds after which price data is considered invalid
    uint256 public staleThresholdSeconds;

    /// @notice The price feed identifier used in DIA Oracle
    /// @dev Format should be "TOKEN/DENOMINATION" (e.g., "KLIMA/USD")
    string public key;

    /// @notice The keccak256 hash of the price feed identifier
    /// @dev Format should be "TOKEN/DENOMINATION" (e.g., "KLIMA/USD")
    bytes32 public keyHash;

    /// @notice Mapping of price feed keys to their authorized updaters
    mapping(bytes32 => address) public oracleUpdaters;

    /// @notice Emitted when the stale threshold is updated
    /// @param _threshold New threshold value in seconds
    /// @param _setter Address of the person setting the threshold
    event NewStaleThreshold(uint256 _threshold, address _setter);

    /// @notice Emitted when a new authorized updater is set
    /// @param _updater Address of the authorized updater
    /// @param _key The price feed identifier
    /// @param _setter Address of the person setting the updater
    event NewOracleUpdater(address _updater, string _key, address _setter);

    /// @notice Emitted when a new key is set
    /// @param _key The new key
    /// @param _setter Address of the person setting the key
    event NewKeySet(string _key, address _setter);

    error InvalidOracleAddress();
    error InvalidStaleThreshold();
    error NotAuthorized();
    error InvalidPrice();
    error InvalidKey();
    error PriceStale();

    /// @notice Initializes the relayer with a specific DIA Oracle feed
    /// @param _diaOracle Address of the DIA Oracle V2 contract
    /// @param _key The price feed identifier (e.g., "KLIMA/USD")
    /// @param _staleThreshold Maximum age of price data in seconds
    /// @param _oracleUpdater Address of the authorized updater
    /// @dev Validates inputs and sets up initial state
    constructor(
        address _diaOracle,
        string memory _key,
        uint256 _staleThreshold,
        address _oracleUpdater
    ) {
        if (_diaOracle == address(0)) revert InvalidOracleAddress();
        if (_staleThreshold == 0) revert InvalidStaleThreshold();
        if (_staleThreshold > MAX_STALE_THRESHOLD_SECONDS) revert InvalidStaleThreshold();
        if (_oracleUpdater == address(0)) revert InvalidOracleAddress();

        DIA_ORACLE = IDIAOraclev2(_diaOracle);
        key = _key;
        keyHash = keccak256(_key);
        staleThresholdSeconds = _staleThreshold;
        oracleUpdaters[keyHash] = _oracleUpdater;

        emit NewKeySet(_key, msg.sender);
        emit NewOracleUpdater(_oracleUpdater, _key, msg.sender);
        emit NewStaleThreshold(_staleThreshold);
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
        if (_value == 0) revert InvalidPrice();

        // Convert the price to 18 decimals (DIA uses 8 decimals)
        _price = uint256(_value) * 10 ** 10;

        // Check if the price is stale
        _validity = block.timestamp <= uint256(_timestamp) + staleThresholdSeconds;

        return (_price, _validity);
    }

    /// @notice Reads the current price, reverting if invalid
    /// @dev This is a convenience wrapper around getResultWithValidity
    /// @return _price The current price with 18 decimal precision
    /// @custom:throws If price is stale or invalid
    function read() external view returns (uint256 _price) {
        bool _validity;
        (_price, _validity) = this.getResultWithValidity();
        if (!_validity) revert PriceStale();
        return _price;
    }

    /// @notice Returns the symbol/key of this price feed
    /// @return _symbol The price feed identifier (e.g., "KLIMA/USD")
    function symbol() external view returns (string memory _symbol) {
        return key;
    }

    /// @notice Sets the price feed identifier
    /// @param _key The new price feed identifier (e.g., "KLIMA/USD")
    function setKey(string memory _key) external {
        if (oracleUpdaters[keyHash] != msg.sender) revert NotAuthorized();
        if (_key == "") revert InvalidKey();

        key = _key;
        keyHash = keccak256(_key);

        // Same authorized updater can update the new key
        oracleUpdaters[keyHash] = msg.sender;
        
        emit NewKeySet(_key, msg.sender);
    }

    /// @notice Updates the stale threshold for price data
    /// @param _newThreshold The new threshold value in seconds
    /// @dev Only callable by an authorized updater
    function setStaleThreshold(uint256 _newThreshold) external {
        if (oracleUpdaters[keyHash] != msg.sender) revert NotAuthorized();
        if (_newThreshold == 0) revert InvalidStaleThreshold();
        if (_newThreshold > MAX_STALE_THRESHOLD_SECONDS) revert InvalidStaleThreshold();

        // Update the stale threshold
        staleThresholdSeconds = _newThreshold;
        emit NewStaleThreshold(_newThreshold, msg.sender);
    }

    /// @notice Updates the authorized updater for this price feed
    /// @param _oracleUpdater The new authorized updater address
    /// @dev Only callable by an authorized updater
    function setOracleUpdater(address _oracleUpdater) external {
        if (oracleUpdaters[keyHash] != msg.sender) revert NotAuthorized();
        if (_oracleUpdater == address(0)) revert InvalidOracleAddress();

        // Update the authorized updater
        oracleUpdaters[keyHash] = _oracleUpdater;
        emit NewOracleUpdater(_oracleUpdater, key, msg.sender);
    }
}
