import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';

class PlaylistSelector extends StatefulWidget {
  PlaylistSelector({Key? key, this.userId = 'none', required this.accessToken})
      : super(key: key);

  String userId;
  String accessToken;

  @override
  State<PlaylistSelector> createState() => _PlaylistSelectorState();
}

class _PlaylistSelectorState extends State<PlaylistSelector> {
  getUserPlaylists(String userId) async {
    print('testing, ${widget.accessToken}');

    // TODO: with the received access token and user ID get the corresponding playlists
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

    return TextField(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter your spotify username',
      ),
      onSubmitted: (userId) {
        getUserPlaylists(userId);
      },
    );
  }
}
