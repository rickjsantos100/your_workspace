import 'package:flutter/material.dart';

class ProfileSelector extends StatelessWidget {
  const ProfileSelector({
    Key? key,
    this.avatarUrl,
    this.isSelected = false,
    required this.onPressed,
  }) : super(key: key);

  final String? avatarUrl;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(8),
          elevation: 1),
      child: const CircleAvatar(
          backgroundImage: AssetImage('images/default_profile.png')
          //  NetworkImage(
          //     'https://images.unsplash.com/photo-1453728013993-6d66e9c9123a?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8Mnx8dmlld3xlbnwwfHwwfHw%3D&w=1000&q=80'),
          ),
      onPressed: () => onPressed(),
    );

    // return InkWell(
    //   onTap: () {},
    //   child: const CircleAvatar(
    //     backgroundImage: NetworkImage(
    //         'https://images.unsplash.com/photo-1453728013993-6d66e9c9123a?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8Mnx8dmlld3xlbnwwfHwwfHw%3D&w=1000&q=80'),
    //   ),
    // );
  }
}
