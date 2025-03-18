// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';
import {ISuperfluid, ISuperToken, ISuperApp, SuperAppDefinitions} from '@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol';
import {SuperAppBase} from '@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol';
import {ISystemCoinSuperToken} from '@interfaces/superfluid/ISystemCoinSuperToken.sol';
import {IConstantFlowAgreementV1} from '@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol';
import {IInstantDistributionAgreementV1} from '@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol';

/**
 * @title  SAFEHandler
 * @notice This contract is spawned to provide a unique safe handler address for each user's SAFE.
 *         It can also be registered as a Super App to interact with Superfluid streams.
 * @dev    When a new SAFE is created inside AzosSafeManager, this contract is deployed and calls the SAFEEngine to add permissions to the SAFE manager
 */
contract SAFEHandler is SuperAppBase {
  /// @notice Address of the SAFEEngine
  address public immutable safeEngine;
  
  /// @notice Address of the SAFE manager
  address public immutable safeManager;
  
  /// @notice The Superfluid host contract
  ISuperfluid public host;
  
  /// @notice The SystemCoin SuperToken
  ISystemCoinSuperToken public systemCoinSuperToken;
  
  /// @notice Indicates if this handler is registered as a Super App
  bool public isRegisteredSuperApp;

  /**
   * @dev    Grants permissions to the SAFE manager to modify the SAFE of this contract's address
   * @param  _safeEngine Address of the SAFEEngine contract
   */
  constructor(address _safeEngine) {
    safeEngine = _safeEngine;
    safeManager = msg.sender; // Set the safe manager as the caller
    ISAFEEngine(_safeEngine).approveSAFEModification(msg.sender);
  }
  
  /**
   * @notice Registers this handler as a Super App
   * @param  _host The Superfluid host contract
   * @param  _systemCoinSuperToken The SystemCoin SuperToken
   */
  function registerAsSuperApp(ISuperfluid _host, ISystemCoinSuperToken _systemCoinSuperToken) external {
    require(msg.sender == safeManager, 'SAFEHandler: Only safe manager can register');
    require(!isRegisteredSuperApp, 'SAFEHandler: Already registered');
    
    host = _host;
    systemCoinSuperToken = _systemCoinSuperToken;
    
    // Register as a super app
    uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL;
    
    _host.registerAppByFactory(
      address(this),
      configWord
    );
    
    isRegisteredSuperApp = true;
  }
  
  /**
   * @notice Callback for when a stream is created to this Super App
   * @dev    Implements the ISuperApp.beforeAgreementCreated callback
   */
  function beforeAgreementCreated(
    ISuperToken _superToken,
    address _agreementClass,
    bytes32 /*_agreementId*/,
    bytes calldata /*_agreementData*/,
    bytes calldata /*_ctx*/
  ) external view override returns (bytes memory /*cbdata*/) {
    // Only accept streams of the system coin super token
    require(address(_superToken) == address(systemCoinSuperToken), 'SAFEHandler: Unsupported token');
    
    // Only support Constant Flow Agreement
    require(
      _agreementClass == address(host.getAgreementClass(keccak256('org.superfluid-finance.agreements.ConstantFlowAgreement.v1'))),
      'SAFEHandler: Unsupported agreement'
    );
    
    return new bytes(0);
  }
  
  /**
   * @notice Callback for after a stream is created to this Super App
   * @dev    Implements the ISuperApp.afterAgreementCreated callback
   */
  function afterAgreementCreated(
    ISuperToken /*_superToken*/,
    address /*_agreementClass*/,
    bytes32 /*_agreementId*/,
    bytes calldata /*_agreementData*/,
    bytes calldata /*_cbdata*/,
    bytes calldata _ctx
  ) external override returns (bytes memory newCtx) {
    // Make sure callback is from the host
    require(msg.sender == address(host), 'SAFEHandler: Only host can call callbacks');
    
    // Just return the original context
    return _ctx;
  }
  
  /**
   * @notice Callback for before a stream is updated
   * @dev    Implements the ISuperApp.beforeAgreementUpdated callback
   */
  function beforeAgreementUpdated(
    ISuperToken _superToken,
    address _agreementClass,
    bytes32 /*_agreementId*/,
    bytes calldata /*_agreementData*/,
    bytes calldata /*_ctx*/
  ) external view override returns (bytes memory /*cbdata*/) {
    // Only accept streams of the system coin super token
    require(address(_superToken) == address(systemCoinSuperToken), 'SAFEHandler: Unsupported token');
    
    // Only support Constant Flow Agreement
    require(
      _agreementClass == address(host.getAgreementClass(keccak256('org.superfluid-finance.agreements.ConstantFlowAgreement.v1'))),
      'SAFEHandler: Unsupported agreement'
    );
    
    return new bytes(0);
  }
  
  /**
   * @notice Callback for after a stream is updated
   * @dev    Implements the ISuperApp.afterAgreementUpdated callback
   */
  function afterAgreementUpdated(
    ISuperToken /*_superToken*/,
    address /*_agreementClass*/,
    bytes32 /*_agreementId*/,
    bytes calldata /*_agreementData*/,
    bytes calldata /*_cbdata*/,
    bytes calldata _ctx
  ) external override returns (bytes memory newCtx) {
    // Make sure callback is from the host
    require(msg.sender == address(host), 'SAFEHandler: Only host can call callbacks');
    
    // Just return the original context
    return _ctx;
  }
  
  /**
   * @notice Callback for before a stream is terminated
   * @dev    Implements the ISuperApp.beforeAgreementTerminated callback
   */
  function beforeAgreementTerminated(
    ISuperToken /*_superToken*/,
    address /*_agreementClass*/,
    bytes32 /*_agreementId*/,
    bytes calldata /*_agreementData*/,
    bytes calldata /*_ctx*/
  ) external view override returns (bytes memory /*cbdata*/) {
    return new bytes(0);
  }
  
  /**
   * @notice Callback for after a stream is terminated
   * @dev    Implements the ISuperApp.afterAgreementTerminated callback
   */
  function afterAgreementTerminated(
    ISuperToken /*_superToken*/,
    address /*_agreementClass*/,
    bytes32 /*_agreementId*/,
    bytes calldata /*_agreementData*/,
    bytes calldata /*_cbdata*/,
    bytes calldata _ctx
  ) external override returns (bytes memory newCtx) {
    // Make sure callback is from the host
    require(msg.sender == address(host), 'SAFEHandler: Only host can call callbacks');
    
    // Just return the original context
    return _ctx;
  }
  
  /**
   * @notice Allows the safe manager to claim super tokens from the handler
   * @param _to The address to send the claimed tokens to
   * @param _amount The amount of tokens to claim
   */
  function claimSuperTokens(address _to, uint256 _amount) external {
    require(msg.sender == safeManager, 'SAFEHandler: Only safe manager can claim');
    systemCoinSuperToken.transfer(_to, _amount);
  }
}
