class PagedResult<T> {
  PagedResult({required this.items, required this.total});

  final List<T> items;
  final int total;
}
