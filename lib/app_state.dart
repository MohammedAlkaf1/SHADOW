import 'package:flutter/material.dart';
import '/backend/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  String _selectedDisability = '';
  String get selectedDisability => _selectedDisability;
  set selectedDisability(String value) {
    _selectedDisability = value;
  }

  double _readingFontSize = 18.0;
  double get readingFontSize => _readingFontSize;
  set readingFontSize(double value) {
    _readingFontSize = value;
  }

  bool _isRecording = false;
  bool get isRecording => _isRecording;
  set isRecording(bool value) {
    _isRecording = value;
  }

  String _liveText = '';
  String get liveText => _liveText;
  set liveText(String value) {
    _liveText = value;
  }
}
