class Avatar {
  final String id;
  final String path;

  Avatar({
    required this.id,
    required this.path,
  });

  static List<Avatar> getDefaultAvatars() {
    return [
      Avatar(id: '1', path: 'assets/images/avatar/avatar_1_img.png'),
      Avatar(id: '2', path: 'assets/images/avatar/avatar_2_img.png'),
      Avatar(id: '3', path: 'assets/images/avatar/avatar_3_img.png'),
      Avatar(id: '4', path: 'assets/images/avatar/avatar_4_img.png'),
      Avatar(id: '5', path: 'assets/images/avatar/avatar_5_img.png'),
      Avatar(id: '6', path: 'assets/images/avatar/avatar_6_img.png'),
      Avatar(id: '7', path: 'assets/images/avatar/avatar_7_img.png'),
      Avatar(id: '8', path: 'assets/images/avatar/avatar_8_img.png'),
      Avatar(id: '9', path: 'assets/images/avatar/avatar_9_img.png'),
    ];
  }
} 