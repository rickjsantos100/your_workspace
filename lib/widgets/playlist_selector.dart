import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class PlaylistSelector extends StatefulWidget {
  PlaylistSelector({Key? key, this.userId = 'none', required this.accessToken})
      : super(key: key);

  String userId;
  String accessToken;

  @override
  State<PlaylistSelector> createState() => _PlaylistSelectorState();
}

class _PlaylistSelectorState extends State<PlaylistSelector> {
  dynamic playlists = [];

  getUserPlaylists(String userId) async {
    widget.userId = userId;

    Response responseHTTP = await http.get(
        Uri.parse('https://api.spotify.com/v1/users/$userId/playlists'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer ${widget.accessToken}',
          HttpHeaders.contentTypeHeader: 'application/json',
        });

    dynamic response = jsonDecode(responseHTTP.body);
    playlists = response['items'];
    print('aaa');
  }

  @override
  Widget build(BuildContext context) {
    // return ElevatedButton(
    //   style: ElevatedButton.styleFrom(
    //       shape: const CircleBorder(),
    //       padding: const EdgeInsets.all(8),
    //       elevation: 1),
    //   child: Text(widget.userId),
    //   onPressed: () => {widget.userId = 'newId'},
    // );

    return
        // Row(
        // children: [
        // if (widget.userId != 'none')
        TextField(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter your spotify username',
      ),
      onSubmitted: (userId) {
        getUserPlaylists(userId);
      },
    );
    // Image.network(
    //     'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg')
    //   ],
    // );
  }
}
