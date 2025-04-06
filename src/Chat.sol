// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { EnumerableSet } from "@openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import { Ownable } from "@openzeppelin-contracts/access/Ownable.sol";

contract Chat is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private _userAddressPointers;

  using EnumerableSet for EnumerableSet.Bytes32Set;

  EnumerableSet.Bytes32Set private _userNamePointers;

  // using EnumerableSet for EnumerableSet.UintSet;

  struct FriendStruct {
    address _address;
    string _nickname;
    uint256 _timestamp;
  }

  struct GenericFriendStruct {
    address _address;
    string _nickname;
  }

  struct UserStruct {
    bytes32 name;
    FriendStruct[] friends;
  }
  // EnumerableSet.Bytes32Set rooms;
  //MessageStruct[] messages;
  //Pointers

  struct ChatRoomStruct {
    EnumerableSet.AddressSet users;
    MessageStruct[] messages;
  }

  struct MessageStruct {
    string message;
    bytes32 roomId;
    address sender;
    uint256 timestamp;
  }

  mapping(address => UserStruct) private users;
  //mapping(address => UserStruct) private friends;
  mapping(bytes32 => MessageStruct[]) private messages;
  mapping(bytes32 => ChatRoomStruct) private chatRooms;
  EnumerableSet.Bytes32Set private _roomsList;
  mapping(uint256 => GenericFriendStruct) private _predefinedfriends;
  EnumerableSet.AddressSet private _friendsList;
  //EnumerableSet.AddressSet private _messagesList;

  constructor(address initialOwner) Ownable(initialOwner) {
    generateGenericFriends();
  }

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
    } else {
      if (existsAccount(msg.sender)) {
        revert UserAccountAlreadyExists(msg.sender);
      } else {
        //add the new user
        addNewNamePointer(nameToBytes32);
        addNewAddressPointer(msg.sender);
        users[msg.sender].name = nameToBytes32;
      }
    }
  }

  //convert string to bytes32
  function stringToBytes32(string memory name) private pure returns (bytes32) {
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
  // Returns the default name provided by an user

  function getUserName(address userAddress) public view returns (string memory) {
    if (!existsAccount(userAddress)) revert UserAccountDoesNotExist(userAddress);
    bytes32 decodedName = users[userAddress].name;
    return bytes32ToString(decodedName);
  }

  // Adds new user as your friend
  function addFriend(address[] memory _friendAddress) external {
    //add each friend to the list
    for (uint256 i = 0; i < _friendAddress.length; i++) {
      if (!existsAccount(msg.sender)) revert UserAccountDoesNotExist(msg.sender);
      if (!existsAccount(_friendAddress[i])) revert FriendAccountDoesNotExist(_friendAddress[i]);
      if (msg.sender == _friendAddress[i]) revert CannotAddYourselfAsFriend(msg.sender);
      if (isFriend(_friendAddress[i])) revert UserIsAlreadyAFriend(_friendAddress[i]);
      _friendsList.add(_friendAddress[i]);
      users[msg.sender].friends.push(FriendStruct(_friendAddress[i], string(""), block.timestamp));
    }
  }

  //Adds the new user as your friend with an associated nickname
  // function addFriend(address friendAddress, string memory _nickname) external {
  //   if (!existsAccount(msg.sender)) revert UserAccountDoesNotExist(msg.sender);
  //   if (!existsAccount(friendAddress)) revert FriendAccountDoesNotExist(friendAddress);
  //   if (msg.sender == friendAddress) revert CannotAddYourselfAsFriend(msg.sender);
  //   if (isFriend(friendAddress)) revert UserIsAlreadyAFriend(friendAddress);
  //   _friendsList.add(friendAddress);
  //   users[msg.sender].friends.push(FriendStruct(friendAddress, _nickname, block.timestamp));
  // }

  // Checks if two users are already friends or not
  function isFriend(address friendAddress) public view returns (bool) {
    return _friendsList.contains(friendAddress);
  }

  // Returns a unique code for the channel created between the two users
  // Hash(key1,key2) where key1 is lexicographically smaller than key2
  function getRoomId(address user1, address user2) public pure returns (bytes32) {
    if (user1 > user2) return keccak256(abi.encodePacked(user2, user1));

    return keccak256(abi.encodePacked(user1, user2));
  }

  // Sends a message in a chatRoom between users
  function sendMessage(bytes32 roomId, string memory message) external {
    if (!existsAccount(msg.sender)) revert UserAccountDoesNotExist(msg.sender);
    if (!existsRoom(roomId)) revert ChatRoomDoesNotExist(roomId);
    // _messagesList.add(msg.sender);

    chatRooms[roomId].messages.push(MessageStruct(message, roomId, msg.sender, block.timestamp));
    //messages[msg.sender] = MessageStruct(message, roomId, msg.sender, block.timestamp);
  }

  //start a chat room between two users
  function startChat(address chatee) external returns (bytes32) {
    if (!existsAccount(msg.sender)) revert UserAccountDoesNotExist(msg.sender);
    if (!existsAccount(chatee)) revert UserAccountDoesNotExist(chatee);
    bytes32 roomId = getRoomId(msg.sender, chatee);
    _roomsList.add(roomId);
    chatRooms[roomId].users.add(msg.sender);
    chatRooms[roomId].users.add(chatee);
    return roomId;
  }

  //get the messages for a room by roomId

  function getMessagesByRoomId(bytes32 roomId) public view returns (MessageStruct[] memory) {
    if (!existsRoom(roomId)) revert ChatRoomDoesNotExist(roomId);
    return chatRooms[roomId].messages;
  }

  function getChatRoomUsers(bytes32 roomId) public view returns (address[] memory) {
    if (!existsRoom(roomId)) revert ChatRoomDoesNotExist(roomId);
    address[] memory members = chatRooms[roomId].users.values();
    return members;
  }

  function existsUserName(bytes32 key) public view returns (bool) {
    return _userNamePointers.contains(key);
  }

  function existsAccount(address key) public view returns (bool) {
    return _userAddressPointers.contains(key);
  }

  function existsRoom(bytes32 key) public view returns (bool) {
    return _roomsList.contains(key);
  }

  function addNewNamePointer(bytes32 key) private {
    _userNamePointers.add(key);
  }

  function addNewAddressPointer(address key) private {
    _userAddressPointers.add(key);
  }

  function getUserFriends(address userAddress) public view returns (FriendStruct[] memory) {
    if (!existsAccount(userAddress)) revert UserAccountDoesNotExist(userAddress);
    return users[userAddress].friends;
  }

  function getRoomsLength() public view returns (uint256) {
    return _roomsList.length();
  }

  function generateGenericFriends() private {
    string[10] memory names = [
      "Mo Salah",
      "Cristiano Ronaldo",
      "Sadio Mane",
      "Lion Messi",
      "Luis Garcia",
      "Stephen Gerrard",
      "Vinicius Junior",
      "Dani Alves",
      "Ronaldinho",
      "Requelmi"
    ];
    //loop through friends array
    for (uint256 i = 0; i < 10; i++) {
      address genericAddress = address(bytes20(keccak256(abi.encodePacked(names[i]))));
      string memory genericName = names[i];
      //Register each friend to our app
      addNewAddressPointer(genericAddress);
      addNewNamePointer(stringToBytes32(genericName));
      users[genericAddress].name = stringToBytes32(genericName);

      _predefinedfriends[i] = GenericFriendStruct(genericAddress, genericName);
    }
  }

  function getPredefinedFriends() public view returns (GenericFriendStruct[] memory) {
    GenericFriendStruct[] memory fr = new GenericFriendStruct[](10);
    for (uint256 i = 0; i < 10; i++) {
      fr[i] = _predefinedfriends[i];
    }

    return fr;
  }

  function getUsersLength() public view returns (uint256) {
    return _userAddressPointers.length();
  }
}
