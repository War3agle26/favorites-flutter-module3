class BookModel {
  final int id;
  final String bookTitle;
  final String bookAuthor;
  bool isFavorite;

  BookModel({
    required this.id,
    required this.bookTitle,
    required this.bookAuthor,
    required this.isFavorite,
  });
}