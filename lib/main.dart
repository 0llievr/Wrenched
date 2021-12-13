import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:wrenched/trails.dart';
import 'package:wrenched/news.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:image_picker/image_picker.dart';


/*
* maintenance.json
* Bike_maintenance : [
*   {
*      Maintenance_date : string
*      Maintenance_Notes : string
*      Maintenance_Mileage: int
*      Maintenance_Mileage_Total: int
*      Maintenance_Cost : double
*      Maintenance_shop : bool
*   },
*   {
*     ...
*   }
* ]
*
* user.json
* {
*   User
*   Total_mileage
*   Service_mileage
*
* }
*
*/

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
        primarySwatch: Colors.blueGrey,
      ),
      darkTheme: ThemeData.dark(),
      //themeMode: ThemeMode.dark, //force darkmode
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
  final _userNameFormKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();
  final _serviceFormKey = GlobalKey<FormState>();
  final String date = DateFormat('yMMMMd').format(DateTime.now()).toString();
  final ImagePicker _picker = ImagePicker();
  Position position = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0);

  File basicImage = File("");

  Map<String, dynamic> userData = {
    "User" : "",
    "Total_mileage" : 0,
    "Service_mileage" : 0,
  };

  List serviceData = [];
  List trailData = [];
  int closestTrail = 0;
  String? notes = "blablabla";
  bool shopWork = false;
  double cost = 0;

  @override
  void initState() {
    super.initState();

    //Hide Status bar in top of app
    //SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays:[SystemUiOverlay.bottom]);

    getService();
    getLocation();
    getUser();
    getTrails();
  }

  //UNUSED: get image for profile photo
  Future<void> pickImage() async{
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if(image != null){
      File imageFile = File(image.path);
      final path = await _localFile;
      await imageFile.copy('$path/profile_image.png'); //copies to local mem
      setState(() {
        basicImage = imageFile;
      });
    }
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
    return path;
  }

  //gets user.json
  Future<void> getUser() async {
    final path = await _localFile;
    final contents = await File('$path/User.json').readAsString();
    final data = await json.decode(contents);
    setState(() {
      userData = data;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data["Maintenance_date"] = date;
    data["Maintenance_Notes"] = notes;
    data["Maintenance_Mileage"] = userData["Service_mileage"];
    data["Maintenance_Mileage_Total"] = userData["Total_mileage"];
    data["Maintenance_Cost"] = 0;
    data["Maintenance_shop "] = false;

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
    await getLocation();
    int closest = 0;
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
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Add miles'),
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
                        child: const Text("Submit"),
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
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        keyboardType: TextInputType.text,
                        initialValue: serviceData[index]["Maintenance_date"],
                        decoration: const InputDecoration(labelText: 'Edit date'),
                        validator: (value) { //The validator receives the text that the user has entered.
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          } return null; },
                        onSaved: (value) {serviceData[index]["Maintenance_date"] = value;},
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        minLines: 1,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        initialValue: serviceData[index]["Maintenance_Notes"],
                        decoration: const InputDecoration(labelText: 'Edit work'),
                        validator: (value) { //The validator receives the text that the user has entered.
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          } return null; },
                        onSaved: (value) {serviceData[index]["Maintenance_Notes"] = value;},
                      ),
                    ),

                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            child: const Text("Submit"),
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
                        )
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
      title: Text( serviceData[index]["Maintenance_date"].toString(), style: const TextStyle(fontSize: 25), textAlign: TextAlign.center,),
      content:SizedBox(
        height: 250,
        child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly ,children: <Widget>[

            Expanded(child:Padding( padding: const EdgeInsets.all(8.0),child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.blueGrey,
              ),
              child:Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(children: <Widget>[
                    const Text("Service Miles:", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white),),
                    Text(serviceData[index]["Maintenance_Mileage"].toString(), style: const TextStyle(fontSize: 22,color: Colors.white),),
              ]))),
            )),

            Expanded(child:Padding( padding: const EdgeInsets.all(8.0),child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.blueGrey,
                ),
                child:Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(children: <Widget>[
                      const Text("Total Miles:", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white),),
                      Text(serviceData[index]["Maintenance_Mileage_Total"].toString(), style: const TextStyle(fontSize: 22, color: Colors.white),),
                    ]))),
            )),
          ]),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.black12,
            ),
            height: 155,
            width: 300,
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.all(10.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Expanded(
                child: SingleChildScrollView( scrollDirection: Axis.vertical, child: Text(serviceData[index]["Maintenance_Notes"]))
            ),]),),],
    ),),
    ));
  }

  //pop up widget to add service data
  Widget addWork(){
    return (AlertDialog(
      content: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child:Stack(
        children: <Widget>[
          Form(
              key:_serviceFormKey,
              child: Column(mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding( //Notes
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        minLines: 1,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(labelText: 'Service notes'),
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
                        style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey)),
                        child: const Text("Submit"),
                        onPressed: (){
                          final form = _serviceFormKey.currentState;
                          if (form!.validate()) {  //runs validate //the ! is a null check
                            form.save();
                            writeService();
                            userData["Service_mileage"] = 0;
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
      ),)
    ));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
        children: <Widget>[
          Container( //for notches
            height: 30,
          ),
          //Header
          Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.black12,
              ),
              height: 100,
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.centerLeft,
            margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 15), child:Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,

                children: <Widget>[
                  Text("${userData["User"]}",style: const TextStyle(fontSize: 30)),
                  Text(" Serviceable miles: ${userData["Service_mileage"].toString()}",style: const TextStyle(fontSize: 17)),
                  Text(" Total miles: ${userData["Total_mileage"].toString()}",style: const TextStyle(fontSize: 17)),
                ]
              ))
          ),

          //Navigation buttons
          Row(
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
                    MaterialPageRoute(builder: (context) =>  const Trails()),);},
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


        //service list
        serviceData.isNotEmpty
          ? Expanded(
            child: ListView.builder(
              itemCount: serviceData.length,
              itemBuilder: (context, index) {
                final item = serviceData[index].toString();
                return Dismissible(
                key: Key(item),
                  direction: DismissDirection.endToStart,
                  onDismissed: (startToEnd) {
                    // Remove the item from the data source.
                    setState(() {
                      if( index == 0) {
                        userData["Service_mileage"] = serviceData[index]["Maintenance_Mileage"];
                      }else{
                        serviceData[index-1]["Maintenance_Mileage"] += serviceData[index]["Maintenance_Mileage"];
                      }
                      serviceData.removeAt(index);
                      updateService();
                      serviceData;
                    });
                  },

                  background: Card(
                    margin: const EdgeInsets.all(10),
                    color: Colors.red,
                    child:  Row(mainAxisAlignment: MainAxisAlignment.end, children: const <Widget>[
                      Padding(padding: EdgeInsets.all(10.0),
                        child: Text("Delete", style: TextStyle(fontSize: 25))),
                    ]),
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                        //leading: Text(service_data[index]["Maintenance_date"]),
                        title: Text(serviceData[index]["Maintenance_date"]),
                        subtitle: Text(serviceData[index]["Maintenance_Notes"], maxLines: 3,),
                        onTap: (){showDialog(context: context, builder: (BuildContext context){
                          return viewWork(index);
                        });},
                        onLongPress: (){showDialog(context: context, builder: (BuildContext context){
                          return editWork(index);
                        });},
                    ),)
                  );
              },
            ),
          )

          //else if no data
          : Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Form(
                  key:_userNameFormKey,
                  child: Column(mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: TextFormField(
                            keyboardType: TextInputType.name,
                            decoration: const InputDecoration(labelText: 'What bike are we working on?'),
                            validator: (value) { //The validator receives the text that the user has entered.
                              if(value !=null && value.length > 15){
                                return'Bike name is too long';
                              }return null;},
                            onSaved: (value) {userData["User"] = value; writeUser();},
                          ),
                        ),

                        ElevatedButton(
                          style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey)),
                          child: const Text("Submit"),
                          onPressed: (){
                            final form = _userNameFormKey.currentState;
                            if (form!.validate()) {  //runs validate //the ! is a null check
                              form.save();
                              setState(() {userData;});//reload new data onto screen
                            }
                          },//on pressed
                        ),
                      ]
                  )
              ),
              Container(
                  height: 50
              ),
              const Text("To add service press the plus button below"),
              const Text("Press and hold to edit"),
              const Text("Tap to view details"),
              const Text("swipe left delete"),




          ],
        )
        ],
      ),


        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          onPressed: (){
            showDialog(context: context, builder: (BuildContext context){
              return (addWork());
          }); //on
          },// pressed
          child: const Icon(Icons.add),
        )
    );
  }
}


