import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/pages/login_screen.dart';

class MainHeader extends StatelessWidget
    implements PreferredSizeWidget {

  final String userName;
  final String? avatarBase64;

  const MainHeader({
    super.key,
    required this.userName,
    this.avatarBase64,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E5CA),
      padding: const EdgeInsets.only(
        top: 40,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      child: Row(
        children: [

          /// AVATAR
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF9BAB60),

            backgroundImage:
                avatarBase64 != null &&
                        avatarBase64!.isNotEmpty
                    ? MemoryImage(
                        base64Decode(avatarBase64!),
                      )
                    : null,

            child:
                avatarBase64 == null ||
                        avatarBase64!.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Colors.white,
                      )
                    : null,
          ),

          const SizedBox(width: 10),

          /// USER NAME
          Expanded(
            child: Text(
              "Chào, $userName!",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          /// NOTIFICATION
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),

          /// LOGOUT
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}