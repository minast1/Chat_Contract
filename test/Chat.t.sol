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

  function test_GetUserName_ItReturnsTheDefaultNameProvidedByAnUser() public {
    address testAddress1 = makeAddr("chatInstance");
    vm.prank(testAddress1);
    chatInstance.createAccount("user1");
    assert(chatInstance.getUserName(testAddress1) == "user1");
  }

  function test_AddFriend_ItRevertsIfUserAccountDoesNotExist() public {
    address testAddress1 = makeAddr("chatInstance");
    address friendAddress = makeAddr("chatInstance2");
    vm.startPrank(testAddress1);

    vm.expectRevert(abi.encodeWithSelector(Chat.UserAccountDoesNotExist.selector, testAddress1));
    chatInstance.addFriend(friendAddress);
    vm.stopPrank();
  }

  function test_AddFriend_ItRevertsIfFriendAccountDoesNotExist() public {
    address testAddress1 = makeAddr("chatInstance");
    address friendAddress = makeAddr("chatInstance2");
    vm.startPrank(testAddress1);
    chatInstance.createAccount("user1");
    vm.expectRevert(abi.encodeWithSelector(Chat.FriendAccountDoesNotExist.selector, friendAddress));
    chatInstance.addFriend(friendAddress);
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
    assert(chatInstance.isFriend(testAddress2));
  }

  function test_AddFriend_ItAddsFriendNickname() public {
    address testAddress1 = makeAddr("chatInstance");
    address testAddress2 = makeAddr("chatInstance2");

    vm.prank(testAddress1);
    chatInstance.createAccount("user1");

    vm.prank(testAddress2);
    chatInstance.createAccount("user2");

    vm.startPrank(testAddress1);
    chatInstance.addFriend(testAddress2, "nickname");
    assert(chatInstance.getUserFriends(testAddress1)[0]._nickname == "nickname");

    vm.stopPrank();
  }

  function test_GetUserFriends_ItReturnsListOfFriends() public {
    address testAddress1 = makeAddr("chatInstance");
    address testAddress2 = makeAddr("chatInstance2");

    vm.prank(testAddress1);
    chatInstance.createAccount("user1");

    vm.prank(testAddress2);
    chatInstance.createAccount("user2");

    vm.startPrank(testAddress1);
    chatInstance.addFriend(testAddress2);
    vm.stopPrank();
    assert(chatInstance.getUserFriends(testAddress1).length == 1);
  }

  // function test_getMessagesByRoomId_ItReturnsListOfMessages() public {
  //   address testAddress1 = makeAddr("chatInstance");
  //   address testAddress2 = makeAddr("chatInstance2");

  //   vm.prank(testAddress1);
  //   chatInstance.createAccount("user1");

  //   vm.prank(testAddress2);
  //   chatInstance.createAccount("user2");

  //   vm.startPrank(testAddress1);
  //   chatInstance.addFriend(testAddress2);
  //   vm.stopPrank();
  //   assert(
  //     chatInstance.getMessagesByRoomId(chatInstance.getRoomId(testAddress1, testAddress2)).length
  //       == 0
  //   );
  // }
}
