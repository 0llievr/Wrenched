// Wrenched
// Oliver Lynch
// September 2021
// Api code for strava

// Client_id: 71354
// Client_secret: be03e1252d6c0c348fcc546db66dc58fc5cdf673
// Oliver ID: 47158111


import 'package:oauth2_client/access_token_response.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class Strava{
  //variables
  var response;

  //oAuth2
  authenticate() async{
    response = await http.get( //works but flutter blocks splash screen
      Uri.parse('http://www.strava.com/oauth/mobile/authorize?client_id=71354&redirect_uri=https://www.developers.strava.com/&response_type=code&approval_prompt=auto&scope=activity:read'),
    );

    if (response != null){ // && response.statusCode == 200) {
      var result = await json.decode(response.body);
      print(result);
    }
  }

  getAccessToken() async{
    response = await http.post(
      Uri.parse('https://www.strava.com/oauth/token'),
      headers:{
        'client_id': "71354",
        'client_secret': "be03e1252d6c0c348fcc546db66dc58fc5cdf673",
        'code': "no gots",
        'grant_type': "authorization_code"
      }
    );
  }
}