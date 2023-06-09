import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:save_me_project/home_page.dart';
import 'dart:async';
import 'utils.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState(){
    super.initState();  
  
  //user need to be created before 
  isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

  if(!isEmailVerified){
    sendVerificationEmail();

    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkEmailVerified(),
      );
  }
}

@override
void dispose(){
  timer?.cancel();

  super.dispose();
}

Future checkEmailVerified()async{
  //call after email verification
  await FirebaseAuth.instance.currentUser!.reload();

  setState((){
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
  });

  if(isEmailVerified)timer?.cancel();
}

Future sendVerificationEmail()async{
  try{
    final user=FirebaseAuth.instance.currentUser!;
    await user.sendEmailVerification();

    setState(()=>canResendEmail = false);
    await Future.delayed(const Duration(seconds: 5));
    setState(() => canResendEmail = true);
  }catch (e){
    Utils.showSnackBar(e.toString());
  }
}

  @override
  Widget build(BuildContext context) => isEmailVerified ? const HomePage() : Scaffold(
    appBar: AppBar(
      title: const Text('Verfiy Email'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'A verification email has been to your email',
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.email,size: 32),
            label: const Text(
              'Resent Email',
              style: TextStyle(fontSize: 24),
            ),
            onPressed: canResendEmail ? sendVerificationEmail : null,
          ),  
          const SizedBox(height: 8),
          TextButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child:const Text(
              ('Cancel'),
              style: TextStyle(fontSize: 24),
            ),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
    ),
  );
}