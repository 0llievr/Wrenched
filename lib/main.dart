import 'package:flutter/material.dart';
import 'package:wrenched/trails.dart';
import 'package:wrenched/service.dart';

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
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            height: 100.0,
            //color: Colors.blue[50],
          ),


          Container( //user Information
            height: 100,
            alignment: Alignment.center,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  child: Text('OL'),
                  radius: 50,
                ),
                Column(children: <Widget>[
                  Text('Oliver Lynch'),
                  Text('Daily milage: 2700'),
                  Text('Total milage: 2700'),
                  Text('last service : DATE')


                ])
              ]
            )
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
                child: const Text ("bike tab"),
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
            child: const Text ("trail information tab"),
          ),
        ),


          Container( //Bike news
            height: 100,
            alignment: Alignment.center,
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text ("bike news"),
          ),
        ],

      )
    );
  }
}


