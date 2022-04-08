import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  double _light = 1;
  double _temperature = 22;
  String _accessToken = 'no_token';
  dynamic playlists = [];
  Timer? _debounce;

  // Object type
  /*
  {
    username: 
    light:
    tempValue
    spotifyUserName:
    playlistID:
  }
  */
  var users = [];
  int userIndex = 0;
  String _spotifyUserName = 'none';
  String _playlistID = 'none';
  bool nfcSession = false;
  int? userId;

  final TextEditingController _spotifyIdController = TextEditingController();
  final TextEditingController _teamCodeController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();

  @override
  initState() {
    super.initState();

    init();
  }

  init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
    if (userId != null) {
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

      retrieveUserInfo();
    }
  }

  retrieveUserInfo() {
    return http
        .get(Uri.parse('$SERVER_URL/user?id=$MOCK_USER_ID&teams=true'))
        .then((responseHTTP) {
      dynamic response = jsonDecode(responseHTTP.body);
      setState(() {
        users = response;
        switchUser(userIndex);
      });
    });
  }

  createTeam() {
    http.put(Uri.parse('$SERVER_URL/team'),
        body: jsonEncode({
          'temperature': 22,
          'light': 2,
          'members': [users[userIndex]['id']]
        }));
  }

  joinTeam(teamCode) {
    var userID = users[0]['id'];
    http
        .put(Uri.parse('$SERVER_URL/user?join_team=$teamCode'),
            body: jsonEncode({
              'id': userID,
            }))
        .then((value) {
      retrieveUserInfo();
    });
  }

  leaveTeam() {
    var teamId = users[userIndex]['id'];
    var userID = users[0]['id'];
    http
        .put(Uri.parse('$SERVER_URL/user?leave_team=$teamId'),
            body: jsonEncode({
              'id': userID,
            }))
        .then((value) {
      setState(() {
        retrieveUserInfo();

        userIndex = userIndex - 1;
      });
    });
  }

  switchUser(index) {
    setState(() {
      resetSpotifyInfo();
      userIndex = index;
      _light = users[index]['light'].toDouble();
      _temperature = users[index]['temperature'].toDouble();

      if (users[index]['spotifyUserName'] != null &&
          users[index]['spotifyUserName'] != '' &&
          users[index]['spotifyUserName'] != 'none') {
        _spotifyUserName = users[index]['spotifyUserName'];

        getUserPlaylists(_spotifyUserName);

        _playlistID = users[index]['playlistID'];
      }
      updateBackend();
    });
  }

  resetSpotifyInfo() {
    setState(() {
      _playlistID = 'none';
      playlists = [];
      _spotifyUserName = 'none';
      updateBackend();
    });
  }

  updateBackend() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      users[userIndex]['temperature'] = _temperature;
      users[userIndex]['light'] = _light;
      users[userIndex]['spotifyUserName'] = _spotifyUserName;
      users[userIndex]['playlistID'] = _playlistID;

      // Checks if is a team profile
      if (users[userIndex]['members'] != null) {
        // TODO handle here the specific fields for team profiles

        http.put(Uri.parse('$SERVER_URL/team'),
            headers: {HttpHeaders.contentTypeHeader: 'application/json'},
            body: jsonEncode(users[userIndex]));
      } else {
        http.put(Uri.parse('$SERVER_URL/user'),
            headers: {HttpHeaders.contentTypeHeader: 'application/json'},
            body: jsonEncode(users[userIndex]));
      }
    });
  }

  startNfcSession() {
    setState(() {
      nfcSession = true;
    });
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        var ndef = MifareUltralight.from(tag);
        if (ndef == null) {
          stopNfcSession('Tag is not ndef writable');

          return;
        }

        NdefMessage message = NdefMessage([
          NdefRecord.createText('This is a message being writen in nfc'),
        ]);

        try {
          List<int> list = utf8.encode('this is a nfc test');
          Uint8List bytes = Uint8List.fromList(list);
          await ndef.writePage(pageOffset: 0, data: bytes);
          stopNfcSession();
        } catch (e) {
          stopNfcSession('Failure to "Ndef Write"');
          return;
        }
      },
    );
  }

  stopNfcSession([errorMessage]) {
    if (errorMessage != null) {
      NfcManager.instance.stopSession(errorMessage: errorMessage);
    } else {
      NfcManager.instance.stopSession();
    }
    setState(() {
      nfcSession = false;
    });
  }

  List<DropdownMenuItem<String>> get playlistsItems {
    List<DropdownMenuItem<String>> menuItems = [
      for (var playlist in playlists)
        DropdownMenuItem(child: Text(playlist['name']), value: playlist['id']),
    ];
    return menuItems;
  }

  getUserPlaylists(String spotifyUserName) async {
    Response responseHTTP = await http.get(
        Uri.parse(
            'https://api.spotify.com/v1/users/$spotifyUserName/playlists'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $_accessToken',
          HttpHeaders.contentTypeHeader: 'application/json',
        });

    if (responseHTTP.statusCode == 200) {
      dynamic response = jsonDecode(responseHTTP.body);
      setState(() {
        playlists = response['items'];
        if (_playlistID == 'none') {
          _playlistID = playlists[0]['id'];
        }
        _spotifyUserName = spotifyUserName;
        updateBackend();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return getPage();
  }

  getPage() {
    if (userId == null) {
      return Scaffold(
          body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your userId',
                ),
                onSubmitted: (userId) async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setInt('userId', int.parse(_userIdController.text));
                  _userIdController.text = '';
                  init();
                },
              ),
            ),
            TextButton(
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setInt('userId', int.parse(_userIdController.text));
                  _userIdController.text = '';
                  init();
                },
                child: const Text('Submit'))
          ],
        ),
      ));
    } else if (users.isNotEmpty) {
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
                        ProfileSelector(
                            isAdd: true,
                            onPressed: () {
                              createTeam();
                              retrieveUserInfo();
                            }),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Column(
                      children: [
                        Row(
                          children: [
                            Text('Lights: ${_light.round().toString()}'),
                            Expanded(
                                child: Slider(
                              value: _light,
                              max: 3,
                              divisions: 3,
                              label: _light.round().toString(),
                              onChanged: (double value) {
                                setState(() {
                                  _light = value;
                                  updateBackend();
                                });
                              },
                            ))
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                                'Temperature: ${_temperature.round().toString()}'),
                            Expanded(
                                child: Slider(
                              value: _temperature,
                              max: 32,
                              min: 16,
                              label: _temperature.round().toString(),
                              onChanged: (double value) {
                                setState(() {
                                  _temperature = value;
                                  updateBackend();
                                });
                              },
                            ))
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_accessToken != 'no_token')

                          //  =========================================== Playlist Selector ============================================
                          // PlaylistSelector(
                          //   accessToken: _accessToken,
                          // ),
                          if (_spotifyUserName != 'none')
                            if (playlists.length > 0)
                              Row(
                                children: [
                                  DropdownButton(
                                    value: _playlistID,
                                    items: playlistsItems,
                                    onChanged: (String? value) {
                                      setState(() {
                                        _playlistID = value!;
                                        updateBackend();
                                      });
                                    },
                                  ),
                                  TextButton(
                                    child: const Text(
                                      'change user',
                                    ),
                                    onPressed: () {
                                      resetSpotifyInfo();
                                    },
                                  ),
                                ],
                              ),
                        if (_spotifyUserName == 'none')
                          Row(
                            children: [
                              Flexible(
                                child: TextField(
                                  controller: _spotifyIdController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter your spotify username',
                                  ),
                                  onSubmitted: (userId) {
                                    getUserPlaylists(userId);
                                    _spotifyIdController.text = '';
                                  },
                                ),
                              ),
                              TextButton(
                                  onPressed: () {
                                    getUserPlaylists(_spotifyIdController.text);
                                    _spotifyIdController.text = '';
                                  },
                                  child: const Text('Change'))
                            ],
                          ),

                        //  =========================================== User Section ==============================

                        const SizedBox(height: 20),
                        if (users[userIndex]['members'] == null)
                          Row(
                            children: [
                              Flexible(
                                child: TextField(
                                  controller: _teamCodeController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter a team code',
                                  ),
                                  onSubmitted: (teamCode) {
                                    joinTeam(teamCode);
                                    _teamCodeController.text = '';
                                  },
                                ),
                              ),
                              TextButton(
                                  onPressed: () {
                                    joinTeam(_teamCodeController.text);
                                    _teamCodeController.text = '';
                                  },
                                  child: const Text('Join'))
                            ],
                          ),

                        //  =========================================== Team section ============================================

                        if (users[userIndex]['members'] != null)
                          Column(
                            children: [
                              const SizedBox(height: 30),
                              Text('Team code: ${users[userIndex]['code']}'),
                              const SizedBox(height: 30),
                              TextButton(
                                child: const Text(
                                  'Leave team',
                                ),
                                onPressed: () {
                                  leaveTeam();
                                  retrieveUserInfo();
                                },
                              ),
                            ],
                          )

                        // ============================================= NFC Section
                        // if (nfcSession)
                        //   TextButton(
                        //     child: Text('Turn off NFC'),
                        //     onPressed: () {
                        //       stopNfcSession();
                        //     },
                        //   )
                        // else
                        //   TextButton(
                        //     child: Text('Turn on NFC'),
                        //     onPressed: () {
                        //       startNfcSession();
                        //     },
                        //   )
                      ],
                    )
                  ],
                ))),
      );
    } else {
      return const Scaffold(
          body: Center(
        child: Text('Loading ...'),
      ));
    }
  }
}
