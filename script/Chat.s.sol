// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";
import { Chat } from "../src/Chat.sol";

contract ChatScript is Script {
  function setUp() public { }

  function run() public {
    vm.startBroadcast();

    new Chat(msg.sender);

    vm.stopBroadcast();
  }
}
