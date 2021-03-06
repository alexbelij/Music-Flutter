import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:music/global_providers/database.dart';
import 'package:music/bloc/data_bloc.dart';
import 'package:music/bloc/queue_bloc.dart';
import 'package:music/helpers/generateSubtitle.dart';
import 'package:music/models/models.dart';
import 'package:music/constants.dart';
import './widgets/SongPage.dart';

class LikedPage extends StatefulWidget {
  @override
  _LikedPageState createState() => _LikedPageState();
}

class _LikedPageState extends State<LikedPage>
    with SingleTickerProviderStateMixin {
  List<SongData> _songs = [];
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    beginAnimation();
    getSongs();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<void> beginAnimation() async {
    await Future.delayed(const Duration(milliseconds: 450));
    await _controller.forward();
  }

  Future<void> getSongs() async {
    var songs = await DatabaseProvider.getDB(context).getSongs(where: 'liked');

    if (!mounted) return;

    setState(() {
      _songs = songs;
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return MultiBlocListener(
      listeners: [
        BlocListener<DataBloc, DataState>(
          listener: (_, state) {
            if (state is UpdateData) {
              getSongs();
            }
          },
        ),
        BlocListener<QueueBloc, QueueState>(
          listener: (context, state) {
            if (state.updateData) {
              getSongs();
            }
          },
        ),
      ],
      child: SongPage(
        controller: _controller,
        title: 'Liked',
        subtitle: generateSubtitle(type: 'Album', numSongs: _songs.length),
        hero: Hero(
          tag: 'liked-songs',
          child: Image.asset(
            '$imgs/liked.png',
            width: screenWidth,
            height: screenWidth,
            fit: BoxFit.cover,
          ),
        ),
        songs: _songs,
      ),
    );
  }
}
