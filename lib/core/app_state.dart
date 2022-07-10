/// This file is a part of Harmonoid (https://github.com/harmonoid/harmonoid).
///
/// Copyright © 2020-2022, Yehuda Kremer <yehudakremer@gmail.com>.
/// All rights reserved.
///
/// Use of this source code is governed by the End-User License Agreement for Harmonoid that can be found in the EULA.txt file.
///

import 'dart:io';
import 'dart:convert' as convert;
import 'package:harmonoid/core/playback.dart'
    show DefaultPlaybackValues, PlaylistLoopMode;
import 'package:harmonoid/models/media.dart';
import 'package:harmonoid/utils/file_system.dart';
import 'package:path/path.dart' as path;

import 'configuration.dart';

/// App State
/// -------------
///
/// App state persistence for [Harmonoid](https://github.com/harmonoid/harmonoid).
/// Used to resume the state of the app after a restart.
class AppState extends AppStateKeys {
  /// [AppState] object instance.
  static late AppState instance = AppState();

  /// Configuration storage [File] to hold serialized JSON document.
  late File file;

  /// Initializes the [AppState] class.
  ///
  /// Called after the [Configuration.initialize] and load the app state.
  /// Generates from scratch if no state is found.
  ///
  static Future<void> initialize() async {
    instance.file = File(
      path.join(
        await Configuration.instance.configurationDirectory,
        '.Harmonoid',
        'AppState.JSON',
      ),
    );
    if (!await instance.file.exists()) {
      await instance.file.create_();
      await instance.file.write_(
        convert.JsonEncoder.withIndent('  ').convert(defaultAppState),
      );
    }
    await instance.read();
  }

  /// Updates and save the app state in the [file].
  Future<void> save(
    List<Track> playlist,
    int index,
    double rate,
    bool shuffle,
    PlaylistLoopMode playlistLoopMode,
    double volume,
    double pitch,
  ) async {
    this.playlist = playlist;
    this.index = index;
    this.rate = rate;
    this.shuffle = shuffle;
    this.playlistLoopMode = playlistLoopMode;
    this.volume = volume;
    this.pitch = pitch;

    await file.write_(convert.JsonEncoder.withIndent('  ').convert({
      'playlist': playlist,
      'index': index,
      'rate': rate,
      'shuffle': shuffle,
      'playlistLoopMode': PlaylistLoopMode.values.indexOf(playlistLoopMode),
      'volume': volume,
      'pitch': pitch,
    }));
  }

  /// Reads the app state from the [file].
  Future<void> read({
    bool retry = true,
  }) async {
    try {
      Map<String, dynamic> current =
          convert.jsonDecode(await file.readAsString());
      // Emblace default values for the keys that not found. Possibly due to app update.
      defaultAppState.keys.forEach(
        (String key) {
          if (!current.containsKey(key)) {
            current[key] = defaultAppState[key];
          }
        },
      );

      playlist = (current['playlist'] as List)
          .map((e) => Track.fromJson(e))
          .toList()
          .cast<Track>();
      index = current['index'];
      rate = current['rate'];
      shuffle = current['shuffle'];
      playlistLoopMode = PlaylistLoopMode.values[current['playlistLoopMode']];
      volume = current['volume'];
      pitch = current['pitch'];
    } catch (exception) {
      if (!retry) throw exception;
      if (!await file.exists()) {
        await file.create_();
      }
      await file.write_(
        convert.JsonEncoder.withIndent('  ').convert(defaultAppState),
      );
      read(retry: false);
    }
  }
}

abstract class AppStateKeys {
  late List<Track> playlist;
  late int index;
  late double rate;
  late bool shuffle;
  late PlaylistLoopMode playlistLoopMode;
  late double volume;
  late double pitch;
}

final Map<String, dynamic> defaultAppState = {
  'playlist': DefaultPlaybackValues.tracks,
  'index': DefaultPlaybackValues.index,
  'rate': DefaultPlaybackValues.rate,
  'shuffle': DefaultPlaybackValues.isShuffling,
  'playlistLoopMode':
      PlaylistLoopMode.values.indexOf(DefaultPlaybackValues.playlistLoopMode),
  'volume': DefaultPlaybackValues.volume,
  'pitch': DefaultPlaybackValues.pitch,
};
