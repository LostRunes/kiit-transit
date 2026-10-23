import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/network_model.dart';

/// The city-wide KIIT + Mo Bus network, bundled as an asset. It is generated
/// by `tool/build_network.py` and changes only when that data is edited.
class NetworkRepository {
  NetworkRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/network/network.json';

  final AssetBundle _bundle;
  TransitNetwork? _network;

  Future<TransitNetwork> load() async =>
      _network ??= TransitNetwork.fromJson(jsonDecode(await _bundle.loadString(asset)) as Map<String, dynamic>);
}
