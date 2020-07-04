import "dart:async";
import "dart:io";
import "package:bloc/bloc.dart";
import "package:equatable/equatable.dart";
import "package:flutter/material.dart";
import "package:meta/meta.dart";
import "package:path_provider/path_provider.dart";

import "package:Music/notifications.dart";
import "package:Music/global_providers/database.dart";
import "package:Music/models/models.dart";
import "package:Music/helpers/downloader.dart";
import "package:Music/helpers/getYoutubeDetails.dart";
import "package:Music/helpers/updateAlbum.dart";

part "data_event.dart";
part "data_state.dart";

class DataBloc extends Bloc<DataEvent, DataState> {
  final DatabaseFunctions db;
  final NotificationHandler notificationHandler;

  DataBloc(this.db, this.notificationHandler) : super(InitialData());

  @override
  Stream<DataState> mapEventToState(
    DataEvent event,
  ) async* {
    if (event is DownloadSong) {
      var songData = event.song;

      var data = await getYoutubeDetails(songData);

      if (data == null) return;

      var filename = songData.title + ".mp3";
      var albumId = songData.albumId;

      print("Downloading ${songData.title}");
      var updateAlbumFuture = updateAlbum(albumId, songData.artist, db);

      var root = await getApplicationDocumentsDirectory();

      var song = SongData(
        albumId: albumId,
        artist: songData.artist,
        filePath: "${root.path}/songs/$filename",
        length: data.length,
        liked: false,
        numListens: 0,
        thumbnail: "${root.path}/album_images/$albumId.jpg",
        title: songData.title,
      );

      await db.insertSong(song);

      await updateAlbumFuture;
      var progressStream = downloadSong(data.id, filename);

      final body = "\nDownloading ${song.title} by ${song.artist}";

      await for (var progress in progressStream) {
        notificationHandler.showProgressNotification(
          progress.first,
          progress.second,
          title: song.title,
          body: body,
          path: song.thumbnail,
        );
        yield ProgressNotification(
          bytesDownloaded: progress.first,
          totalBytes: progress.second,
          title: song.title,
        );
      }

      print("Downloaded");
      notificationHandler.showNotification(
        title: song.title,
        body: "Finished Downloading ${song.title} by ${song.artist}",
        path: song.thumbnail,
      );
    } else if (event is DeleteSong) {
      var songFile = File(event.song.filePath);

      Future.wait([
        songFile.delete(),
        db.deleteSong(event.song.title),
        db.update(
          Tables.Albums,
          {"numSongs": await db.getNumSongs(event.song.albumId)},
          where: "id LIKE ?",
          whereArgs: [event.song.albumId],
        ),
      ]);

      await db.deleteEmptyAlbums();
    } else if (event is AddCustomAlbum) {
      var album = CustomAlbumData(
        id: await db.nextCustomAlbumId(),
        name: event.name,
        songs: event.songs,
      );

      await db.insertCustomAlbum(album);

      print("ADDED ${event.name}");
    } else if (event is EditCustomAlbum) {
      await db.update(
        Tables.CustomAlbums,
        {"songs": stringifyArr(event.songs)},
        where: "id LIKE ?",
        whereArgs: [event.id],
      );

      print("UPDATED ${event.id}");
    } else if (event is AddSongToCustomAlbum) {
      var album = (await db.getCustomAlbums(
        where: "id LIKE ?",
        whereArgs: [event.id],
      ))[0];

      if (album.songs.contains(event.song.title)) return;

      album.songs.add(event.song.title);

      db.update(
        Tables.CustomAlbums,
        album.toMap(),
        where: "id LIKE ?",
        whereArgs: [event.id],
      );
    } else if (event is DeleteCustomAlbum) {
      await db.deleteCustomAlbum(event.id);

      print("DELETED ${event.id}");
    }

    yield UpdateData();
  }
}
