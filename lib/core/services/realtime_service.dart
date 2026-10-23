import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages Supabase Realtime table subscriptions.
///
/// Each call returns a broadcast stream of the full table snapshot. If the
/// socket drops, the subscription is re-opened after a short back-off so a
/// flaky campus network does not freeze the map.
class RealtimeService {
  RealtimeService(this._client);

  final SupabaseClient _client;
  static const _retryDelay = Duration(seconds: 3);

  Stream<List<Map<String, dynamic>>> watchTable(String table, {String orderBy = 'id'}) {
    late StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? sub;
    Timer? retry;

    void subscribe() {
      sub = _client
          .from(table)
          .stream(primaryKey: ['id'])
          .order(orderBy, ascending: true)
          .listen(
            controller.add,
            onError: (Object e) {
              debugPrint('Realtime[$table] error: $e — retrying');
              sub?.cancel();
              retry = Timer(_retryDelay, subscribe);
            },
          );
    }

    controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: subscribe,
      onCancel: () {
        retry?.cancel();
        sub?.cancel();
      },
    );
    return controller.stream;
  }
}
