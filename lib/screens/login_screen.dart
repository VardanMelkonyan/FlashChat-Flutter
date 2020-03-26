import 'package:flutter/material.dart';
import 'package:flash_chat/bottom_button.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import '../constants.dart';
import 'chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/auth.dart';

class LoginScreen extends StatefulWidget {
  static String id = '/Login_Screen';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  String email;
  String password;
  var err;
  var authent = Auth();
  bool spinnerIsActive = false;

  Widget showErrorMessage(err) {
    var _errorMessage = err;
    if (_errorMessage != null) {
      return Text(
        _errorMessage,
        style: TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
      );
    } else {
      return Container(
        height: 0.0,
      );
    }
  }

  void afterNavigation(user) async {
    if (user != null) {
      bool isVerified = await authent.isEmailVerified();
      if (isVerified == true) {
        Navigator.pushNamed(context, ChatScreen.id);
      } else {
        setState(() {
          err = 'Verify your email and try to log in.';
        });
      }
      setState(() {
        spinnerIsActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: spinnerIsActive,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Flexible(
                      child: Hero(
                        tag: 'logo',
                        child: Container(
                          height: 200.0,
                          child: Image.asset('images/logo.png'),
                        ),
                      ),
                    ),
                    Container(
                      height: 48.0,
                      child: Center(
                        child: showErrorMessage(err),
                      ),
                    ),
                    TextField(
                        keyboardType: TextInputType.emailAddress,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black),
                        onChanged: (value) {
                          email = value;
                        },
                        decoration: kInputDecoration.copyWith(
                            hintText: 'Enter your email')),
                    SizedBox(
                      height: 8.0,
                    ),
                    TextField(
                      obscureText: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black),
                      onChanged: (value) {
                        password = value;
                      },
                      decoration: kInputDecoration.copyWith(
                          hintText: 'Enter your password.'),
                    ),
                  ],
                ),
              ),
            ),
            BottomButton(
              buttonTitle: 'Log In or Register',
              onTap: () async {
                print(email);
                print(password);
                try {
                  setState(() {
                    spinnerIsActive = true;
                  });
                  final user = await _auth.signInWithEmailAndPassword(
                      email: email, password: password);
                  afterNavigation(user);
                } catch (e) {
                  if (e.message.toString() ==
                      'There is no user record corresponding to this identifier. The user may have been deleted.') {
                    setState(() {
                      err = 'Verify your email and try to log in.';
                    });
                  } else {
                    setState(() {
                      err = e.message;
                    });
                  }
                  print(e.message);
                  try {
                    setState(() {
                      spinnerIsActive = true;
                    });
                    final newUser = await _auth.createUserWithEmailAndPassword(
                        email: email, password: password);
                    authent.sendEmailVerification();
                    afterNavigation(newUser);
                  } catch (er) {
                    print(er.message);
                    setState(() {
                      err = er.message;
                    });
                  }
                  spinnerIsActive = false;
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
