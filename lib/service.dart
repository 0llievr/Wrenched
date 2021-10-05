import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class Maintenance extends StatefulWidget {
  @override
  _Maintenance createState() => _Maintenance();
}

class _Maintenance extends State<Maintenance> {
  final _formKey = GlobalKey<FormState>();
  List _items = [];


  //Get data from json
  Future<void> readJson() async{
    final String response = await rootBundle.loadString('data/maintenance.json');
    final data = await json.decode(response);
    setState(() {
      _items = data["Bike_maintenance"];
    });
  }


  @override
  void initState() {
    super.initState();
    readJson();
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
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: CircleAvatar(
                  child: Icon( Icons.close),
                  backgroundColor: Colors.red,
                ),),),
                Form(
                  key:_formKey,
                  child: Column(mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: TextFormField(),
                    ),
                  ])
                )
                ],
                ),
                ));
    });
    },
      child: const Icon(Icons.add),
    )
    );
  }
}