import 'package:flutter/material.dart';
import 'package:wrenched/trails.dart';
import 'package:wrenched/service.dart';
import 'package:wrenched/news.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'wrenched',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData.dark(),
      home: const MyHomePage(title: 'Wrenched Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _items = {
    "User" : "Oliver",
    "Total_mileage" : 0,
    "Weekly_mileage" : 0,
  };
  Map<String, dynamic> service_data = {
    "Maintenance_date" : "No recent service",
    "Maintenance_Notes" : "Input service to see it here"
  };
  Map<String, dynamic> trail_data = {
    "Trail_Name" : "No trails saved",
    "Trail_Location" : "",
    "Trail_latitude" : "",
    "Trail_longitude" : ""

  };


  @override
  void initState() {
    super.initState();
    getUser();
    getService();
    getTrails();
  }

//get location of user writable storage since you cant write to asset file (data)
//TODO: This only works for android, modify to also work with ios
  Future<String> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    print(path);
    return path;
  }

//get file from documents
  Future<void> getUser() async {
    final path = await _localFile;
    final contents = await File('$path/User.json').readAsString();
    final data = await json.decode(contents);
    setState(() {
      _items = data;
      print(_items);
    });
  }

  Future<void> getService() async {
    final path = await _localFile;
    final contents = await File('$path/maintenance.json').readAsString();
    final data = await json.decode(contents);
    setState(() {
      service_data = data["Bike_maintenance"].last;
    });
  }

  Future<void> getTrails() async {
    final path = await _localFile;
    final contents = await File('$path/trails.json').readAsString();
    final data = await json.decode(contents);
    setState(() {
      trail_data = data["Trails"][1];
    });
  }

//add item to list and write data to json
  Future<void> writeUser() async{
    //overwrite old json data
    String tmpstr = json.encode(_items);

    //local file io
    final path = await _localFile;
    File('$path/User.json').writeAsString(tmpstr);

  }


  Widget addMiles(){
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
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Add total miles'),
                        validator: (value) { //The validator receives the text that the user has entered.
                          if (value == null || value.isEmpty) {
                            return 'Please enter miles';
                          } return null; },
                        onSaved: (value) {_items["Total_mileage"] += int.parse(value!);},
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
                            writeUser();
                            setState(() {_items;});//reload new data onto screen
                            Navigator.of(context).pop();
                          }
                        },//on pressed
                      ),
                    )
                  ]
              )
          )
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,

        children: <Widget>[
          Container(
            height: 50.0,
            //color: Colors.blue[50],
          ),


        InkWell(
          onTap: () {showDialog(context: context, builder: (BuildContext context){
            return addMiles();
          });
          },
          child: Container( //user Information
            height: 100,
            alignment: Alignment.center,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                CircleAvatar(
                  child: Text('OL'),
                  radius: 50,
                ),
                Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text(" Welcome back ${_items["User"]}"),
                      Text(" Weekly miles: ${_items["Weekly_mileage"].toString()}"),
                      Text(" Total miles ridden: ${_items["Total_mileage"].toString()}")
                    ]
                )
              ]
            )
          ),
        ),

        InkWell(
          onTap: () {Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  Maintenance()),);},
          child: Container( //Bike information
              height: 100,
              alignment: Alignment.center,
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child:Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text("Service", style: TextStyle( fontSize: 15 )),
                  Text ("Last service Date: ${service_data["Maintenance_date"]} "),
                  Text("Service notes: ${service_data["Maintenance_Notes"]}"),
              ],)
            ),
        ),

        InkWell(
          onTap: () {Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  Trails()),);},
          child: Container( //Trail information
            height: 100,
            alignment: Alignment.center,
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text("Trails", style: TextStyle( fontSize: 15 )),
                  Text ("${trail_data["Trail_Name"]}"),
                ],
            ),
          ),
        ),

        InkWell(
          onTap: () {Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  News()),);},
          child: Container( //Bike news
            height: 100,
            alignment: Alignment.center,
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text ("Recent_news"),
          ),
        ),
        ],
      ),
    );
  }
}


