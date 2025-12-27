// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AuthorizationManager} from "./AuthorizationManager.sol";
// Added ReentrancyGuard for extra security layer
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SecureVault is ReentrancyGuard {
    AuthorizationManager public immutable authManager;

    event Deposited(address indexed sender, uint256 amount);
    event Withdrawn(address indexed recipient, uint256 amount);

    constructor(address _authManager) {
        // Zero-address check to prevent deployment errors
        require(_authManager != address(0), "Invalid auth manager address");
        authManager = AuthorizationManager(_authManager);
    }

    // Explicitly handle plain Ether transfers
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    // Fallback in case data is sent
    fallback() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(
        address payable recipient,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external nonReentrant { // Added nonReentrant modifier
        require(address(this).balance >= amount, "Insufficient vault balance");
        require(recipient != address(0), "Invalid recipient address");

        bool authorized = authManager.verifyAuthorization(
            address(this),
            recipient,
            amount,
            nonce,
            signature
        );
        require(authorized, "Authorization failed");

        // Interaction: Transfer happens AFTER all state checks and effects
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit Withdrawn(recipient, amount);
    }
}