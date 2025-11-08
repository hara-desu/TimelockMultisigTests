// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {TimelockMultisig} from "../src/TimelockMultisig.sol";

contract DeployTimelockMultisig is Script {
    TimelockMultisig public timelockMultisig;
    address[] internal owners;

    function setUp() public {}

    function run() public {
        uint256 minConfirmations = 2;
        owners.push(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        owners.push(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        owners.push(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);

        vm.startBroadcast();
        timelockMultisig = new TimelockMultisig(minConfirmations, owners);
        vm.stopBroadcast();
        console2.log(
            "TimelockMultisig deployed at:",
            address(timelockMultisig)
        );
    }
}
