class HobbyModel {
  final int id;
  final String hobbyName;
  final String hobbyIcon;
  bool isFavorite;

  HobbyModel({
    required this.id,
    required this.hobbyName,
    required this.hobbyIcon,
    required this.isFavorite,
  });
}