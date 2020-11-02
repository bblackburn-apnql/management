import 'dart:developer';
import 'dart:ui';

import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter/material.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';



String userName;

class Presence extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    initializeDateFormatting();

    return MaterialApp(
      title: 'APNQL Management',
      home: Agenda(presenceContext: context),

    );
  }
}

class Agenda extends StatefulWidget {
  final BuildContext presenceContext;

  const Agenda({ Key key, this.presenceContext}): super(key: key);

  @override
  _AgendaState createState() => _AgendaState();
}

String _userName;
String _firstName;
String _lastName;
DateTime _dateSelected = DateTime.now();
bool changeAgenda = false;
bool _userInAgenda = false;

var format = new DateFormat('yMd', "fr_CA");

class _AgendaState extends State<Agenda> {

  //var format = new DateFormat('yMd', "fr_CA");
  var formatShow = new DateFormat('d MMM y', "fr_CA");
  Widget _addButton;


  @override
  Widget build(BuildContext context) {

    if (_userName == null) {loadUserInfos();}
    DatabaseReference dbRef = FirebaseDatabase.instance.reference().child("Presence").child(format.format(_dateSelected));
    _addButton = new AddButton(dbTodayRef: dbRef, key: ValueKey(_userInAgenda));

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 227, 120, 48),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(160, 255, 255, 255),
          title: Row(

            children: [
              FlatButton(onPressed: () {Navigator.pop(widget.presenceContext);}, child: Icon(Icons.arrow_back)),
              Center(
                child: Text("APNQL - Horaire bureau", style: TextStyle(color: Colors.black),),
              )
            ],
          )
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                  child: Icon(Icons.remove),
                  onPressed: () {setState(() {
                    _dateSelected = _dateSelected.subtract(Duration(days: 1));
                  });},
                ),
                FlatButton(
                  child: Text(
                      formatShow.format(_dateSelected).toString(),
                      style: TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(255, 70, 0, 0),
                          fontWeight: FontWeight.w900
                      )
                  ),
                  onPressed: () {
                    DatePicker.showDatePicker(context,
                      minTime: DateTime(2019, 3, 5),
                      maxTime: DateTime(2021, 6, 7),
                      currentTime: _dateSelected,
                      locale: LocaleType.fr,

                      onChanged: (date) {
                      }, onConfirm: (date) {
                        setState(() {
                          _dateSelected = date;
                        });
                      },
                    );
                  },
                ),
                FlatButton(
                  child: Icon(Icons.add),
                  onPressed: () {setState(() {
                    _dateSelected = _dateSelected.add(Duration(days: 1));
                  });},
                ),
              ],
              //Text(format.format(_dateSelected).toString(),style: TextStyle(fontSize: 25)),
            ),
          ),
          Flexible(
            child: FirebaseAnimatedList(
              query: dbRef,
              padding: EdgeInsets.all(8.0),
              key: new ValueKey(_dateSelected),
              sort: (a, b) {
                return b.value["createdDate"].compareTo(a.value["createdDate"]);
              },
              itemBuilder: (_, DataSnapshot snapshot,
                  Animation<double> animation, int x) {
                bool _owner = (snapshot.key == _userName);
                //print(snapshot.key);
                AgendaItem _agendaItem = AgendaItem(
                  snapshot: snapshot,
                  dateSelected: _dateSelected,
                  userDeleted: this.userDeleted,
                  owner: _owner,
                );
                return _agendaItem;
              },

            ),
          ),
        ],
      ),
      floatingActionButton: _addButton,
    );
  }

  loadUserInfos() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName') ?? "";
    _userName = userName;
    if (userName != _userName) {
      Future<DataSnapshot> dbUser = FirebaseDatabase.instance.reference().child("users").child(userName).once();
      dbUser.then((value) {
        if (value.value != null) {
          setState(() {
            _userName = userName;
            _firstName = value.value["firstname"];
            _lastName = value.value["lastname"];
          });
        }
      });
      //Future<DataSnapshot> dbUserInfos = dbUser.once();
      //dbUser.then((value) => print(value.value));
      /*setState(() {
        _userName = userName;
      });*/
    }
  }

  void userDeleted(key) {
    setState(() {
      _userInAgenda = false;
    });
  }
}

class AgendaItem extends StatefulWidget {
  final DataSnapshot snapshot;
  final DateTime dateSelected;
  final Function userDeleted;
  final bool owner;

  const AgendaItem({ Key key, this.snapshot, this.dateSelected, this.owner, this.userDeleted}): super(key: key);
  @override
  _AgendaItemState createState() => _AgendaItemState();
}

class _AgendaItemState extends State<AgendaItem> {
  bool _selectedItem = false;
  var format = new DateFormat('yMd', "fr_CA");

  @override
  Widget build(BuildContext context) {
    String finalName = "";
    final value = widget.snapshot.value.values.first;


    var formatShow = new DateFormat('d MMMM y à H:m', "fr_CA");
    DataSnapshot sn = widget.snapshot;
    final DateTime _createDate = DateTime.fromMicrosecondsSinceEpoch(value["createdDate"] * 1000);
    return Card(
      elevation: 5,
      child: ListTile(
        title: FutureBuilder(
            future: writeName(widget.snapshot.key),
            builder: (context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Text(snapshot.data.toString(), style: TextStyle(fontWeight: FontWeight.w900));
              } else if (snapshot.connectionState == ConnectionState.none) {
                return Text("No data");
              }
              return CircularProgressIndicator();
            },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Text>[
            //Text(widget.snapshot.value["description"].toString(), style: TextStyle(color: Colors.black),),
            Text((formatShow.format(_createDate)), style: TextStyle(fontStyle: FontStyle.italic),),
          ],
        ),
        //isThreeLine: true,

        selected: _selectedItem,
        contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
        onTap: () {setState(() {_selectedItem = !_selectedItem;});},
        trailing: (widget.owner ?
        GestureDetector(
          onTap: () {_showDialog(widget.snapshot);},
          child: Container(
            child: Icon(Icons.remove_circle),
            padding: EdgeInsets.symmetric(horizontal: 5.0),
          ),
        ) : GestureDetector(
          onTap: () {_showDialog(widget.snapshot);},
          child: Container(
            child: Icon(Icons.do_not_touch),
            padding: EdgeInsets.symmetric(horizontal: 5.0),
          ),
        )),
      ),
    );
  }

  Future<String> writeName(String username) async {
    final dbUserRef = FirebaseDatabase.instance.reference().child("users").child(username);
    final DataSnapshot user = await dbUserRef.once();
    final String finalName = "${user.value["firstname"]} ${user.value["lastname"]}";
    return finalName;
  }

  void _showDialog(DataSnapshot snapshot) {
    TextStyle contentStyle = TextStyle(color: Color.fromARGB(255, 0, 40, 155));
    TextStyle elementStyle = TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text("Suppression de données"),
          content: RichText(
            text: TextSpan(
                children: <TextSpan>[
                  TextSpan(text: "Voulez-vous retirez ", style: contentStyle),
                  TextSpan(text: "${snapshot.value['name']}", style: elementStyle),
                  TextSpan(text: " ?", style: contentStyle),
                ]
            ),
          ),
          //content: Text("zVoulez-vous retire ${snapshot.value['name']}", style: TextStyle(fontWeight: FontWeight.bold),),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            FlatButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("Delete"),
              onPressed: () {
                setState(() {
                  _userInAgenda = false;
                });
                widget.userDeleted(snapshot.key);
                FirebaseDatabase.instance.reference().child("Presence").child(format.format(widget.dateSelected)).child(snapshot.key).remove();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class AddButton extends StatefulWidget {
  final DatabaseReference dbTodayRef;

  const AddButton({ Key key, this.dbTodayRef}): super(key: key);

  @override
  _AddButtonState createState() => _AddButtonState();
}

class _AddButtonState extends State<AddButton> {
  String _userChange = "";

  @override
  Widget build(BuildContext context) {
    Future<DataSnapshot> today = widget.dbTodayRef.once();

    return FutureBuilder(
      future: today,
      key: ValueKey(_dateSelected),

      builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {

        _userInAgenda = false;

        if(snapshot.hasData) {
          Map<dynamic, dynamic> values = snapshot.data.value;
          if(values != null) {
            values.forEach((key, value) {
              if (key == _userName) {
                _userInAgenda = true;
                return null;
              }
            });
          }
        }
        return !_userInAgenda ?
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  addPresenceToday(widget.dbTodayRef, true);
                },
                tooltip: 'Increment Counter',


                child: Text("AM"),
                backgroundColor: Color.fromARGB(180, 50, 50, 150),

              ),
              FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  addPresenceToday(widget.dbTodayRef, null);
                },
                tooltip: 'Increment Counter',
                backgroundColor: Color.fromARGB(200, 0, 0, 0),


                child: Text("All\nday", textAlign: TextAlign.center),

              ),
              FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  addPresenceToday(widget.dbTodayRef, false);
                },
                tooltip: 'Increment Counter',
                child: Text("PM"),
                backgroundColor: Color.fromARGB(180, 50, 50, 150),

              )
            ]
          ): Container();

      }
    );
  }

  void addPresenceToday(DatabaseReference dbTodayRef, bool am) {
    print(am);
    if (_userName != "") {
      var newTodayRef = dbTodayRef.child(_userName).push();
      newTodayRef.set({
        "am": am,
        "description": "Add with fullname",
        //"creationDate": DateTime.now().millisecond,
        "createdDate": ServerValue.timestamp,
      });
      setState(() {
        _userInAgenda = true;
      });
    }
  }
}


