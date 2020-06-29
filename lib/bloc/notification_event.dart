part of "notification_bloc.dart";

@immutable
abstract class NotificationEvent extends Equatable {}

class DownloadSong extends NotificationEvent {
  final NapsterSongData song;
  DownloadSong(this.song) : super();

  @override
  List<Object> get props => [song];
}

class AddCustomAlbum extends NotificationEvent {
  final String name;
  final List<String> songs;

  AddCustomAlbum({this.name, this.songs});

  @override
  List<Object> get props => [name, songs];
}

class DeleteCustomAlbum extends NotificationEvent {
  final String id;

  DeleteCustomAlbum(this.id);

  @override
  List<Object> get props => [id];
}
