import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_launcher/maps_launcher.dart';


class Trails extends StatefulWidget {
  @override
  _Trails createState() => _Trails();
}

class _Trails extends State<Trails> {
  final _formKey = GlobalKey<FormState>();
  final String date = DateFormat('yMMMMd').format(DateTime.now()).toString();
  List _items = []; //growable list
  String location = "blablabla";
  String? name = "blablabla";
  double latitude = 37.42796133580664;
  double longitude = -122.085749655962;
  Set<Marker> _markers = {};
  Position position = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0);

  Completer<GoogleMapController> _controller = Completer();
/*
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(latatude, longitude),
    zoom: 14.4746,
  );
*/

  void showPinsOnMap() async {
      for(int i=0; i<_items.length; i++){
        _markers.add(Marker(
            markerId: MarkerId(_items[i]["Trail_Name"]),
            position: LatLng(_items[i]["Trail_latitude"],_items[i]["Trail_longitude"]),
        ));
     }
      setState(() {
        _markers;
      });
  }

  launchMaps(double lat, double long)async{
    MapsLauncher.launchCoordinates(lat,long);
  }


  Future<void> getLocation() async{
    //TODO: clean this up, Modify to work for ios aswell
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
      location = position.toString();
      latitude = position.latitude;
      longitude = position.longitude;
    });
  }

  //get location of user writable storage since you cant write to asset file (data)
  //TODO: This only works for android, modify to also work with ios
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    print(path);
    return File('$path/trails.json');
  }

  //get file from documents
  Future<void> readJson() async {
    final file = await _localFile;
    final contents = await file.readAsString();
    final data = await json.decode(contents);
    setState(() {
      _items = data["Trails"];
    });
  }

  //add item to list and write data to json
  Future<void> writeJson() async{
    //Add new item to list
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["Trail_Name"] = name;
    data["Trail_Location"] = location;
    data["Trail_latitude"] = latitude;
    data["Trail_longitude"] = longitude;


    _items.add(data);

    //overwrite old json data
    var tmp = {};
    tmp["Trails"] = _items;
    String tmpstr = json.encode(tmp);

    //local file io
    final file = await _localFile;
    file.writeAsString(tmpstr);

    showPinsOnMap();
  }

  @override
  void initState() {
    super.initState();
    getLocation();
    readJson(); //load in innital data
    showPinsOnMap();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(
          title: Text("Trails"),
        ),
        body: Column(
            children: <Widget>[// Display the data loaded from sample.json
              Container(
                  height:  MediaQuery.of(context).size.height/3,
                  width: MediaQuery.of(context).size.width,
                child: GoogleMap(
                  mapType: MapType.hybrid,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(latitude, longitude),
                    zoom: 14.4746,
                  ),
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
              ),),
              Container(
                height: 30,
                child: Text(position.toString()),
              ),
              _items.isNotEmpty
                  ? Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        //leading: Text(_items[index]["Maintenance_date"]),
                        title: Text(_items[index]["Trail_Name"]),
                        subtitle: Text(_items[index]["Trail_Location"]),
                        onLongPress:() => launchMaps(_items[index]["Trail_latitude"],_items[index]["Trail_longitude"]),
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
                    Positioned(
                      right: -40.0,
                      top: -40.0,
                      child: InkResponse(
                        onTap: () { Navigator.of(context).pop(); },
                        child: CircleAvatar(
                          child: Icon( Icons.close),
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
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
                                  onSaved: (value) {name = value;},
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