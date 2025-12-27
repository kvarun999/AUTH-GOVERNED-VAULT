// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../contracts/SecureVault.sol";
import "../contracts/AuthorizationManager.sol";

contract DeploySystem is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address signer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        AuthorizationManager auth = new AuthorizationManager(signer);
        SecureVault vault = new SecureVault(address(auth));

        console.log("AuthorizationManager deployed to:", address(auth));
        console.log("SecureVault deployed to:", address(vault));

        vm.stopBroadcast();
    }
}