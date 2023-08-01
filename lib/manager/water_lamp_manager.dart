import 'dart:ui';
import 'package:water_mushroom/manager/bluetooth_manager.dart';

class WaterLampManager {
  static const _splitChar = ';';

  static const colorModeStatic = 0;
  static const colorModeRainbow = 1;

  static const _setLight = 6;
  static const _setColorMode = 1;
  static const _setColor = 0;
  static const _setWater = 7;
  static const _setWaterSpeed = 2;
  static const _setTimer = 3;
  static const _getState = 4;
  static const _setDateTime = 5;

  //Lamp functions
  /*
   * COMMAND + SPLITCHAR + PARAMETER + SPLITCHAR + PARAMETER + END_CHAR
   * Example:
   * SetColor to red
   * "0;255;0;0\n"
   * 0 = setColor; R; G, B \ncommand ended
   */
  static Future<bool> setColor(Color color) {
    String command = _setColor.toString() +
        _splitChar +
        color.red.toString() +
        _splitChar +
        color.green.toString() +
        _splitChar +
        color.blue.toString();
    return BluetoothManager.sendMessage(command);
  }

  static Future<bool> setColorMode(int mode) {
    String command = _setColorMode.toString() + _splitChar + mode.toString();
    return BluetoothManager.sendMessage(command);
  }

  static Future<bool> setLights(bool state) {
    String command = "$_setLight$_splitChar$state";
    return BluetoothManager.sendMessage(command);
  }

  static Future<bool> setWater(bool state) {
    String command = _setWater.toString() + _splitChar + state.toString();
    return BluetoothManager.sendMessage(command);
  }

  static Future<bool> setWaterSpeed(double speed) {
    String command =
        _setWaterSpeed.toString() + _splitChar + speed.toInt().toString();
    return BluetoothManager.sendMessage(command);
  }

  static Future<bool> setTimer() {
    String command = _setTimer.toString();
    return BluetoothManager.sendMessage(command);
  }

  static Future<bool> getState() {
    String command = _getState.toString();
    return BluetoothManager.sendMessage(command);
  }

  static Future<bool> setDateTime() {
    String command = "$_setDateTime${_splitChar}setDateTime";
    return BluetoothManager.sendMessage(command);
  }
}
