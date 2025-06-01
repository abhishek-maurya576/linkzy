class AppUser {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String profilePicUrl;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    this.displayName = '',
    this.profilePicUrl = '',
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'username': username,
    'displayName': displayName,
    'profilePicUrl': profilePicUrl,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] ?? '',
    email: map['email'] ?? '',
    username: map['username'] ?? '',
    displayName: map['displayName'] ?? '',
    profilePicUrl: map['profilePicUrl'] ?? '',
  );
  
  AppUser copyWith({
    String? uid,
    String? email,
    String? username,
    String? displayName,
    String? profilePicUrl,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
    );
  }
} 