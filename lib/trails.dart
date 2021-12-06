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
import 'package:weather/weather.dart';

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

class Trails extends StatefulWidget {
  const Trails({Key? key}) : super(key: key);

  @override
  _Trails createState() => _Trails();
}

class _Trails extends State<Trails> {
  final _formKey = GlobalKey<FormState>();
  final String date = DateFormat('yMMMMd').format(DateTime.now()).toString();
  WeatherFactory wf = new WeatherFactory("e5cd94249035e1dc2c3203aaeecf7a45");
  List _items = []; //growable list
  String location = "There was an error, try again"; //unused
  String? name = "blablabla";
  double latitude = 37.077760;
  double longitude = -121.843640;
  final Set<Marker> _markers = {};
  Position position = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0);
  List<Weather> weather = [];
  bool load = false;
  String temperature = "Temp";
  String condition = "Condition";

  final Completer<GoogleMapController> _mapController = Completer();

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

    Weather w = await wf.currentWeatherByLocation(latitude, longitude);


    setState(() {
      position;
      location = position.toString(); //can delete this
      latitude = position.latitude;
      longitude = position.longitude;
      weather = [w];
      condition = w.weatherDescription!;
      temperature = w.tempFeelsLike.toString();
      load = true;
    });
    getDistance();
  }

  //get location of user writable storage since you cant write to asset file (data)
  Future<String> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
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
  }

  //add item to list and write data to json
  Future<void> writeJson() async{
    //Add new item to list
    final Map<String, dynamic> data = <String, dynamic>{};
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
    for( int i = 0; i < _items.length; i++){
      double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude, _items[i]["Trail_latitude"], _items[i]["Trail_longitude"]);
        _items[i]["Trail_Distance"] = distance;
    }
    setState(() {_items;});
  }

  //pop up widget to edit service data
  Widget AddTrail(){
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
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'Trail name'),
                            validator: (value) { //The validator receives the text that the user has entered.
                              if (value == null || value.isEmpty) {
                                return 'Please give the trial a name';
                              } return null; },
                            onSaved: (value) {name = value;},
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey)),
                            child: const Text("Submit"),
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
  }

  @override
  void initState() {
    super.initState();
    getLocation();
    readJson(); //load in inital data
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
        body: OrientationBuilder( //to notice landscape mode
          builder: (context, orientation){
            if(orientation == Orientation.portrait){
              return Column( children: <Widget>[// Display the data loaded from sample.json
                Container(
                  height:  MediaQuery.of(context).size.height/3,
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(8),

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
                  ),
                ),

                load //dont load if map hasnt loaded
                ? Padding(padding: EdgeInsets.symmetric(vertical: 5), child:Container(
                  child:Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.black12,
                      ),
                      height: 40,
                      width: MediaQuery.of(context).size.width/1.5,
                      child:Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                        Text("Latitude:  ${position.latitude.toStringAsFixed(3)} \n"
                            "Longitude:  ${position.longitude.toStringAsFixed(3)}",
                            textAlign: TextAlign.left),

                        Text("$condition\n$temperature", textAlign: TextAlign.right,),
                      ]),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Trail'),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey),
                      ),
                      onPressed: () {showDialog(context: context, builder: (BuildContext context){
                        return AddTrail();
                      });},
                    )
                  ])
                ),)
                : Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Container(
                      decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.black12,
                    ),
                    height: 40,
                    width: MediaQuery.of(context).size.width/1.5,
                    child:Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const <Widget>[
                          Text("Fetching location...", textAlign: TextAlign.center,style: TextStyle(fontSize: 27)),
                        ])),
                ),


                _items.isNotEmpty
                  ? Expanded(
                    child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index].toString();
                        return Dismissible(
                          key: Key(item),
                          direction: DismissDirection.endToStart,
                          onDismissed: (startToEnd) {
                            // Remove the item from the data source.
                            setState(() {
                              _items.removeAt(index);
                              updateJson();
                              _items;
                            });
                          },
                          background: Card(
                            margin: const EdgeInsets.all(10),
                            color: Colors.red,
                            child:  Row(mainAxisAlignment: MainAxisAlignment.end, children: const <Widget>[
                              Padding(padding: EdgeInsets.all(10.0),
                              child: Text("Delete", style: TextStyle(fontSize: 25))),
                            ] ),
                          ),

                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Padding(padding: EdgeInsets.symmetric(vertical: 5),
                            child:ListTile(
                              title: Text(_items[index]["Trail_Name"]),
                              subtitle: Text("Latitude ${_items[index]["Trail_latitude"]}\nLongitude${_items[index]["Trail_longitude"]} "),
                              trailing: Text("Distance \n${(_items[index]["Trail_Distance"]/1000).toStringAsFixed(1)}km",
                                textAlign: TextAlign.center,
                              ),
                              onTap: () => updateMapCam(_items[index]["Trail_latitude"],_items[index]["Trail_longitude"]),
                              onLongPress:() => launchMaps(_items[index]["Trail_latitude"],_items[index]["Trail_longitude"],_items[index]["Trail_Name"]),
                            ),))
                        );
                      },
                    ),
                  )
                :Column( children: <Widget>[
                  Container(
                      height: 50
                  ),
                  const Text("Welcome to the Trail Saver"),
                  const Text("To save a trail press the plus button below"),
                  const Text("Press and hold to launch navigation"),
                  const Text("swipe left delete"),
                  const Text("tap to center on map"),
                  const Text("Rotate landscape for big map mode"),
                ],)
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
    );
  }
}