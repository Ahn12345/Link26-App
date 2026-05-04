class PageRequest {
  const PageRequest({this.offset = 0, this.limit = 20});

  final int offset;
  final int limit;
}

class PageResult<T> {
  const PageResult({required this.items, required this.hasMore});

  final List<T> items;
  final bool hasMore;
}
