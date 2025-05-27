import 'package:flutter/material.dart';
import '../models/avatar.dart';

class AvatarSelectionScreen extends StatelessWidget {
  const AvatarSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final avatars = Avatar.getDefaultAvatars();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Avatar'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: avatars.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              Navigator.pop(context, avatars[index].path);
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  avatars[index].path,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 