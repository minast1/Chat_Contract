// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { Chat } from "../src/Chat.sol";

contract CounterTest is Test {
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

  function test_CreateAccount_ItRevertsIfUserAddressAlreadyExists() public {
    address testAddress1 = makeAddr("chatInstance");
    vm.prank(testAddress1);
    chatInstance.createAccount("user1");

    vm.startPrank(testAddress1);
    vm.expectRevert(abi.encodeWithSelector(Chat.UserAccountAlreadyExists.selector, testAddress1));
    chatInstance.createAccount("user2");

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

    address[] memory friends = new address[](1);
    vm.startPrank(testAddress1);

    vm.expectRevert(abi.encodeWithSelector(Chat.UserAccountDoesNotExist.selector, testAddress1));
    chatInstance.addFriend(friends);
    vm.stopPrank();
  }

  function test_AddFriend_ItRevertsIfFriendAccountDoesNotExist() public {
    address testAddress1 = makeAddr("chatInstance");

    address[] memory friends = new address[](1);
    vm.startPrank(testAddress1);
    chatInstance.createAccount("user1");
    vm.expectRevert(abi.encodeWithSelector(Chat.FriendAccountDoesNotExist.selector, friends[0]));
    chatInstance.addFriend(friends);
    vm.stopPrank();
  }

  function test_AddFriend_ItRevertsIfUserAndFriendAreTheSame() public {
    address testAddress1 = makeAddr("chatInstance");
    address[] memory friends = new address[](1);
    friends[0] = testAddress1;
    vm.startPrank(testAddress1);
    chatInstance.createAccount("user1");
    vm.expectRevert(abi.encodeWithSelector(Chat.CannotAddYourselfAsFriend.selector, testAddress1));
    chatInstance.addFriend(friends);
    vm.stopPrank();
  }

  function test_AddFriend_ItRevertsIfUserAndFriendAreAlreadyFriends() public {
    address testAddress1 = makeAddr("chatInstance");
    address testAddress2 = makeAddr("chatInstance2");
    address[] memory friends = new address[](1);
    friends[0] = testAddress2;
    vm.prank(testAddress1);
    chatInstance.createAccount("user1");

    vm.prank(testAddress2);
    chatInstance.createAccount("user2");

    vm.startPrank(testAddress1);
    chatInstance.addFriend(friends);

    vm.expectRevert(abi.encodeWithSelector(Chat.UserIsAlreadyAFriend.selector, testAddress2));
    chatInstance.addFriend(friends);
    vm.stopPrank();
  }

  function test_AddFriend_ItAddsAUserAsAFriend() public {
    address testAddress1 = makeAddr("chatInstance");
    address testAddress2 = makeAddr("chatInstance2");
    address[] memory friends = new address[](1);
    friends[0] = testAddress2;
    vm.prank(testAddress1);
    chatInstance.createAccount("user1");

    vm.prank(testAddress2);
    chatInstance.createAccount("user2");

    vm.startPrank(testAddress1);
    chatInstance.addFriend(friends);
    vm.stopPrank();
    assert(chatInstance.isFriend(testAddress2));
  }

  function test_AddFriend_ItAddsMultipleFriends() public {
    address testAddress1 = makeAddr("chatInstance");
    address testAddress2 = makeAddr("chatInstance2");
    address testAddress3 = makeAddr("chatInstance3");
    address[] memory friends = new address[](2);
    friends[0] = testAddress2;
    friends[1] = testAddress3;
    vm.prank(testAddress1);
    chatInstance.createAccount("user1");

    vm.prank(testAddress2);
    chatInstance.createAccount("user2");

    vm.prank(testAddress3);
    chatInstance.createAccount("user3");

    vm.startPrank(testAddress1);
    chatInstance.addFriend(friends);
    vm.stopPrank();
    assert(chatInstance.isFriend(testAddress2));
    assert(chatInstance.isFriend(testAddress3));
  }

  function test_GetUserFriends_ItReturnsListOfFriends() public {
    address testAddress1 = makeAddr("chatInstance");
    address testAddress2 = makeAddr("chatInstance2");
    address[] memory friends = new address[](1);
    friends[0] = testAddress2;
    vm.prank(testAddress1);
    chatInstance.createAccount("user1");

    vm.prank(testAddress2);
    chatInstance.createAccount("user2");

    vm.startPrank(testAddress1);
    chatInstance.addFriend(friends);
    vm.stopPrank();
    assert(chatInstance.getUserFriends(testAddress1).length == 1);
  }

  function test_startChat_ItRevertsIfUserAccountDoesNotExist() public {
    address testAddress1 = makeAddr("chatInstance");
    address friendAddress = makeAddr("chatInstance2");
    vm.startPrank(testAddress1);
    vm.expectRevert(abi.encodeWithSelector(Chat.UserAccountDoesNotExist.selector, testAddress1));
    chatInstance.startChat(friendAddress);
    vm.stopPrank();
  }

  function test_startChat_ItCreatesANewChatRoom() public {
    address testAddress1 = makeAddr("chatInstance");
    address friendAddress = makeAddr("chatInstance2");
    address[] memory friends = new address[](1);
    friends[0] = friendAddress;
    string memory roomId;
    vm.prank(testAddress1);
    chatInstance.createAccount("user1");
    vm.prank(friendAddress);
    chatInstance.createAccount("user2");
    vm.startPrank(testAddress1);
    chatInstance.addFriend(friends);
    roomId = chatInstance.startChat(friendAddress);
    vm.stopPrank();
    assertEq(chatInstance.getRoomsLength(), 1);
    address[] memory members = chatInstance.getChatRoomUsers(roomId);
    assertEq(members.length, 2);
    assertEq(members[0], testAddress1);
    assertEq(members[1], friendAddress);
    assert(chatInstance.getMessagesByRoomId(roomId).length == 0);
  }

  function test_sendMessage_ItSendsAMessage() public {
    address testAddress1 = makeAddr("chatInstance");
    address friendAddress = makeAddr("chatInstance2");
    address[] memory friends = new address[](1);
    friends[0] = friendAddress;
    string memory roomId;
    vm.prank(testAddress1);
    chatInstance.createAccount("user1");
    vm.prank(friendAddress);
    chatInstance.createAccount("user2");
    vm.startPrank(testAddress1);
    chatInstance.addFriend(friends);
    roomId = chatInstance.startChat(friendAddress);
    vm.stopPrank();
    vm.startPrank(testAddress1);
    chatInstance.sendMessage(roomId, "message");
    vm.stopPrank();
    assert(chatInstance.getMessagesByRoomId(roomId).length == 1);
  }

  function test_ItGeneratesRegisteredGenericFriends() public view {
    //chatInstance.generateGenericFriends();
    assertEq(chatInstance.getPredefinedFriends().length, 10);
  }

  function test_ItGeneratesUniqueRoomIds() public {
    address testAddress1 = makeAddr("chatInstance");
    address friendAddress = makeAddr("chatInstance2");

    bytes32 roomId1 = chatInstance.getRoomId(testAddress1, friendAddress);
    //bytes32 roomId2 = chatInstance.getRoomId(testAddress1, friendAddress);
    bytes32 roomId3 = chatInstance.getRoomId(friendAddress, testAddress1);
    assert(roomId1 == roomId3);
  }
}
