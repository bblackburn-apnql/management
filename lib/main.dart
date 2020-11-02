import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presence.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue, cardTheme: CardTheme(elevation: 3)),
      home: Login(),
    );
  }
}

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    checkUserInfos(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Connexion'),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20.0),
              child: TextField(
                controller: _controller,

                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                ),
                onSubmitted: (newValue) {
                  if (newValue != "") {
                    if (saveUserInfos(newValue) != "") {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Presence()));
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Replace these two methods in the examples that follow


  saveUserInfos(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userName', userName);
    print('saved $userName in userName');
    return prefs.getString('userName') ?? "";
  }

  checkUserInfos(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName');
    if(userName != null) {
      _controller.text = userName;
    }
  }
}