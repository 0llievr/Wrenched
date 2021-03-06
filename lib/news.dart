import 'package:flutter/material.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/*
* Innactive code due to google play issues:
*
* News apps MUST:
* provide ownership information about the news publisher and its
* contributors including, but not limited to, the official website
* for the news published in your app, valid and verifiable contact information,
* and the original publisher of each article, and have a dedicated
* website or in-app page that is clearly labelled as containing
* contact information, is easy to find (e.g., linked at the bottom of
* the home page or in the site navigation bar), and provides valid contact
* information for the news publisher, including at least a contact
* email address and phone number.
* */


class News extends StatefulWidget {
  @override
  _News createState() => _News();
}

class _News extends State<News> {
  RssFeed _feed = RssFeed(); // RSS Feed Object
  List<RssItem> _items = [];


  @override
  void initState() {
    super.initState();
    getFeed();
  }
  
  getFeed() async{
    var response = await http.get(
        Uri.parse('https://www.pinkbike.com/pinkbike_xml_feed.php'));
    var channel = RssFeed.parse(response.body);

    //the items in the feed
    setState(() {
      _items = channel.items!;
    });
  }

  void _launchURL(String _url) async =>
      await canLaunch(_url) ? await launch(_url) : throw 'Could not launch $_url';

  @override
  Widget build(BuildContext context){
    return Scaffold(
        body: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(left: 60, right: 60, top: 45, bottom: 10),
                child: Image.asset('data/Images/Pinkbike.png'),
              ),

              _items.isNotEmpty
                  ? Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Text(DateFormat('EEEE\nMMM d').format(_items[index].pubDate!)),
                        title: Text(_items[index].title!),
                        //subtitle: Text(_items[index].!),
                        onTap:() => _launchURL(_items[index].link!),
                      ),
                    );
                  },
                ),
              )
                  : Container()
            ],
        ),
    );
  }
}