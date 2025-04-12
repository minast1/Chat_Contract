// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { Chat } from "../src/Chat.sol";
import { Vm } from "forge-std/Vm.sol";

contract ChatTest is Test {
  event ChatStarted(string indexed _roomId);

  Chat public chatInstance;

  function setUp() public {
    chatInstance = new Chat(address(this));
  }

  modifier createAccount() {
    address testAddress1 = makeAddr("chatInstance");
    vm.prank(testAddress1);
    chatInstance.createAccount("user1");
    _;
  }

  function test_CreateAccount_ItRevertsIfUserNameAlreadyExists() public {
    address testAddress1 = makeAddr("chatInstance");
    vm.prank(testAddress1);
    chatInstance.createAccount("user1");
    address testAddress2 = makeAddr("chatInstance2");

    vm.startPrank(testAddress2);
    vm.expectRevert(abi.encodeWithSelector(Chat.UserNameAlreadyExists.selector, bytes32("user1")));
    chatInstance.createAccount("user1");

    vm.stopPrank();
  }

  function test_CreateAccount_ItAddsUserAccount() public {
    address testAddress1 = makeAddr("chatInstance");
    vm.prank(testAddress1);
    chatInstance.createAccount("user1");
    assert(chatInstance.existsAccount(testAddress1));
    assertEq(chatInstance.getUserName(testAddress1), "user1");
  }

  function test_GetUserName_ItReturnsTheDefaultNameProvidedByAnUser() public {
    address testAddress1 = makeAddr("chatInstance");
    vm.prank(testAddress1);
    chatInstance.createAccount("@DanteDiggs");
    assertEq(chatInstance.getUserName(testAddress1), "@DanteDiggs");
  }

  function test_AddFriend_ItRevertsIfUserAccountDoesNotExist() public {
    address testAddress1 = makeAddr("chatInstance");
    address testAddress2 = makeAddr("chatInstance2");

    vm.startPrank(testAddress1);

    vm.expectRevert(abi.encodeWithSelector(Chat.UserAccountDoesNotExist.selector, testAddress1));
    chatInstance.addFriend(testAddress2);
    vm.stopPrank();
  }

  function test_AddFriend_ItRevertsIfUserAndFriendAreTheSame() public {
    address testAddress1 = makeAddr("chatInstance");

    vm.startPrank(testAddress1);
    chatInstance.createAccount("user1");
    vm.expectRevert(abi.encodeWithSelector(Chat.CannotAddYourselfAsFriend.selector, testAddress1));
    chatInstance.addFriend(testAddress1);
    vm.stopPrank();
  }

  function test_AddFriend_ItRevertsIfUserAndFriendAreAlreadyFriends() public {
    address testAddress1 = makeAddr("chatInstance");
    address testAddress2 = makeAddr("chatInstance2");

    vm.prank(testAddress1);
    chatInstance.createAccount("user1");

    vm.prank(testAddress2);
    chatInstance.createAccount("user2");

    vm.startPrank(testAddress1);
    chatInstance.addFriend(testAddress2);

    vm.expectRevert(abi.encodeWithSelector(Chat.UserIsAlreadyAFriend.selector, testAddress2));
    chatInstance.addFriend(testAddress2);
    vm.stopPrank();
  }

  function test_AddFriend_ItAddsAUserAsAFriend() public {
    address testAddress1 = makeAddr("chatInstance");
    address testAddress2 = makeAddr("chatInstance2");

    vm.prank(testAddress1);
    chatInstance.createAccount("user1");

    vm.prank(testAddress2);
    chatInstance.createAccount("user2");

    vm.startPrank(testAddress1);
    chatInstance.addFriend(testAddress2);
    vm.stopPrank();
    assert(chatInstance.isFriend(testAddress1, testAddress2));
  }

  function test_AddFriend_ItAddsFriendWithNickname() public {
    address testAddress1 = makeAddr("chatInstance");
    address testAddress2 = makeAddr("chatInstance2");

    vm.prank(testAddress1);
    chatInstance.createAccount("user1");

    vm.prank(testAddress2);
    chatInstance.createAccount("user2");

    vm.startPrank(testAddress1);
    chatInstance.addFriend(testAddress2, "user2");
    Chat.FriendStruct[] memory friends = chatInstance.getUserFriends(testAddress1);
    vm.stopPrank();
    assertEq(friends[0]._nickname, "user2");
  }

  function test_GetUserFriends_ItReturnsListOfFriends() public {
    address testAddress1 = makeAddr("chatInstance");
    address testAddress2 = makeAddr("chatInstance2");
    address testAddress3 = makeAddr("chatInstance3");

    vm.prank(testAddress1);
    chatInstance.createAccount("user1");

    vm.prank(testAddress2);
    chatInstance.createAccount("user2");

    vm.prank(testAddress3);
    chatInstance.createAccount("user3");

    vm.startPrank(testAddress1);
    chatInstance.addFriend(testAddress2);
    chatInstance.addFriend(testAddress3);
    vm.stopPrank();
    assert(chatInstance.getUserFriends(testAddress1).length == 2);
  }

  function test_sendMessage_ItSendsAMessage() public {
    address testAddress1 = makeAddr("chatInstance");
    address friendAddress = makeAddr("chatInstance2");

    //string memory roomId;
    vm.prank(testAddress1);
    chatInstance.createAccount("user1");
    vm.prank(friendAddress);
    chatInstance.createAccount("user2");
    vm.startPrank(testAddress1);
    chatInstance.addFriend(friendAddress);
    Chat.FriendStruct[] memory myfriends = chatInstance.getUserFriends(testAddress1);
    // roomId = chatInstance.startChat(friendAddress);
    vm.stopPrank();
    vm.startPrank(testAddress1);
    chatInstance.sendMessage(myfriends[0]._roomId, "message");
    vm.stopPrank();
    assert(chatInstance.getMessagesByRoomId(myfriends[0]._roomId).length == 1);
  }

  function test_ItGeneratesUniqueRoomIds() public {
    address testAddress1 = makeAddr("chatInstance");
    address friendAddress = makeAddr("chatInstance2");

    bytes32 roomId1 = chatInstance.getRoomId(testAddress1, friendAddress);
    //bytes32 roomId2 = chatInstance.getRoomId(testAddress1, friendAddress);
    bytes32 roomId3 = chatInstance.getRoomId(friendAddress, testAddress1);
    assert(roomId1 == roomId3);
  }

  function test_ItClearsAllMessagesForARoom() public {
    address testAddress1 = makeAddr("chatInstance");
    address friendAddress = makeAddr("chatInstance2");
    vm.prank(testAddress1);
    chatInstance.createAccount("user1");
    vm.prank(friendAddress);
    chatInstance.createAccount("user2");
    vm.startPrank(testAddress1);
    chatInstance.addFriend(friendAddress);
    Chat.FriendStruct[] memory myfriends = chatInstance.getUserFriends(testAddress1);
    vm.stopPrank();
    vm.startPrank(testAddress1);
    chatInstance.sendMessage(myfriends[0]._roomId, "message");
    vm.stopPrank();
    assert(chatInstance.getMessagesByRoomId(myfriends[0]._roomId).length == 1);
    vm.startPrank(testAddress1);
    chatInstance.clearChatMessages(myfriends[0]._roomId);
    vm.stopPrank();
    assert(chatInstance.getMessagesByRoomId(myfriends[0]._roomId).length == 0);
  }
}
