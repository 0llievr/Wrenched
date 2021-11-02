import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:io/ansi.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';

class Maintenance extends StatefulWidget {
  @override
  _Maintenance createState() => _Maintenance();
}

class _Maintenance extends State<Maintenance> {
  final _formKey = GlobalKey<FormState>();
  final _editformKey = GlobalKey<FormState>();

  final String date = DateFormat('yMMMMd').format(DateTime.now()).toString();
  List _items = []; //growable list
  String? notes = "blablabla";

  //get location of user writable storage since you cant write to asset file (data)
  //TODO: This only works for android, modify to also work with ios
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    print(path);
    return File('$path/maintenance.json');
  }

  //get file from documents
  Future<void> readJson() async {
    final file = await _localFile;
    final contents = await file.readAsString();
    final data = await json.decode(contents);
    setState(() {
      _items = data["Bike_maintenance"];
    });
  }

  //add item to list and write data to json
  Future<void> writeJson() async{
    //Add new item to list
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["Maintenance_date"] = date;
    data["Maintenance_Notes"] = notes;
    _items.add(data);

    //overwrite old json data
    var tmp = {};
    tmp["Bike_maintenance"] = _items;
    String tmpstr = json.encode(tmp);

    //local file io
    final file = await _localFile;
    file.writeAsString(tmpstr);
  }

  Future<void> updateJson() async{
    //overwrite old json data
    var tmp = {};
    tmp["Bike_maintenance"] = _items;
    String tmpstr = json.encode(tmp);

    //local file io
    final file = await _localFile;
    file.writeAsString(tmpstr);
  }

  Widget editWork(int index){
    return (AlertDialog(
      content: Stack(
        children: <Widget>[
          Form(
              key:_editformKey,
              child: Column(mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: TextFormField(
                        initialValue: _items[index]["Maintenance_Notes"],
                        decoration: InputDecoration(labelText: 'Edit work'),
                        validator: (value) { //The validator receives the text that the user has entered.
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          } return null; },
                        onSaved: (value) {_items[index]["Maintenance_Notes"] = value;},
                      ),
                    ),
                    Row( mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                      Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        child: Text("Delete"),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                        ),
                        onPressed: (){
                          _items.removeAt(index);
                          updateJson();
                          setState(() {});//reload new data onto screen
                          Navigator.of(context).pop();
                        },//on pressed
                      ),
                    ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          child: Text("Submit"),
                          onPressed: (){
                            final form = _editformKey.currentState;
                            if (form!.validate()) {  //runs validate //the ! is a null check
                              form.save();
                              updateJson();
                              setState(() {});//reload new data onto screen
                            }
                            Navigator.of(context).pop();
                          },//on pressed
                        ),
                      )],),

                  ]
              )
          )
        ],
      ),
    ));
  }


  @override
  void initState() {
    super.initState();
    //readJsonAsset();
    readJson(); //load in innital data
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(
        title: Text("Maintenance Page"),
        ),
        body: Column(
            children: <Widget>[// Display the data loaded from sample.json
              _items.isNotEmpty
                  ? Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        //leading: Text(_items[index]["Maintenance_date"]),
                        title: Text(_items[index]["Maintenance_date"]),
                        subtitle: Text(_items[index]["Maintenance_Notes"]),
                        onLongPress: (){showDialog(context: context, builder: (BuildContext context){
                          return editWork(index);
                        });},
                      ),
                    );
                  },
                ),
              )
                  : Container()
        ]),





    floatingActionButton: FloatingActionButton(
      onPressed: (){
        showDialog(context: context, builder: (BuildContext context){
          return (AlertDialog(
          content: Stack(
          children: <Widget>[
            Form(
                key:_formKey,
                child: Column(mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: TextFormField(
                        decoration: InputDecoration(labelText: 'Enter work done'),
                        validator: (value) { //The validator receives the text that the user has entered.
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          } return null; },
                        onSaved: (value) {notes = value;},
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        child: Text("Submit"),
                        onPressed: (){
                          final form = _formKey.currentState;
                          if (form!.validate()) {  //runs validate //the ! is a null check
                            form.save();
                            writeJson();
                            setState(() {});//reload new data onto screen
                          }
                          Navigator.of(context).pop();
                          },//on pressed
                      ),
                    )
                  ]
                )
            )
          ],
          ),
          ));
      });
    }, //on pressed
      child: const Icon(Icons.add),
    )
    );
  }
}