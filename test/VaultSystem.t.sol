// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/SecureVault.sol";
import "../contracts/AuthorizationManager.sol";

contract VaultSystemTest is Test {
    SecureVault vault;
    AuthorizationManager auth;

    // Test accounts
    uint256 signerKey = 0xABC123;
    address signer = vm.addr(signerKey);
    address recipient = address(0xDE1);
    address attacker = address(0xBAD);

    function setUp() public {
        // 1. Deploy contracts
        auth = new AuthorizationManager(signer);
        vault = new SecureVault(address(auth));

        // 2. Fund the vault for testing
        vm.deal(address(vault), 100 ether);
    }

    // Helper to generate EIP-712 signatures
    function getSignature(
        uint256 pKey,
        address vlt,
        address recp,
        uint256 amt,
        uint256 nnc
    ) public view returns (bytes memory) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("SecureVaultSystem")),
                keccak256(bytes("1")),
                block.chainid,
                address(auth)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Withdrawal(address vault,address recipient,uint256 amount,uint256 nonce)"
                ),
                vlt,
                recp,
                amt,
                nnc
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pKey, digest);
        return abi.encodePacked(r, s, v);
    }

    function test_Deposit() public {
        uint256 amount = 1 ether;
        address caller = address(0xABCD);
        vm.deal(caller, amount);

        // Expect the Deposited event
        vm.expectEmit(true, false, false, true);
        emit SecureVault.Deposited(caller, amount);

        // Perform deposit
        vm.prank(caller);
        (bool success, ) = address(vault).call{value: amount}("");

        require(success, "Transfer failed");
        assertEq(address(vault).balance, 101 ether); // 100 from setUp + 1
    }

    function test_ValidWithdrawal() public {
        uint256 amount = 5 ether;
        uint256 nonce = 1;
        bytes memory sig = getSignature(
            signerKey,
            address(vault),
            recipient,
            amount,
            nonce
        );

        uint256 startBal = recipient.balance;
        vault.withdraw(payable(recipient), amount, nonce, sig);

        assertEq(recipient.balance, startBal + amount);
        assertTrue(auth.usedNonces(nonce));
    }

    function test_Fail_ReplayAttack() public {
        uint256 amount = 1 ether;
        uint256 nonce = 2;
        bytes memory sig = getSignature(
            signerKey,
            address(vault),
            recipient,
            amount,
            nonce
        );

        // First withdrawal succeeds
        vault.withdraw(payable(recipient), amount, nonce, sig);

        // Second withdrawal with same parameters must fail
        vm.expectRevert("Nonce already used");
        vault.withdraw(payable(recipient), amount, nonce, sig);
    }

    function test_Fail_WrongSigner() public {
        uint256 fakeKey = 0x111; // Not the authorized signer
        bytes memory sig = getSignature(
            fakeKey,
            address(vault),
            recipient,
            1 ether,
            3
        );

        vm.expectRevert("Invalid signature");
        vault.withdraw(payable(recipient), 1 ether, 3, sig);
    }

    function test_Fail_TamperedAmount() public {
        uint256 nonce = 4;
        // Sign for 1 ether
        bytes memory sig = getSignature(
            signerKey,
            address(vault),
            recipient,
            1 ether,
            nonce
        );

        // Attempt to withdraw 100 ether using the 1 ether signature
        vm.expectRevert("Invalid signature");
        vault.withdraw(payable(recipient), 100 ether, nonce, sig);
    }
}
