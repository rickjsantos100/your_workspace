import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:your_workspace/widgets/playlist_selector.dart';
import 'package:your_workspace/widgets/profile_selector.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  // void _incrementCounter() {
  //   setState(() {
  //     // This call to setState tells the Flutter framework that something has
  //     // changed in this State, which causes it to rerun the build method below
  //     // so that the display can reflect the updated values. If we changed
  //     // _counter without calling setState(), then the build method would not be
  //     // called again, and so nothing would appear to happen.
  //     _tabController = TabController(length: 3, vsync: this);
  //   });
  // }

  double _lightsValue = 1;
  double _temperatureValue = 22;
  String _accessToken = 'no_token';
  dynamic playlists = [];

  // Object type
  /*
  {
    username: 
    lightValue:
    tempValue
    spotifyId:
    spotifyPlaylistId:
  }
  */
  var users = [];
  int userIndex = 0;
  String spotifyId = 'none';
  String spotifyPlaylistId = 'none';

  @override
  initState() {
    super.initState();

    http.post(Uri.parse('https://accounts.spotify.com/api/token'), headers: {
      HttpHeaders.authorizationHeader: CLIENT_CREDENTIALS_AUTH,
      HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
    }, body: {
      'grant_type': 'client_credentials'
    }).then((responseHTTP) {
      dynamic response = jsonDecode(responseHTTP.body);
      setState(() {
        _accessToken = response['access_token'];
        switchUser(userIndex);
      });
    });

    // MOCK getting info from backend
    users = [
      {
        'username': 'aaaa',
        'lightValue': 1,
        'temperatureValue': 33,
        'spotifyId': 't8awcrzi144aabwemfihklc7m',
        'spotifyPlaylistId': '266opC1QggK58tOCf6iTJa',
      },
      {
        'username': 'bbbbbbb',
        'lightValue': 3,
        'temperatureValue': 27,
        'members': ['aaaa']
      },
    ];
  }

  switchUser(index) {
    setState(() {
      if (userIndex != index) {
        userIndex = index;
      }

      _lightsValue = users[index]['lightValue'].toDouble();
      _temperatureValue = users[index]['temperatureValue'].toDouble();

      if (users[index]['spotifyId'] != null) {
        spotifyId = users[index]['spotifyId'];

        getUserPlaylists(spotifyId);

        if (users[index]['spotifyPlaylistId'] != null) {
          spotifyPlaylistId = users[index]['spotifyPlaylistId'];
        } else {
          spotifyPlaylistId = 'none';
        }
      } else {
        resetSpotifyInfo();
      }
    });
  }

  resetSpotifyInfo() {
    setState(() {
      spotifyPlaylistId = 'none';
      playlists = [];
      spotifyId = 'none';
    });
  }

  List<DropdownMenuItem<String>> get playlistsItems {
    List<DropdownMenuItem<String>> menuItems = [
      for (var playlist in playlists)
        DropdownMenuItem(child: Text(playlist['name']), value: playlist['id']),
    ];
    return menuItems;
  }

  getUserPlaylists(String spotifyId) async {
    Response responseHTTP = await http.get(
        Uri.parse('https://api.spotify.com/v1/users/$spotifyId/playlists'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $_accessToken',
          HttpHeaders.contentTypeHeader: 'application/json',
        });

    dynamic response = jsonDecode(responseHTTP.body);
    setState(() {
      playlists = response['items'];
      if (spotifyPlaylistId == 'none') {
        spotifyPlaylistId = playlists[0]['id'];
      }
      spotifyId = spotifyId;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Container(
              margin: const EdgeInsets.only(left: 15, top: 40),
              child: Column(
                // Column is also a layout widget. It takes a list of children and
                // arranges them vertically. By default, it sizes itself to fit its
                // children horizontally, and tries to be as tall as its parent.
                //
                // Invoke "debug painting" (press "p" in the console, choose the
                // "Toggle Debug Paint" action from the Flutter Inspector in Android
                // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
                // to see the wireframe for each widget.
                //
                // Column has various properties to control how it sizes itself and
                // how it positions its children. Here we use mainAxisAlignment to
                // center the children vertically; the main axis here is the vertical
                // axis because Columns are vertical (the cross axis would be
                // horizontal).

                // mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: [
                      for (var i = 0; i < users.length; i++)
                        ProfileSelector(
                            isTeam: users[i]['members'] != null,
                            isSelected: i == userIndex,
                            onPressed: () => {switchUser(i)}),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Column(
                    children: [
                      Row(
                        children: [
                          Text('Lights: ${_lightsValue.round().toString()}'),
                          Expanded(
                              child: Slider(
                            value: _lightsValue,
                            max: 3,
                            divisions: 3,
                            label: _lightsValue.round().toString(),
                            onChanged: (double value) {
                              setState(() {
                                _lightsValue = value;
                              });
                            },
                          ))
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                              'Temperature: ${_temperatureValue.round().toString()}'),
                          Expanded(
                              child: Slider(
                            value: _temperatureValue,
                            max: 40,
                            min: 0,
                            label: _temperatureValue.round().toString(),
                            onChanged: (double value) {
                              setState(() {
                                _temperatureValue = value;
                              });
                            },
                          ))
                        ],
                      ),
                      if (_accessToken != 'no_token')

                        //  =========================================== Playlist Selector ============================================
                        // PlaylistSelector(
                        //   accessToken: _accessToken,
                        // ),
                        if (spotifyId != 'none')
                          if (playlists.length > 0)
                            Row(
                              children: [
                                DropdownButton(
                                  value: spotifyPlaylistId,
                                  items: playlistsItems,
                                  onChanged: (String? value) {
                                    setState(() {
                                      spotifyPlaylistId = value!;
                                    });
                                  },
                                ),
                                TextButton(
                                  child: Text(
                                    'change user',
                                  ),
                                  onPressed: () {
                                    resetSpotifyInfo();
                                  },
                                ),
                              ],
                            )
                          else
                            TextField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Enter your spotify username',
                              ),
                              onSubmitted: (userId) {
                                getUserPlaylists(userId);
                              },
                            )
                      //  =========================================== Playlist Selector ============================================
                    ],
                  )
                ],
              ))),
    );
  }
}
