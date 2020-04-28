import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';

import 'login_screen.dart';
import 'welcome_screen.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  static String id = '/Chat_Screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _fcm = FirebaseMessaging();

  String messageText;

  @override
  void initState() {
    super.initState();
    _fcm.requestNotificationPermissions(IosNotificationSettings());
    getCurrentUser();
    if (Platform.isIOS) {
      _fcm.requestNotificationPermissions(IosNotificationSettings());

      _fcm.onIosSettingsRegistered.listen((data) {
        _saveToken();
      });
    }
  }

  void _saveToken() async {
    String fcmToken = await _fcm.getToken();

    if (fcmToken != null) {
      var tokenRef = _firestore
          .collection('user')
          .document(loggedInUser.email)
          .collection('token');

      await tokenRef.add({
        'token': fcmToken,
        'createdAt': DateTime.now(),
        'platform': Platform.operatingSystem
      });
    }
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.popAndPushNamed(context, LoginScreen.id);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Stream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      style: TextStyle(color: Colors.black),
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'time_stamp': DateTime.now(),
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
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

class Stream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore.collection('messages').orderBy('time_stamp').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final messages = snapshot.data.documents.reversed;
          List<MessageBubble> messagesWidget = [];
          for (var message in messages) {
            final messageText = message.data['text'];
            final messageSender = message.data['sender'];
            final time = message.data['time_stamp'];

            final currentUser = loggedInUser.email;

            final messageBubble = MessageBubble(
              sender: messageSender,
              text: messageText,
              isMe: currentUser == messageSender,
              time: time,
            );
            messagesWidget.add(messageBubble);
          }
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              child: ListView(
                reverse: true,
                children: messagesWidget,
              ),
            ),
          );
        } else {
          return CircularProgressIndicator(
            backgroundColor: Colors.lightBlueAccent,
          );
        }
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;
  final Timestamp time;

  MessageBubble(
      {@required this.text, @required this.sender, this.isMe, this.time});

  String getTimeLabel() {
    var timeSent = DateTime.fromMillisecondsSinceEpoch(time.seconds * 1000);
    var now = DateTime.now();

    var day = DateFormat.yMMMMd("en_US").format(timeSent);
    var hour = DateFormat.Hm().format(timeSent);

    String output = '';

    if (timeSent.day == now.day) {
      output = '$hour';
    } else {
      output = '$day $hour';
    }
    return output;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Text(
              sender,
              style: TextStyle(fontSize: 12),
            ),
          ),
          Material(
            elevation: 5,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMe ? 30 : 3),
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
              topRight: Radius.circular(isMe ? 4 : 30),
            ),
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
              child: Text(
                text,
                style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15.0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              '   ${getTimeLabel()}    ',
              style: TextStyle(fontSize: 11.0),
            ),
          ),
        ],
      ),
    );
  }
}
