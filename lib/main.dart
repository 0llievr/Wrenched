import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wrenched/trails.dart';
import 'package:wrenched/news.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';










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
      debugShowCheckedModeBanner: false,
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
  final _userFormKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();
  final _serviceFormKey = GlobalKey<FormState>();
  final String date = DateFormat('yMMMMd').format(DateTime.now()).toString();
  Position position = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0);

  Map<String, dynamic> userData = {
    "User" : "Oliver",
    "Total_mileage" : 0,
    "Service_mileage" : 0
  };
  List serviceData = [];

  List trailData = [];
  int closestTrail = 0;

  String? notes = "blablabla";

  @override
  void initState() {
    super.initState();

    //Hide Status bar in top of app
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays:[SystemUiOverlay.bottom]);

    getService();
    getLocation();
    getUser();
    getTrails();
  }

  //checks location permissions and asks if needed
  Future<void> getLocation() async{
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }
    position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      position;
    });
  }

  //get location of user writable storage since you cant write to asset file (data)
  Future<String> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    print(path);
    return path;
  }

  //gets user.json
  Future<void> getUser() async {
    final path = await _localFile;
    final contents = await File('$path/User.json').readAsString();
    final data = await json.decode(contents);
    setState(() {
      userData = data;
      print(userData);
    });
  }

  //gets service.json
  Future<void> getService() async {
    final path = await _localFile;
    final contents = await File('$path/maintenance.json').readAsString();
    final data = await json.decode(contents);
    setState(() {
      serviceData = data["Bike_maintenance"];
    });
  }

  //add item to list and write data to json
  Future<void> writeService() async{
    //Add new item to list
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["Maintenance_date"] = date;
    data["Maintenance_Notes"] = notes;
    data["Maintenance_Mileage"] = userData["Total_mileage"];

    serviceData.insert(0,data);

    //overwrite old json data
    var tmp = {};
    tmp["Bike_maintenance"] = serviceData;
    String tmpstr = json.encode(tmp);

    //local file io
    final path = await _localFile;
    final file = File('$path/maintenance.json');
    file.writeAsString(tmpstr);
  }

  //updates service.json
  Future<void> updateService() async{
    //overwrite old json data
    var tmp = {};
    tmp["Bike_maintenance"] = serviceData;
    String tmpstr = json.encode(tmp);

    //local file io
    final path = await _localFile;
    final file = File('$path/maintenance.json');
    file.writeAsString(tmpstr);
  }

  //gets trial.json
  Future<void> getTrails() async {
    final path = await _localFile;
    final contents = await File('$path/trails.json').readAsString();
    final data = await json.decode(contents);
    setState(() {
      trailData = data["Trails"];
    });
    getClosest();
  }

  //maps launcher
  launchMaps(double lat, double long, String name)async{
    MapsLauncher.launchCoordinates(lat,long,name);
  }

  //gets closest trail in trail.json
  Future<void> getClosest() async{
    var closest;
    double distance = 99999999999999;
    for( int i = 0; i < userData.length; i++){
      double distanceInMeters = Geolocator.distanceBetween(
          position.latitude, position.longitude, trailData[i]["Trail_latitude"], trailData[i]["Trail_longitude"]);
      if(distanceInMeters < distance){
        distance = distanceInMeters;
        closest = i;
      }
    }
    setState(() {
      closestTrail = closest;
    });
  }

  //add item to list and write data to user.json
  Future<void> writeUser() async{
    //overwrite old json data
    String tmpstr = json.encode(userData);

    //local file io
    final path = await _localFile;
    File('$path/User.json').writeAsString(tmpstr);

  }

  //pop up widget to add miles
  Widget addMiles(){
    return (AlertDialog(
      content: Stack(
        children: <Widget>[
          Form(
              key:_userFormKey,
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
                        onSaved: (value) {
                          int add = int.parse(value!);
                          userData["Total_mileage"] += add;
                          userData["Service_mileage"] += add;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        child: Text("Submit"),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey),
                        ),
                        onPressed: (){
                          final form = _userFormKey.currentState;
                          if (form!.validate()) {  //runs validate //the ! is a null check
                            form.save();
                            writeUser();
                            setState(() {userData;});//reload new data onto screen
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

  //pop up widget to edit service data
  Widget editWork(int index){
    return (AlertDialog(
      content: Stack(
        children: <Widget>[
          Form(
              key:_editFormKey,
              child: Column(mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: TextFormField(
                        initialValue: serviceData[index]["Maintenance_Notes"],
                        decoration: InputDecoration(labelText: 'Edit work'),
                        validator: (value) { //The validator receives the text that the user has entered.
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          } return null; },
                        onSaved: (value) {serviceData[index]["Maintenance_Notes"] = value;},
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
                              serviceData.removeAt(index);
                              updateService();
                              setState(() {});//reload new data onto screen
                              Navigator.of(context).pop();
                            },//on pressed
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            child: Text("Submit"),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey),
                            ),
                            onPressed: (){
                              final form = _editFormKey.currentState;
                              if (form!.validate()) {  //runs validate //the ! is a null check
                                form.save();
                                updateService();
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

  //pop up widget to view service data
  Widget viewWork(int index){
    return (AlertDialog(
      content: Column(
        children: <Widget>[
          Text(serviceData[index]["Maintenance_Mileage"].toString()),
          Text(serviceData[index]["Maintenance_Notes"])


        ],
      ),
    ));
  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            height: 15
          ),

          //Header
          Container( //user Information
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
                      Text(" Welcome back ${userData["User"]}"),
                      Text(" Miles since last service: ${userData["Service_mileage"].toString()}"),
                      Text(" Total miles ridden: ${userData["Total_mileage"].toString()}"),
                    ]
                )

              ]
            ),
          ),

          //Navigation buttons
          Container(
            child: Row(
              children: <Widget>[
                Expanded(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.pin_drop),
                    label: const Text('Trails'),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey),
                    ),
                    onPressed: (){Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>  Trails()),);},
                    onLongPress:() => launchMaps(trailData[closestTrail]["Trail_latitude"], trailData[closestTrail]["Trail_longitude"],trailData[closestTrail]["Trail_Name"]),
                  ),
                )),

                Expanded(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.star),
                    label: const Text('News'),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey),
                    ),
                    onPressed: (){Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>  News()),);},
                  )
                )),

                Expanded(child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Miles'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey),
                  ),
                  onPressed: () {showDialog(context: context, builder: (BuildContext context){
                    return addMiles();
                  }); },
                )
                )),
              ],
            ),
          ),


        //service list
        serviceData.isNotEmpty
          ? Expanded(
            child: ListView.builder(
              itemCount: serviceData.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    //leading: Text(service_data[index]["Maintenance_date"]),
                    title: Text(serviceData[index]["Maintenance_date"]),
                    subtitle: Text(serviceData[index]["Maintenance_Notes"]),
                    onTap: (){showDialog(context: context, builder: (BuildContext context){
                      return viewWork(index);
                    });},
                    onLongPress: (){showDialog(context: context, builder: (BuildContext context){
                      return editWork(index);
                    });},
                  ),
                );
              },
            ),
          )
          : Container(
          //add "no data welcome information"
        )
        ],
      ),


        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          onPressed: (){
            showDialog(context: context, builder: (BuildContext context){
              return (AlertDialog(
                content: Stack(
                  children: <Widget>[
                    Form(
                        key:_serviceFormKey,
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
                                    final form = _serviceFormKey.currentState;
                                    if (form!.validate()) {  //runs validate //the ! is a null check
                                      form.save();
                                      userData["Service_mileage"] = 0;
                                      writeService();
                                      setState(() {trailData;});//reload new data onto screen
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


