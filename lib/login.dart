import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  SharedPreferences? _prefs = null;
  final String _loggedInKey = 'loggedIn';

  @override
  void initState() {
    super.initState();
    initSharedPreferences();
    checkUserLoginStatus();
  }

  void initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void checkUserLoginStatus() {
    bool isLoggedIn = _prefs?.getBool(_loggedInKey) ?? false;
    if (isLoggedIn) {
      User? user = FirebaseAuth.instance.currentUser;
      navigateToMainScreen(user);
    }
  }

  void saveLoginStatus() {
    _prefs?.setBool(_loggedInKey, true);
  }

  void _signIn(BuildContext context) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      User user = userCredential.user!;
      saveLoginStatus();
      navigateToMainScreen(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Display error message using a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('unregistered email.')),
        );
      } else if (e.code == 'wrong-password') {
        // Display error message using a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wrong password entered.')),
        );
      } else {
        // Display error message using a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.code}')),
        );
      }
    }
  }

  void _navigateToRegistration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistrationScreen()),
    );
  }

  void navigateToMainScreen(User? user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen(user: user!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Center(
      //       child: const Text(
      //     'Login',
      //     style: TextStyle(fontSize: 80),
      //   )),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Center(
              child: Text(
                'Login',
                style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple),
              ),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _signIn(context),
                  child: const Text('Sign In'),
                ),
                ElevatedButton(
                  onPressed: () => _navigateToRegistration(context),
                  child: const Text('Register'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void _register(BuildContext context) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Set the user's display name
      await userCredential.user!
          .updateProfile(displayName: nameController.text);

      // Initialize the user's score to zero
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({'score': 0});

      navigateToMainScreen(context, userCredential.user!);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        // Display error message using a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The password provided is too weak.')),
        );
      } else if (e.code == 'email-already-in-use') {
        // Display error message using a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The account already exists for that email.')),
        );
      } else {
        // Display error message using a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.code}')),
        );
      }
    }
  }

  void navigateToMainScreen(BuildContext context, User? user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              MainScreen(user: user ?? FirebaseAuth.instance.currentUser!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () => _register(context),
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
