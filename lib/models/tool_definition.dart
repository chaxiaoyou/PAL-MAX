import 'package:flutter/material.dart';

/// A calculator in the catalogue. Titles and subtitles are not stored here:
/// they are resolved from the active locale via the `toolTitle` / `toolSubtitle`
/// lookups in `data/tools.dart`, so one catalogue drives every language.
class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.icon,
    required this.color,
    required this.categoryId,
  });

  final String id;
  final IconData icon;
  final Color color;

  /// Catalogue section: `trading` or `investment`.
  final String categoryId;
}
