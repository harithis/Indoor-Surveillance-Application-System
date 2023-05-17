import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:save_me_project/camera.dart';
import 'package:save_me_project/home_page.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Hello There!'),
            accountEmail: Text(user.email!),
            decoration: const BoxDecoration(
                color: Colors.blue,
                image: DecorationImage(
                  image: NetworkImage(
                      'https://oflutter.com/wp-content/uploads/2021/02/profile-bg3.jpg'),
                  fit: BoxFit.cover,
                )),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => {Navigator.push(context, MaterialPageRoute(builder: (context)=>const HomePage()))},
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Camera'),
            onTap: () => {Navigator.push(context, MaterialPageRoute(builder: (context)=>const CameraPage()))},
          ),
        ],
      ),
    );
  }
}
