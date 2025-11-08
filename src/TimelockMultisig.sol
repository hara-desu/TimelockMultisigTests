// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TimelockMultisig {
    uint256 constant MINIMUM_DELAY = 10;
    uint256 constant MAXIMUM_DELAY = 1 days;
    uint256 constant GRACE_PERIOD = 1 days;

    uint256 public immutable confirmationsRequired;
    address[] public owners;

    struct Transaction {
        bytes32 uid;
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }

    mapping(bytes32 => Transaction) public txs;
    mapping(bytes32 => mapping(address => bool)) public confirmations;
    mapping(bytes32 => bool) public queue;
    mapping(address => bool) public isOwner;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    event Queued(bytes32 txId);
    event Discarded(bytes32 txId);
    event Executed(bytes32 txId);

    constructor(uint256 _confirmationsRequired, address[] memory _owners) {
        require(_owners.length >= _confirmationsRequired, "Not enough owners");
        confirmationsRequired = _confirmationsRequired;
        for (uint256 i = 0; i < _owners.length; i++) {
            address nextOwner = _owners[i];
            require(nextOwner != address(0), "Zero owner");
            require(!isOwner[nextOwner], "Duplicate owner");
            isOwner[nextOwner] = true;
            owners.push(nextOwner);
        }
    }

    function addToQueue(
        address _to,
        string calldata _func,
        bytes calldata _data,
        uint256 _value,
        uint256 _timestamp
    ) external onlyOwner returns (bytes32) {
        require(
            _timestamp > block.timestamp + MINIMUM_DELAY &&
                _timestamp < block.timestamp + MAXIMUM_DELAY,
            "Invalid timestamp"
        );

        bytes32 txId = keccak256(
            abi.encode(_to, _func, _data, _value, _timestamp)
        );
        require(!queue[txId], "Already queued");
        queue[txId] = true;
        txs[txId] = Transaction({
            uid: txId,
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 0
        });

        emit Queued(txId);
        return txId;
    }

    function confirm(bytes32 _txId) external onlyOwner {
        require(queue[_txId], "Not queued");
        require(!confirmations[_txId][msg.sender], "Already confirmed");
        Transaction storage transaction = txs[_txId];
        require(!transaction.executed, "Already executed");
        confirmations[_txId][msg.sender] = true;
        transaction.confirmations++;
    }

    function execute(
        address _to,
        string calldata _func,
        bytes calldata _data,
        uint256 _value,
        uint256 _timestamp
    ) external payable onlyOwner returns (bytes memory) {
        require(block.timestamp > _timestamp, "Too early");
        require(_timestamp + GRACE_PERIOD > block.timestamp, "TX expired");

        bytes32 txId = keccak256(
            abi.encode(_to, _func, _data, _value, _timestamp)
        );
        require(queue[txId], "Not queued");

        Transaction storage transaction = txs[txId];
        require(
            transaction.confirmations >= confirmationsRequired,
            "Not enough confirmations"
        );

        delete queue[txId];
        transaction.executed = true;

        bytes memory callData;
        if (bytes(_func).length > 0) {
            callData = abi.encodePacked(bytes4(keccak256(bytes(_func))), _data);
        } else {
            callData = _data;
        }

        (bool success, bytes memory response) = _to.call{value: _value}(
            callData
        );
        require(success, "Call failed");

        emit Executed(txId);
        return response;
    }

    function cancelConfirmation(bytes32 _txId) external onlyOwner {
        require(queue[_txId], "Not queued");
        require(confirmations[_txId][msg.sender], "Not confirmed");
        Transaction storage transaction = txs[_txId];
        confirmations[_txId][msg.sender] = false;
        transaction.confirmations--;
    }

    function discard(bytes32 _txId) external onlyOwner {
        require(queue[_txId], "Not queued");
        delete queue[_txId];
        emit Discarded(_txId);
    }
}
