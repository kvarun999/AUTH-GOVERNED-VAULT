// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract AuthorizationManager {
    using ECDSA for bytes32;

    bytes32 private constant WITHDRAWAL_TYPEHASH = 
        keccak256("Withdrawal(address vault,address recipient,uint256 amount,uint256 nonce)");

    bytes32 private immutable DOMAIN_SEPARATOR;
    address public immutable AUTHORIZED_SIGNER;

    mapping(uint256 => bool) public usedNonces;

    event AuthorizationConsumed(uint256 indexed nonce, address indexed recipient);

    constructor(address _signer) {
        // Ensure the signer is a valid address
        require(_signer != address(0), "Invalid signer address");
        AUTHORIZED_SIGNER = _signer;
        
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("SecureVaultSystem")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external returns (bool) {
        // Nonce check prevents Replay Attacks
        require(!usedNonces[nonce], "Nonce already used");
        
        bytes32 structHash = keccak256(
            abi.encode(WITHDRAWAL_TYPEHASH, vault, recipient, amount, nonce)
        );

        bytes32 digest = MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, structHash);
        address signer = digest.recover(signature);

        require(signer == AUTHORIZED_SIGNER, "Invalid signature");

        // Effect: Mark nonce as used BEFORE returning to prevent re-entry logic
        usedNonces[nonce] = true;
        emit AuthorizationConsumed(nonce, recipient);

        return true;
    }
}