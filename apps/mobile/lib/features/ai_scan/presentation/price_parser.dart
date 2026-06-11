double parsePrice(String raw) {
  return double.tryParse(raw.replaceAll(RegExp(r'[$,\s]'), '')) ?? 0;
}
