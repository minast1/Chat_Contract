// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { EnumerableSet } from "@openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import { Ownable } from "@openzeppelin-contracts/access/Ownable.sol";

contract Chat is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private s_userAddressPointers;

  using EnumerableSet for EnumerableSet.Bytes32Set;

  EnumerableSet.Bytes32Set private s_userNamePointers;

  struct FriendStruct {
    address _address;
    string _nickname;
    uint256 _timestamp;
    bytes32 _roomId;
  }

  struct UserStruct {
    bytes32 name;
    FriendStruct[] friends;
  }

  struct MessageStruct {
    string message;
    bytes32 roomId;
    address sender;
    uint256 timestamp;
    string nickname;
  }

  //events
  event ChatStarted(string indexed _roomId);

  mapping(address => UserStruct) private s_users;
  //mapping(address => UserStruct) private friends;
  mapping(bytes32 => MessageStruct[]) private s_chat_messages;
  // mapping(bytes32 => ) private chatRooms;
  EnumerableSet.Bytes32Set private s_roomsList;
  mapping(address => EnumerableSet.AddressSet) private s_userFriends;

  constructor(address initialOwner) Ownable(initialOwner) { }

  error UserNameAlreadyExists(bytes32 name);
  error UserAccountAlreadyExists(address userAddress);
  error FriendAccountDoesNotExist(address friendAddress);
  error UserAccountDoesNotExist(address userAddress);
  error CannotAddYourselfAsFriend(address userAddress);
  error UserIsAlreadyAFriend(address userAddress);
  error ChatRoomDoesNotExist(bytes32 roomId);

  // Registers the caller(msg.sender) to our app with a non-empty username
  function createAccount(string memory name) external {
    bytes32 nameToBytes32 = stringToBytes32(name);
    if (existsUserName(nameToBytes32)) {
      revert UserNameAlreadyExists(nameToBytes32);
    }
    //add the new user
    addNewNamePointer(nameToBytes32);
    addNewAddressPointer(msg.sender);
    s_users[msg.sender].name = nameToBytes32;
  }

  //convert string to bytes32
  function stringToBytes32(string memory name) public pure returns (bytes32) {
    return bytes32(abi.encodePacked(name));
  }

  //converts bytes32 to string
  function bytes32ToString(bytes32 _bytes32) private pure returns (string memory) {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (uint8 j = 0; j < i; j++) {
      bytesArray[j] = _bytes32[j];
    }
    return string(bytesArray);
  }

  function getUserName(address userAddress) public view returns (string memory) {
    if (!existsAccount(userAddress)) revert UserAccountDoesNotExist(userAddress);
    bytes32 decodedName = s_users[userAddress].name;
    return bytes32ToString(decodedName);
  }

  // Adds new user as your friend without nickname option
  function addFriend(address _friendAddress) external {
    if (!existsAccount(msg.sender)) revert UserAccountDoesNotExist(msg.sender);
    if (!existsAccount(_friendAddress)) revert FriendAccountDoesNotExist(_friendAddress);
    if (msg.sender == _friendAddress) revert CannotAddYourselfAsFriend(msg.sender);
    if (isFriend(msg.sender, _friendAddress)) revert UserIsAlreadyAFriend(_friendAddress);
    s_userFriends[msg.sender].add(_friendAddress);
    string memory friendName = getUserName(_friendAddress);
    bytes32 roomId = getRoomId(msg.sender, _friendAddress);
    s_users[msg.sender].friends.push(
      FriendStruct(_friendAddress, friendName, block.timestamp, roomId)
    );
  }

  // Adds new user as your friend with nickname option
  function addFriend(address _friendAddress, string memory _nickname) external {
    if (!existsAccount(msg.sender)) revert UserAccountDoesNotExist(msg.sender);
    if (!existsAccount(_friendAddress)) revert FriendAccountDoesNotExist(_friendAddress);
    if (msg.sender == _friendAddress) revert CannotAddYourselfAsFriend(msg.sender);
    if (isFriend(msg.sender, _friendAddress)) revert UserIsAlreadyAFriend(_friendAddress);
    s_userFriends[msg.sender].add(_friendAddress);

    bytes32 roomId = getRoomId(msg.sender, _friendAddress);
    s_users[msg.sender].friends.push(
      FriendStruct(_friendAddress, _nickname, block.timestamp, roomId)
    );
  }

  // Checks if two users are already friends or not
  function isFriend(address owner, address friendAddress) public view returns (bool) {
    return s_userFriends[owner].contains(friendAddress);
  }

  // Returns a unique code for the channel created between the two users
  // Hash(key1,key2) where key1 is lexicographically smaller than key2
  function getRoomId(address user1, address user2) public pure returns (bytes32) {
    if (user1 > user2) return keccak256(abi.encodePacked(user2, user1));

    return keccak256(abi.encodePacked(user1, user2));
  }

  // Sends a message in a chatRoom between users
  function sendMessage(bytes32 _roomId, string memory message) external {
    //bytes32 roomId = stringToBytes32(_roomId);
    if (!existsAccount(msg.sender)) revert UserAccountDoesNotExist(msg.sender);
    // if (!existsRoom(roomId)) revert ChatRoomDoesNotExist(roomId);
    string memory _nickname = getUserName(msg.sender);
    s_chat_messages[_roomId].push(
      MessageStruct(message, _roomId, msg.sender, block.timestamp, _nickname)
    );
  }

  function getMessagesByRoomId(bytes32 _roomId) public view returns (MessageStruct[] memory) {
    //if (!existsRoom(roomId)) revert ChatRoomDoesNotExist(roomId);
    return s_chat_messages[_roomId];
  }

  function existsUserName(bytes32 key) public view returns (bool) {
    return s_userNamePointers.contains(key);
  }

  function existsAccount(address key) public view returns (bool) {
    return s_userAddressPointers.contains(key);
  }

  function addNewNamePointer(bytes32 key) private {
    s_userNamePointers.add(key);
  }

  function getUserFriends(address userAddress) public view returns (FriendStruct[] memory) {
    if (!existsAccount(userAddress)) revert UserAccountDoesNotExist(userAddress);
    return s_users[userAddress].friends;
  }

  function getRoomsLength() public view returns (uint256) {
    return s_roomsList.length();
  }

  function getUsersLength() public view returns (uint256) {
    return s_userAddressPointers.length();
  }

  function addNewAddressPointer(address key) private {
    s_userAddressPointers.add(key);
  }
}
