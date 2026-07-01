class UserSearchResult {
  final String uid;
  final String name;
  final String? username;
  final String? avatarUrl;
  final String? email;
  final bool isFriend;
  final bool requestSent;

  const UserSearchResult({
    required this.uid,
    required this.name,
    this.username,
    this.avatarUrl,
    this.email,
    this.isFriend = false,
    this.requestSent = false,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) =>
      UserSearchResult(
        uid: json['uid'] as String,
        name: json['name'] as String? ?? '',
        username: json['username'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        email: json['email'] as String?,
        isFriend: json['isFriend'] as bool? ?? false,
        requestSent: json['requestSent'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    if (username != null) 'username': username,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    if (email != null) 'email': email,
    'isFriend': isFriend,
    'requestSent': requestSent,
  };

  UserSearchResult copyWith({bool? requestSent, bool? isFriend}) =>
      UserSearchResult(
        uid: uid,
        name: name,
        username: username,
        avatarUrl: avatarUrl,
        email: email,
        isFriend: isFriend ?? this.isFriend,
        requestSent: requestSent ?? this.requestSent,
      );
}
