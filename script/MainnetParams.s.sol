// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import '@script/Params.s.sol';

abstract contract MainnetParams is Contracts, Params {
  address constant BASE_ADMIN_SAFE = 0xBdAF85b594C7Cb802ECBBcF0C64e0959b6Cf3629;

  // --- Mainnet Params ---
  function _getEnvironmentParams() internal override {
    // Setup delegated collateral joins
    delegatee[OP] = address(azosDelegate);
    delegatee[USDGLO] = address(azosDelegate);

    _safeEngineParams = ISAFEEngine.SAFEEngineParams({
      safeDebtCeiling: 55_000 * WAD, // WAD
      globalDebtCeiling: 200_000 * RAD // initially disabled
    });

    _accountingEngineParams = IAccountingEngine.AccountingEngineParams({
      surplusIsTransferred: 1, // surplus is not auctioned
      surplusDelay: 1 days,
      popDebtDelay: 14 days,
      disableCooldown: 3 days,
      surplusAmount: 42_000 * RAD, // 42k AZUSD
      surplusBuffer: 100_000 * RAD, // 100k AZUSD
      debtAuctionMintedTokens: 10_000 * WAD, // 10k AZOS
      debtAuctionBidSize: 10_000 * RAD // 10k AZUSD
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
      bidReceiver: governor,
      recyclingPercentage: 0 // 100% is burned
    });

    _liquidationEngineParams = ILiquidationEngine.LiquidationEngineParams({
      onAuctionSystemCoinLimit: 10_000_000 * RAD, // 10M AZUSD
      saviourGasLimit: 10_000_000 // 10M gas
    });

    _stabilityFeeTreasuryParams = IStabilityFeeTreasury.StabilityFeeTreasuryParams({
      treasuryCapacity: 1_000_000 * RAD, // 1M AZUSD
      pullFundsMinThreshold: 0, // no threshold
      surplusTransferDelay: 1 days
    });

    _taxCollectorParams = ITaxCollector.TaxCollectorParams({
      primaryTaxReceiver: address(accountingEngine),
      globalStabilityFee: RAY, // no global SF
      maxStabilityFeeRange: RAY - MINUS_0_5_PERCENT_PER_HOUR, // +- 0.5% per hour
      maxSecondaryReceivers: 5
    });

    delete _taxCollectorSecondaryTaxReceiver; // avoid stacking old data on each push

    _taxCollectorSecondaryTaxReceiver.push(
      ITaxCollector.TaxReceiver({
        receiver: address(stabilityFeeTreasury),
        canTakeBackTax: true, // [bool]
        taxPercentage: 0.05e18 // 5%
      })
    );

    _taxCollectorSecondaryTaxReceiver.push(
      ITaxCollector.TaxReceiver({
        receiver: BASE_ADMIN_SAFE,
        canTakeBackTax: true, // [bool]
        taxPercentage: 0.21e18 // 21%
      })
    );

    // --- PID Params ---

    _oracleRelayerParams = IOracleRelayer.OracleRelayerParams({
      redemptionRateUpperBound: PLUS_950_PERCENT_PER_YEAR, // +950%/yr
      redemptionRateLowerBound: MINUS_90_PERCENT_PER_YEAR // -90%/yr
    });

    _pidControllerParams = IPIDController.PIDControllerParams({
      perSecondCumulativeLeak: HALF_LIFE_30_DAYS, // 0.999998e27
      noiseBarrier: 0.995e18, // 0.5%
      feedbackOutputLowerBound: -int256(RAY - 1), // unbounded
      feedbackOutputUpperBound: RAD, // unbounded
      integralPeriodSize: 1 hours
    });

    _pidControllerGains = IPIDController.ControllerGains({
      kp: int256(PROPORTIONAL_GAIN), // imported from RAI
      ki: int256(INTEGRAL_GAIN) // imported from RAI
    });

    _pidRateSetterParams = IPIDRateSetter.PIDRateSetterParams({updateRateDelay: 1 hours});

    // --- Global Settlement Params ---
    _globalSettlementParams = IGlobalSettlement.GlobalSettlementParams({shutdownCooldown: 3 days});
    _postSettlementSAHParams = IPostSettlementSurplusAuctionHouse.PostSettlementSAHParams({
      bidIncrease: 1.01e18, // +1 %
      bidDuration: 3 hours,
      totalAuctionLength: 1 days
    });

    // --- Collateral Specific Params ---
    // ------------ USDGLO ------------
    _safeEngineCParams[USDGLO] = ISAFEEngine.SAFEEngineCollateralParams({
      debtCeiling: 40_000 * RAD, // 40k AZUSD
      debtFloor: 150 * RAD // 150 HAI
    });

    _oracleRelayerCParams[USDGLO] = IOracleRelayer.OracleRelayerCollateralParams({
      oracle: delayedOracle[USDGLO],
      safetyCRatio: 1.11e27, // 111%
      liquidationCRatio: 1.07e27 // 107%
    });

    _taxCollectorCParams[USDGLO].stabilityFee = PLUS_5_PERCENT_PER_YEAR; // 5%/yr

    _liquidationEngineCParams[USDGLO] = ILiquidationEngine.LiquidationEngineCollateralParams({
      collateralAuctionHouse: address(collateralAuctionHouse[USDGLO]),
      liquidationPenalty: 1.05e18, // 5%
      liquidationQuantity: 50_000 * RAD // 50k AZUSD
    });

    _collateralAuctionHouseParams[USDGLO] = ICollateralAuctionHouse.CollateralAuctionHouseParams({
      minimumBid: 100 * WAD, // 100 AZUSD
      minDiscount: 1e18, // no discount
      maxDiscount: 0.9e18, // -10%
      perSecondDiscountUpdateRate: MINUS_10_PERCENT_IN_2_HOURS_CORRECT // -10% / 2hs
    });

    // ------------ HLSP ------------
    _safeEngineCParams[HLSP] = ISAFEEngine.SAFEEngineCollateralParams({
      debtCeiling: 60_000 * RAD, // 60k AZUSD
      debtFloor: 150 * RAD // 150 HAI
    });

    _oracleRelayerCParams[HLSP] = IOracleRelayer.OracleRelayerCollateralParams({
      oracle: delayedOracle[HLSP],
      safetyCRatio: 1.11e27, // 111%
      liquidationCRatio: 1.07e27 // 107%
    });

    _taxCollectorCParams[HLSP].stabilityFee = PLUS_5_PERCENT_PER_YEAR; // 2%/yr

    _liquidationEngineCParams[HLSP] = ILiquidationEngine.LiquidationEngineCollateralParams({
      collateralAuctionHouse: address(collateralAuctionHouse[HLSP]),
      liquidationPenalty: 1.05e18, // 5%
      liquidationQuantity: 50_000 * RAD // 50k AZUSD
    });

    _collateralAuctionHouseParams[HLSP] = ICollateralAuctionHouse.CollateralAuctionHouseParams({
      minimumBid: 100 * WAD, // 100 AZUSD
      minDiscount: 1e18, // no discount
      maxDiscount: 0.9e18, // -10%
      perSecondDiscountUpdateRate: MINUS_10_PERCENT_IN_2_HOURS_CORRECT // -10% / 2hs
    });

    // ------------ KLIMA ------------
    _safeEngineCParams[KLIMA] = ISAFEEngine.SAFEEngineCollateralParams({
      debtCeiling: 20_000 * RAD, // 20k AZUSD
      debtFloor: 150 * RAD // 150 AZUSD
    });

    _oracleRelayerCParams[KLIMA] = IOracleRelayer.OracleRelayerCollateralParams({
      oracle: delayedOracle[KLIMA],
      safetyCRatio: 1.50e27, // 150%
      liquidationCRatio: 1.20e27 // 120%
    });

    _taxCollectorCParams[KLIMA].stabilityFee = PLUS_5_PERCENT_PER_YEAR; // 5%/yr

    _liquidationEngineCParams[KLIMA] = ILiquidationEngine.LiquidationEngineCollateralParams({
      collateralAuctionHouse: address(collateralAuctionHouse[KLIMA]),
      liquidationPenalty: 1.05e18, // 5%
      liquidationQuantity: 50_000 * RAD // 50k AZUSD
    });

    _collateralAuctionHouseParams[KLIMA] = ICollateralAuctionHouse.CollateralAuctionHouseParams({
      minimumBid: 100 * WAD, // 100 AZUSD
      minDiscount: 1e18, // no discount
      maxDiscount: 0.85e18, // -15%
      perSecondDiscountUpdateRate: MINUS_15_PERCENT_IN_2_HOURS // -15% / 2hs
    });

    // WETH
    _safeEngineCParams[WETH] = ISAFEEngine.SAFEEngineCollateralParams({
      debtCeiling: 20_000 * RAD, // 20k AZUSD
      debtFloor: 150 * RAD // 150 AZUSD
    });

    _oracleRelayerCParams[WETH] = IOracleRelayer.OracleRelayerCollateralParams({
      oracle: delayedOracle[WETH],
      safetyCRatio: 1.50e27, // 150%
      liquidationCRatio: 1.20e27 // 120%
    });

    _taxCollectorCParams[WETH].stabilityFee = PLUS_5_PERCENT_PER_YEAR; // 5%/yr

    _liquidationEngineCParams[WETH] = ILiquidationEngine.LiquidationEngineCollateralParams({
      collateralAuctionHouse: address(collateralAuctionHouse[WETH]),
      liquidationPenalty: 1.05e18, // 5%
      liquidationQuantity: 50_000 * RAD // 50k AZUSD
    })

    // --- Governance Params ---
    _governorParams = IAzosGovernor.AzosGovernorParams({
      votingDelay: 12 hours, // 43_200
      votingPeriod: 36 hours, // 129_600
      proposalThreshold: 5000 * WAD, // 5k AZOS
      quorumNumeratorValue: 1, // 1%
      quorumVoteExtension: 1 days, // 86_400
      timelockMinDelay: 1 days // 86_400
    });

  // add weth 15k debt limit

  }
}
