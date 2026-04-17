import 'package:shopping_list/env.dart';

/// HTTPS [Uri] for a path on the Realtime Database host (e.g. `shopping-list.json`).
Uri databaseUri(String path) => Uri.https(kDatabaseUrl, path);

/// GET / POST — entire shopping list node.
Uri shoppingListUri() => databaseUri(kShoppingListPath);

/// DELETE / PATCH — one child node under the list (`shopping-list/{id}.json`).
Uri shoppingListItemUri(String id) {
  final base = kShoppingListPath.replaceFirst(RegExp(r'\.json$'), '');
  return databaseUri('$base/$id.json');
}
