// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {TimelockMultisig} from "../src/TimelockMultisig.sol";

contract TimelockMultisigTest is Test {
    TimelockMultisig timelockMultisig;

    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address[] public owners;
    address[] public zero_owner_owners;

    uint16 constant CONFIRMATIONS_REQUIRED = 2;
    uint256 constant SMALL_DELAY = 5;
    uint256 constant BIG_DELAY = 2 days;
    uint256 constant DELAY = 30;
    uint256 constant SEND_VALUE = 1234000;

    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(msg.sender);

        timelockMultisig = new TimelockMultisig(CONFIRMATIONS_REQUIRED, owners);
        vm.deal(address(timelockMultisig), SEND_VALUE * 10);
    }

    /////////////////
    /* Constructor */
    /////////////////
    function testConfirmationsRequired() public {
        // Arrange
        uint256 confirmationsRequired = timelockMultisig
            .confirmationsRequired();

        // Act / Assert
        assertEq(
            confirmationsRequired,
            CONFIRMATIONS_REQUIRED,
            "Required confirmations do not match!"
        );
    }

    function testZeroAddressCannotBeAddedToOwners() public {
        // Arrange
        zero_owner_owners.push(address(0));

        // Act / Assert
        vm.expectRevert();
        new TimelockMultisig(CONFIRMATIONS_REQUIRED, zero_owner_owners);
    }

    function testDuplicateOwnerCannotBeAddedToOwners() public {
        // Arrange
        owners.push(address(0x1));

        // Act / Assert
        vm.expectRevert(bytes("Duplicate owner"));
        new TimelockMultisig(CONFIRMATIONS_REQUIRED, owners);
    }

    ////////////////
    /* AddToQueue */
    ////////////////
    function testOnlyOwnerCanAddToQueue() public {
        // Arrange
        uint256 timestamp = block.timestamp + 5;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act / Assert
        vm.expectRevert(bytes("Not an owner"));
        timelockMultisig.addToQueue(to, func, data, value, timestamp);
    }

    function testAddToQueueRevertsIfDelayIsNotEnough() public {
        // Arrange
        uint256 timestamp = block.timestamp + SMALL_DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act / Assert
        vm.prank(owner1);
        vm.expectRevert(bytes("Invalid timestamp"));
        timelockMultisig.addToQueue(to, func, data, value, timestamp);
    }

    function testAddToQueueRevertsIfDelayMoreThanAllowed() public {
        // Arrange
        uint256 timestamp = block.timestamp + BIG_DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act / Assert
        vm.prank(owner1);
        vm.expectRevert(bytes("Invalid timestamp"));
        timelockMultisig.addToQueue(to, func, data, value, timestamp);
    }

    function testAddToQueueRevertsIfTxIsAlreadyQueued() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act / Assert
        vm.prank(owner1);
        timelockMultisig.addToQueue(to, func, data, value, timestamp);
        vm.expectRevert(bytes("Already queued"));
        vm.prank(owner1);
        timelockMultisig.addToQueue(to, func, data, value, timestamp);
    }

    function testAddToQueueWorks() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);
        bytes32 inputTxId = keccak256(
            abi.encode(to, func, data, value, timestamp)
        );

        // Act
        vm.prank(owner1);
        bytes32 outputTxId = timelockMultisig.addToQueue(
            to,
            func,
            data,
            value,
            timestamp
        );

        // Assert
        assertEq(inputTxId, outputTxId, "Input TX is not equal to output TX");
    }

    /////////////
    /* Confirm */
    /////////////
    function testConfirmRevertsIfNotOwner() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act / Assert
        vm.prank(owner1);
        bytes32 txId = timelockMultisig.addToQueue(
            to,
            func,
            data,
            value,
            timestamp
        );

        vm.expectRevert(bytes("Not an owner"));
        timelockMultisig.confirm(txId);
    }

    function testConfirmRevertsIfTxNotQueued() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);
        bytes32 inputTxId = keccak256(
            abi.encode(to, func, data, value, timestamp)
        );

        // Act / Assert
        vm.prank(owner1);
        vm.expectRevert(bytes("Not queued"));
        timelockMultisig.confirm(inputTxId);
    }

    function testConfirmRevertsAlreadyConfirmed() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act / Assert
        vm.prank(owner1);
        bytes32 txId = timelockMultisig.addToQueue(
            to,
            func,
            data,
            value,
            timestamp
        );
        vm.prank(owner1);
        timelockMultisig.confirm(txId);
        vm.expectRevert(bytes("Already confirmed"));
        vm.prank(owner1);
        timelockMultisig.confirm(txId);
    }

    function testConfirmWorks() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act
        vm.prank(owner1);
        bytes32 txId = timelockMultisig.addToQueue(
            to,
            func,
            data,
            value,
            timestamp
        );
        vm.prank(owner1);
        timelockMultisig.confirm(txId);

        // Assert
        bool confirmation = timelockMultisig.confirmations(txId, owner1);
        assert(confirmation);
    }

    /////////////
    /* execute */
    /////////////
    function testExecuteFailsIfNotCalledByOwner() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act / Assert
        vm.prank(owner1);
        bytes32 txId = timelockMultisig.addToQueue(
            to,
            func,
            data,
            value,
            timestamp
        );
        vm.prank(owner1);
        timelockMultisig.confirm(txId);

        vm.expectRevert(bytes("Not an owner"));
        timelockMultisig.execute(to, func, data, value, timestamp);
    }

    function testExecuteFailsIfTooEarly() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act / Assert
        vm.prank(owner1);
        bytes32 txId = timelockMultisig.addToQueue(
            to,
            func,
            data,
            value,
            timestamp
        );
        vm.prank(owner1);
        timelockMultisig.confirm(txId);

        vm.expectRevert(bytes("Too early"));
        vm.prank(owner1);
        timelockMultisig.execute(to, func, data, value, timestamp);
    }

    function testExecuteFailsIfNotEnoughConfirmations() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act / Assert
        vm.prank(owner1);
        bytes32 txId = timelockMultisig.addToQueue(
            to,
            func,
            data,
            value,
            timestamp
        );
        vm.prank(owner1);
        timelockMultisig.confirm(txId);

        vm.warp(timestamp + 1);

        vm.expectRevert(bytes("Not enough confirmations"));
        vm.prank(owner1);
        timelockMultisig.execute(to, func, data, value, timestamp);
    }

    function testExecuteFailsIfAlreadyExecuted() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act / Assert
        vm.prank(owner1);
        bytes32 txId = timelockMultisig.addToQueue(
            to,
            func,
            data,
            value,
            timestamp
        );
        vm.prank(owner1);
        timelockMultisig.confirm(txId);
        vm.prank(owner2);
        timelockMultisig.confirm(txId);

        vm.warp(timestamp + 1);

        vm.prank(owner1);
        timelockMultisig.execute(to, func, data, value, timestamp);

        vm.expectRevert(bytes("Not queued"));
        vm.prank(owner1);
        timelockMultisig.execute(to, func, data, value, timestamp);
    }

    ////////////////////////
    /* cancelConfirmation */
    ///////////////////////
    function testCancelConfirmationFailsIfTxNotQueued() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);
        bytes32 txId = keccak256(abi.encode(to, func, data, value, timestamp));

        // Act / Assert
        vm.prank(owner1);
        vm.expectRevert(bytes("Not queued"));
        timelockMultisig.cancelConfirmation(txId);
    }

    function testCancelConfirmationFailsIfTxNotConfirmed() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act / Assert
        vm.prank(owner1);
        bytes32 txId = timelockMultisig.addToQueue(
            to,
            func,
            data,
            value,
            timestamp
        );

        vm.expectRevert(bytes("Not confirmed"));
        vm.prank(owner1);
        timelockMultisig.cancelConfirmation(txId);
    }

    function testCancelConfirmationWorks() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act / Assert
        vm.prank(owner1);
        bytes32 txId = timelockMultisig.addToQueue(
            to,
            func,
            data,
            value,
            timestamp
        );

        vm.prank(owner1);
        timelockMultisig.confirm(txId);

        vm.prank(owner1);
        timelockMultisig.cancelConfirmation(txId);

        bool confirmed = timelockMultisig.confirmations(txId, owner1);
        assert(!confirmed);
    }

    /////////////
    /* discard */
    /////////////
    function testDiscardRevertsIfTxNotQueued() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);
        bytes32 txId = keccak256(abi.encode(to, func, data, value, timestamp));

        // Act / Assert
        vm.expectRevert(bytes("Not queued"));
        vm.prank(owner1);
        timelockMultisig.discard(txId);
    }

    function testDiscardWorks() public {
        // Arrange
        uint256 timestamp = block.timestamp + DELAY;
        uint256 value = SEND_VALUE;
        bytes memory data = bytes("Hello");
        string memory func = "RandomFunc()";
        address to = address(0x4);

        // Act
        vm.prank(owner1);
        bytes32 txId = timelockMultisig.addToQueue(
            to,
            func,
            data,
            value,
            timestamp
        );
        vm.prank(owner1);
        timelockMultisig.discard(txId);
        bool queued = timelockMultisig.queue(txId);

        // Assert
        assert(!queued);
    }
}
