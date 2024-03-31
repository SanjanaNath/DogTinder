import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

class MainScreen extends StatefulWidget {
  final User user;

  MainScreen({
    required this.user,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

enum SwipeDirection {
  Left,
  Right,
  Down,
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  String currentImageUrl = '';
  String nextImageUrl = '';
  int leftCount = 0;
  int downCount = 0;
  int rightCount = 0;
  late SharedPreferences _prefs;
  final String _leftCountKey = 'leftCount';
  final String _downCountKey = 'downCount';
  final String _rightCountKey = 'rightCount';
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  void initCounts() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .get();

    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        leftCount = data['leftCount'] ?? 0;
        downCount = data['downCount'] ?? 0;
        rightCount = data['rightCount'] ?? 0;
      });
    } else {
      setState(() {
        leftCount = 0;
        downCount = 0;
        rightCount = 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initCounts();
    initSharedPreferences();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(1.0, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    fetchRandomDogPicture();
  }

  void initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();

    bool isFirstTime = _prefs.getBool('firstTime') ?? true;
    if (isFirstTime) {
      setState(() {
        leftCount = 0;
        downCount = 0;
        rightCount = 0;
        saveCounts();
        _prefs.setBool('firstTime', false);
      });
    } else {
      setState(() {
        leftCount = _prefs.getInt(_leftCountKey) ?? 0;
        downCount = _prefs.getInt(_downCountKey) ?? 0;
        rightCount = _prefs.getInt(_rightCountKey) ?? 0;
      });
    }
  }

  void saveCounts() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .update({
      'leftCount': leftCount,
      'downCount': downCount,
      'rightCount': rightCount,
    });

    _prefs.setInt(_leftCountKey, leftCount);
    _prefs.setInt(_downCountKey, downCount);
    _prefs.setInt(_rightCountKey, rightCount);
  }

  void fetchRandomDogPicture() async {
    try {
      final response =
          await http.get(Uri.parse('https://dog.ceo/api/breeds/image/random'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          nextImageUrl = data['message'];
        });
      } else {
        print('Failed to fetch dog picture: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to fetch dog picture: $error');
    }
  }

  void onSwipe(SwipeDirection direction) {
    setState(() {
      if (direction == SwipeDirection.Left) {
        leftCount += 1;
      } else if (direction == SwipeDirection.Down) {
        downCount += 1;
      } else if (direction == SwipeDirection.Right) {
        rightCount += 1;
      }
      saveCounts();
      currentImageUrl = nextImageUrl;
    });
    fetchRandomDogPicture();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 156, 98, 255),
          title: Text(
            'Welcome, ${widget.user.displayName ?? 'Guest'}',
            style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                // Sign out the user
                await FirebaseAuth.instance.signOut();

                // Navigate back to the login screen
                // ignore: use_build_context_synchronously
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Column(
                children: [
                  const SizedBox(
                    height: 50,
                  ),
                  const Text(
                    "Tinder Of Dogs",
                    style:
                        TextStyle(fontSize: 50.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 100,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Left: $leftCount',
                            style: const TextStyle(fontSize: 30.0),
                          ),
                          const SizedBox(height: 16.0),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Down: $downCount',
                            style: const TextStyle(fontSize: 30.0),
                          ),
                          const SizedBox(height: 16.0),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Right: $rightCount',
                            style: const TextStyle(fontSize: 30.0),
                          ),
                          const SizedBox(height: 16.0),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Stack(
                    children: [
                      if (currentImageUrl.isNotEmpty)
                        GestureDetector(
                          onTapDown: (_) {
                            _animationController.forward();
                          },
                          onTapUp: (_) {
                            _animationController.reverse().whenComplete(() {
                              onSwipe(SwipeDirection.Left);
                            });
                          },
                          onDoubleTap: () {
                            _animationController.reverse().whenComplete(() {
                              onSwipe(SwipeDirection.Right);
                            });
                          },
                          onLongPress: () {
                            _animationController.reverse().whenComplete(() {
                              onSwipe(SwipeDirection.Down);
                            });
                          },
                          child: SlideTransition(
                            position: _animation,
                            child: Container(
                              height: 300,
                              width: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(currentImageUrl),
                                ),
                              ),
                              foregroundDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        const CircularProgressIndicator(),
                      if (nextImageUrl.isNotEmpty)
                        IgnorePointer(
                          child: Opacity(
                            opacity: 0.0,
                            child: Container(
                              height: 300,
                              width: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(nextImageUrl),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    splashColor: Colors.red[300],
                    highlightColor: Colors.red[300],
                    onTapDown: (_) {
                      setState(() {
                        _animation = Tween<Offset>(
                          begin: Offset.zero,
                          end: Offset(-1.0, 0.0), // Swipe Left
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.easeInOut,
                          ),
                        );
                        _animationController.forward();
                      });
                    },
                    onTapUp: (_) {
                      _animation = Tween<Offset>(
                        begin: Offset.zero,
                        end: Offset(-1.0, 0.0), // Swipe Left
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeInOut,
                        ),
                      );
                      _animationController.reverse().whenComplete(() {
                        onSwipe(SwipeDirection.Left);
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Left",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 50,
                  ),
                  InkWell(
                    splashColor: Colors.black45,
                    highlightColor: Colors.black45,
                    onTapDown: (_) {
                      setState(() {
                        _animation = Tween<Offset>(
                          begin: Offset.zero,
                          end: Offset(0.0, 1.0), // Swipe Down
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.easeInOut,
                          ),
                        );
                        _animationController.forward();
                      });
                    },
                    onTapUp: (_) {
                      _animation = Tween<Offset>(
                        begin: Offset.zero,
                        end: Offset(0.0, 1.0), // Swipe Down
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeInOut,
                        ),
                      );
                      _animationController.reverse().whenComplete(() {
                        onSwipe(SwipeDirection.Down);
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Down",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 50,
                  ),
                  InkWell(
                    splashColor: Colors.blue[200],
                    highlightColor: Colors.blue[200],
                    onTapDown: (_) {
                      setState(() {
                        _animation = Tween<Offset>(
                          begin: Offset.zero,
                          end: Offset(1.0, 0.0), // Swipe Right
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.easeInOut,
                          ),
                        );
                        _animationController.forward();
                      });
                    },
                    onTapUp: (_) {
                      _animation = Tween<Offset>(
                        begin: Offset.zero,
                        end: Offset(1.0, 0.0), // Swipe Right
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeInOut,
                        ),
                      );
                      _animationController.reverse().whenComplete(() {
                        onSwipe(SwipeDirection.Right);
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Right",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
