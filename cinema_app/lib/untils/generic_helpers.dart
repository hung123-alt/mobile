T? timTheoId<T>(List<T> ds, int Function(T) layId, int id) {
  for (final item in ds) {
    if (layId(item) == id) return item;
  }
  return null;
}

// Lọc danh sách theo điều kiện bất kỳ
List<T> loc<T>(List<T> ds, bool Function(T) dieuKien) {
  return ds.where(dieuKien).toList();
}