class GroupModel {
  final String groupId;
  final String groupName;
  final String groupPicture;
  final String creatorId;
  final bool hidePhoneNumbers;
  final List<String> membersUid;
  final String lastMessage;
  final DateTime timeSent;

  GroupModel({
    required this.groupId,
    required this.groupName,
    required this.groupPicture,
    required this.creatorId,
    required this.hidePhoneNumbers,
    required this.membersUid,
    required this.lastMessage,
    required this.timeSent,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupPicture': groupPicture,
      'creatorId': creatorId,
      'hidePhoneNumbers': hidePhoneNumbers,
      'membersUid': membersUid,
      'lastMessage': lastMessage,
      'timeSent': timeSent.millisecondsSinceEpoch,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
      groupPicture: map['groupPicture'] ?? '',
      creatorId: map['creatorId'] ?? '',
      hidePhoneNumbers: map['hidePhoneNumbers'] ?? false,
      membersUid: List<String>.from(map['membersUid'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      timeSent: DateTime.fromMillisecondsSinceEpoch(map['timeSent'] ?? 0),
    );
  }
}