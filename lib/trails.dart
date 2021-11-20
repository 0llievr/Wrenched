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

/*
* trails.json
* Trails : [
*   {
*     Trail_Name
*     Trail_Location
*     Trail_latitude
*     Trail_longitude
*     Trail_Distance
*   },
*   {
*     ...
*   },
* ]
*
*/

//Todo:: make swipe to go back work on android

class Trails extends StatefulWidget {
  @override
  _Trails createState() => _Trails();
}

class _Trails extends State<Trails> {
  final _formKey = GlobalKey<FormState>();
  final String date = DateFormat('yMMMMd').format(DateTime.now()).toString();
  List _items = []; //growable list
  String location = "There was an error, try again";
  String? name = "blablabla";
  double latitude = 37.42796133580664;
  double longitude = -122.085749655962;
  Set<Marker> _markers = {};
  Position position = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0);

  Completer<GoogleMapController> _mapController = Completer();

  Future<CameraPosition> camPos() async{
    return CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: 14.4746,
    );
  }

  updateMapCam(double lat, double long) async {
    var newPosition = CameraPosition(
      target: LatLng(lat, long),
      zoom: 16,
    );
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(newPosition));
    //_mapController.moveCamera(update);

  }

  void showPinsOnMap() async {
      for(int i=0; i<_items.length; i++){
        _markers.add(Marker(
            markerId: MarkerId(_items[i]["Trail_Name"]),
            position: LatLng(_items[i]["Trail_latitude"],_items[i]["Trail_longitude"]),
            infoWindow: InfoWindow(title: _items[i]["Trail_Name"] )
            //ontap: //popup with info
        ));
     }
      setState(() {
        _markers;
      });
  }

  launchMaps(double lat, double long, String name)async{
    MapsLauncher.launchCoordinates(lat,long,name);
  }


  Future<void> getLocation() async{
    position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    updateMapCam(position.latitude, position.longitude);

    setState(() {
      //move google maps location campos()
      position;
      location = position.toString();
      latitude = position.latitude;
      longitude = position.longitude;
    });
    readJson();
  }

  //get location of user writable storage since you cant write to asset file (data)
  Future<String> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    print(path);
    return path;
  }

  //get file from documents
  Future<void> readJson() async {
    final path = await _localFile;
    final contents = await File('$path/trails.json').readAsString();
    final data = await json.decode(contents);
    setState(() {
      _items = data["Trails"];
    });
    showPinsOnMap();
    getDistance();
  }

  //add item to list and write data to json
  Future<void> writeJson() async{
    //Add new item to list
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["Trail_Name"] = name;
    data["Trail_Location"] = location;
    data["Trail_latitude"] = latitude;
    data["Trail_longitude"] = longitude;
    data["Trail_Distance"] = 0.0;


    _items.insert(0,data);

    //overwrite old json data
    var tmp = {};
    tmp["Trails"] = _items;
    String tmpstr = json.encode(tmp);

    //local file io
    final path = await _localFile;
    File('$path/trails.json').writeAsString(tmpstr);

    showPinsOnMap();
  }

  //add item to list and write data to json
  Future<void> updateJson() async{
    //overwrite old json data
    var tmp = {};
    tmp["Trails"] = _items;
    String tmpstr = json.encode(tmp);

    //local file io
    final path = await _localFile;
    File('$path/trails.json').writeAsString(tmpstr);

    showPinsOnMap();
  }


  Future<void> getDistance() async{
    //await getLocation();
    double distance = 0;
    for( int i = 0; i < _items.length; i++){
      double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude, _items[i]["Trail_latitude"], _items[i]["Trail_longitude"]);
      print(distance);
        _items[i]["Trail_Distance"] = distance;
        setState(() {_items;});
    }
  }

  @override
  void initState() {
    super.initState();
    getLocation();
    //readJson(); //load in inital data
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
        body: OrientationBuilder( //to notice landscape mode
          builder: (context, orientation){
            if(orientation == Orientation.portrait){
              return Column(
                  children: <Widget>[// Display the data loaded from sample.json
                    Container(
                      height:  MediaQuery.of(context).size.height/3,
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.all(8),

                      child: GoogleMap(
                        mapType: MapType.satellite,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(latitude, longitude),
                          zoom: 14.4746,
                        ),
                        markers: _markers,
                        myLocationEnabled: true,
                        compassEnabled: true,
                        buildingsEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled : false,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController.complete(controller);
                        },
                      ),),


                    _items.isNotEmpty
                        ? Expanded(
                      child: ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: EdgeInsets.all(10),


                            child: ListTile(

                              title: Text(_items[index]["Trail_Name"]),
                              subtitle: Text(_items[index]["Trail_Location"]),
                              trailing: Text("Distance \n${(_items[index]["Trail_Distance"]/1000).toStringAsFixed(1)}km",
                                textAlign: TextAlign.center,
                              ),
                              onTap: () => updateMapCam(_items[index]["Trail_latitude"],_items[index]["Trail_longitude"]),
                              onLongPress:() => launchMaps(_items[index]["Trail_latitude"],_items[index]["Trail_longitude"],_items[index]["Trail_Name"]),
                            ),
                          );
                        },
                      ),
                    )
                        :  Column(
                      children: <Widget>[
                        Container(
                            height: 50
                        ),
                        const Text("Welcome to the Trail Saver"),
                        const Text("To save a trail press the plus button below"),
                        const Text("Press and hold to launch navigation"),
                        const Text("tap to center on map"),
                        const Text("Rotate landscape for big map mode"),





                      ],
                    )
                  ]);
            }else{ //if landscape
              return GoogleMap(
                mapType: MapType.satellite,
                initialCameraPosition: CameraPosition(
                  target: LatLng(latitude, longitude),
                  zoom: 16,
                ),
                markers: _markers,
                myLocationEnabled: true,
                compassEnabled: true,
                buildingsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled : false,
                onMapCreated: (GoogleMapController controller) {
                  _mapController.complete(controller);
                },
              );
            }
          },
        ),





        //TODO:make unavaliable untill map gps location is recieved
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          onPressed: (){
            showDialog(context: context, builder: (BuildContext context){
              return (AlertDialog(
                content: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child:Stack(
                  children: <Widget>[
                    Form(
                        key:_formKey,
                        child: Column(mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: TextFormField(
                                  decoration: InputDecoration(labelText: 'Enter trail name'),
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
                                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey)),
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
                ),)
              ));
            });
          }, //on pressed
          child: const Icon(Icons.add),
        )
    );
  }
}