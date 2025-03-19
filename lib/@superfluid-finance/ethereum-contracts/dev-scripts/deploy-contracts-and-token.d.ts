export function deployContractsAndToken(): Promise<{
    deployer: any;
    tokenDeploymentOutput: {
        wrapperSuperTokenData: {
            wrapperSuperTokenName: string;
            wrapperSuperTokenSymbol: string;
            wrapperSuperTokenAddress: any;
            wrapperSuperTokenUnderlyingToken: {
                underlyingTokenAddress: any;
                underlyingTokenSymbol: string;
                underlyingTokenName: string;
            };
        };
        nativeAssetSuperTokenData: {
            name: string;
            symbol: string;
            nativeAssetSuperTokenAddress: any;
        };
        pureSuperTokenData: {
            name: string;
            symbol: string;
            pureSuperTokenAddress: any;
        };
    };
}>;
//# sourceMappingURL=deploy-contracts-and-token.d.ts.map