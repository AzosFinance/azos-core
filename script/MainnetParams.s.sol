// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import '@script/Params.s.sol';

abstract contract MainnetParams is Contracts, Params {
  // --- Mainnet Params ---
  address constant OP_MAINNET_ADMIN_SAFE = 0xAABa8e3c6FCa6FD8d5a85C4C8D47175a2c1D7478;
  address constant OP_WETH = 0x4200000000000000000000000000000000000006;
  address constant OP_WSTETH = 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb;
  address constant OP_OPTIMISM = 0x4200000000000000000000000000000000000042;

  address constant OP_CHAINLINK_SEQUENCER_UPTIME_FEED = 0x371EAD81c9102C9BF4874A9075FFFf170F2Ee389;
  address constant OP_CHAINLINK_ETH_USD_FEED = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
  address constant OP_CHAINLINK_WSTETH_ETH_FEED = 0x524299Ab0987a7c4B3c8022a35fcF824a970f5b6;
  address constant OP_CHAINLINK_OP_USD_FEED = 0x0D276FC14719f9292D5C1eA2198673d1f4269246;

  address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

  function _getEnvironmentParams() internal override {
    _safeEngineParams = ISAFEEngine.SAFEEngineParams({
      safeDebtCeiling: 10_000 * WAD, // 10000 WAD
      globalDebtCeiling: 55_000_000 * RAD // initially with 55M RAD
    });

    _accountingEngineParams = IAccountingEngine.AccountingEngineParams({
      surplusIsTransferred: 0, // surplus is auctioned
      surplusDelay: 1 days,
      popDebtDelay: 0,
      disableCooldown: 3 days,
      surplusAmount: 42_000 * RAD, // 42k AZUSD
      surplusBuffer: 100_000 * RAD, // 100k AZUSD
      debtAuctionMintedTokens: 10_000 * WAD, // 10k KITE
      debtAuctionBidSize: 1000 * RAD // 1k AZUSD
    });

    _debtAuctionHouseParams = IDebtAuctionHouse.DebtAuctionHouseParams({
      bidDecrease: 1.025e18, // -2.5 %
      amountSoldIncrease: 1.5e18, // +50 %
      bidDuration: 3 hours,
      totalAuctionLength: 2 days
    });

    _surplusAuctionHouseParams = ISurplusAuctionHouse.SurplusAuctionHouseParams({
      bidIncrease: 1.01e18, // +1 %
      bidDuration: 6 hours,
      totalAuctionLength: 1 days,
      bidReceiver: OP_MAINNET_ADMIN_SAFE,
      recyclingPercentage: 0 // 100% is burned
    });

    _liquidationEngineParams = ILiquidationEngine.LiquidationEngineParams({
      onAuctionSystemCoinLimit: 10_000_000 * RAD, // 10M AZUSD
      saviourGasLimit: 10_000_000 // 10M gas
    });

    _oracleRelayerParams = IOracleRelayer.OracleRelayerParams({redemptionRate: RAY, redemptionPrice: RAY});

    _taxCollectorParams = ITaxCollector.TaxCollectorParams({primaryTaxReceiver: address(stabilityFeeTreasury)});

    _stabilityFeeTreasuryParams = IStabilityFeeTreasury.StabilityFeeTreasuryParams({
      treasuryCapacity: 1_000_000 * RAD, // 1M AZUSD
      pullFundsMinThreshold: 0, // no threshold
      surplusTransferDelay: 1 days
    });

    _globalSettlementParams = IGlobalSettlement.GlobalSettlementParams({shutdownCooldown: 1 days});

    _postSettlementSAHParams = IPostSettlementSurplusAuctionHouse.PostSettlementSAHParams({
      bidIncrease: 1.01e18, // +1 %
      bidDuration: 6 hours,
      totalAuctionLength: 1 days
    });

    _governorParams = IAzosGovernor.AzosGovernorParams({
      votingDelay: 1,
      votingPeriod: 50 days / 12, // HOURS
      proposalThreshold: 100e18,
      quorum: 40,
      timelock: address(0)
    });

    _pidControllerGains = IPIDController.ControllerGains({Kp: PROPORTIONAL_GAIN, Ki: INTEGRAL_GAIN});

    _pidControllerParams = IPIDController.PIDControllerParams({
      perSecondCumulativeLeak: 999_997_208_243_937_652_252_849_536, // -1%/h (capped, if above deadband)
      integralPeriodSize: 1 hours,
      noiseBarrier: 0.999e18, // -0.1%
      feedbackOutputLowerBound: 999_999_403_010_509_949_429_565_376, // -50% per year
      feedbackOutputUpperBound: 1_000_000_806_542_030_018_272_359_338, // +100% per year
      bound: 10**23 // +/-10% compared to the current redemption price
    });

    _pidRateSetterParams = IPIDRateSetter.PIDRateSetterParams({updateRateDelay: 3 hours});

    /// --- Collateral ---
    bytes32[] memory _collateralList = new bytes32[](3);
    _collateralList[0] = WETH;
    _collateralList[1] = WSTETH;
    _collateralList[2] = OP;

    for (uint256 _i; _i < _collateralList.length; _i++) {
      bytes32 _cType = _collateralList[_i];

      _safeEngineCParams[_cType] = ISAFEEngine.SAFEEngineCollateralParams({
        debtCeiling: 10_000_000 * RAD, // 10M AZUSD
        debtFloor: 1 * RAD // 1 AZUSD
      });

      _liquidationEngineCParams[_cType] = ILiquidationEngine.LiquidationEngineCollateralParams({
        collateralAuctionHouse: address(collateralAuctionHouse[_cType]),
        liquidationPenalty: 1.1e18, // 10%
        liquidationQuantity: 1000 * RAD // 1000 AZUSD
      });

      _collateralAuctionHouseParams[_cType] = ICollateralAuctionHouse.CollateralAuctionHouseParams({
        minimumBid: WAD, // 1 AZUSD
        minDiscount: WAD, // no discount
        maxDiscount: 0.9e18, // -10%
        perSecondDiscountUpdateRate: MINUS_0_5_PERCENT_PER_HOUR, // -0.5%/hour
        lowerCollateralDeviation: 0.9e18, // -10%
        upperCollateralDeviation: 1.1e18, // +10%
        minimumBidBump: 1.01e18 // 1%
      });

      _oracleRelayerCParams[_cType] = IOracleRelayer.OracleRelayerCollateralParams({
        oracle: address(delayedOracle[_cType]),
        safetyCRatio: 1.45e27, // 145%
        liquidationCRatio: 1.4e27 // 140%
      });

      _taxCollectorCParams[_cType] = ITaxCollector.TaxCollectorCollateralParams({
        // NOTE: We need to compute ln(1 + X%) / seconds_in_a_year to get the correct value for X% ANNUAL interest
        // bc -l <<< 'scale=27; e( l(1.005)/(60 * 60 * 24 * 365) )'
        // This results in 1.000000000158153903837946258
        // For a 0.5% stability fee, the value we input is
        // 1.000000000158153903837946258 * 10 ^ 27 - 10 ^ 27 = 158153903837946258
        // We add the 10 ^ 27 in _modifyParameters directly
        stabilityFee: RAY
      });
    }

    // Set specific parameters for WETH
    _oracleRelayerCParams[WETH].liquidationCRatio = 1.35e27; // 135%
    _taxCollectorCParams[WETH].stabilityFee = RAY + 154714e9; // + 0.5%/yr

    // Set specific parameters for WSTETH
    _oracleRelayerCParams[WSTETH].liquidationCRatio = 1.35e27; // 135%
    _taxCollectorCParams[WSTETH].stabilityFee = RAY + 309427e9; // + 1.0%/yr

    // Set specific parameters for OP
    _oracleRelayerCParams[OP].liquidationCRatio = 1.55e27; // 155%
    _taxCollectorCParams[OP].stabilityFee = RAY + 927854e9; // + 3.0%/yr
  }
}
