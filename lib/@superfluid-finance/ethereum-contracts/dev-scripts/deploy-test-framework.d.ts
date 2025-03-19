/**
 * {DEPRECATED}
 * Deploys Superfluid Framework in local testing environments.
 *
 * NOTE: This only works with Hardhat + ethers v5.
 * @returns SuperfluidFrameworkDeployer Contract object
 */
export function deployTestFramework(): Promise<{
    frameworkDeployer: any;
}>;
export function deployTestFrameworkWithEthersV5(ethersV5Signer: any): Promise<{
    frameworkDeployer: any;
}>;
export function deployTestFrameworkWithEthersV6(privateKey: any, provider: any): Promise<{
    frameworkDeployer: any;
}>;
export function printProtocolFrameworkAddresses(framework: any): {
    Host: any;
    CFAv1: any;
    IDAv1: any;
    SuperTokenFactory: any;
    SuperTokenLogic: any;
    Resolver: any;
    SuperfluidLoader: any;
    CFAv1Forwarder: any;
};
//# sourceMappingURL=deploy-test-framework.d.ts.map