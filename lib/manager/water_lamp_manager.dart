import 'package:flutter/material.dart' show Color, Colors;
import 'package:water_mushroom/manager/bluetooth_manager.dart';

class Time {
  double second = 0;
  double minute = 0;
  double hour = 0;

  double toMilliseconds() {
    double totalMilliseconds = (hour * 3600 + minute * 60 + second) * 1000;
    return totalMilliseconds;
  }

  void fromMilliseconds(double milliseconds) {
    // Convert total milliseconds to hours, minutes, and seconds
    double totalSeconds = milliseconds / 1000;
    hour = (totalSeconds / 3600).truncateToDouble();
    totalSeconds -= hour * 3600;
    minute = (totalSeconds / 60).truncateToDouble();
    totalSeconds -= minute * 60;
    second = totalSeconds;
  }
}

class WaterLampManager {
  static const _splitChar = ';';

  static const colorModeStatic = 0;
  static const colorModeRainbow = 1;

  static const _setLight = 0;
  static const _setColorMode = 1;
  static const _setColor = 2;
  static const _setWater = 3;
  static const _setWaterSpeed = 4;
  static const _setTimer = 5;
  static const _getState = 6;

  static Time? shutdownTime;
  static Color selectedColor = Colors.white;
  static double waterSpeed = 0;
  static bool lightsOn = false;
  static bool waterOn = false;
  static bool timerOn = false;
  static int currentColorMode = 0;

  //Lamp functions
  /*
   * COMMAND + SPLITCHAR + PARAMETER + SPLITCHAR + PARAMETER + END_CHAR
   * Example:
   * SetColor to red
   * "0;255;0;0\n"
   * 0 = setColor; R; G, B \ncommand ended
   */
  static Future<bool> setColor() {
    String command = _setColor.toString() +
        _splitChar +
        selectedColor.red.toString() +
        _splitChar +
        selectedColor.green.toString() +
        _splitChar +
        selectedColor.blue.toString();
    return BluetoothManager.sendMessage(command);
  }

  static Future<bool> setColorMode() {
    String command =
        _setColorMode.toString() + _splitChar + currentColorMode.toString();
    return BluetoothManager.sendMessage(command);
  }

  static Future<bool> setLights() {
    String command = _setLight.toString() + _splitChar + (lightsOn ? "1" : "0");
    return BluetoothManager.sendMessage(command);
  }

  static Future<bool> setWater() {
    String command = _setWater.toString() + _splitChar + (waterOn ? "1" : "0");
    return BluetoothManager.sendMessage(command);
  }

  static Future<bool> setWaterSpeed() {
    String command =
        _setWaterSpeed.toString() + _splitChar + waterSpeed.toInt().toString();
    return BluetoothManager.sendMessage(command);
  }

  static String _timeToMillisString(Time time) {
    double milliseconds = time.toMilliseconds();
    return milliseconds.toString();
  }

  static Future<bool> setTimer() async {
    if (shutdownTime == null) return false;
    String command =
        _setTimer.toString() + _splitChar + _timeToMillisString(shutdownTime!);
    return BluetoothManager.sendMessage(command);
  }

  static Future<bool> getState() {
    String command = _getState.toString();
    return BluetoothManager.sendMessage(command);
  }

  static void computeMessage(String message) {
    List<String> values = message.split(";");
    List<int> intValues = [];
    for (String val in values) {
      if (int.tryParse(val) == null) return;
      intValues.add(int.parse(val));
    }
    if (intValues.isEmpty) return;

    int command = intValues[0];

    switch (command) {
      case _setLight:
        if (intValues.length != 2) return;
        print("Set Light to:");
        print(intValues[1].toString());
        lightsOn = intValues[1] == 1;
        break;
      case _setColorMode:
        if (intValues.length != 2) return;
        print("Set ColorMode to:");
        print(intValues[1]);
        currentColorMode = intValues[1];
        break;
      case _setColor:
        if (intValues.length != 4) return;
        print("Set Color to:");
        print("${intValues[1]} : ${intValues[2]} : ${intValues[3]}");
        selectedColor =
            Color.fromARGB(255, intValues[1], intValues[2], intValues[3]);
        break;
      case _setWater:
        if (intValues.length != 2) return;
        print("Set Water to:");
        print(intValues[1].toString());
        waterOn = intValues[1] == 1;
        break;
      case _setWaterSpeed:
        if (intValues.length != 2) return;
        print("Set WaterSpeed to:");
        print(intValues[1].toString());
        waterSpeed = intValues[1].toDouble();
        break;
      case _setTimer:
        if (intValues.length != 2) return;
        print("Set Timer to:");
        print(intValues[1].toString());
        shutdownTime = Time();
        shutdownTime!.fromMilliseconds(intValues[1].toDouble());
        break;
    }
  }
}
