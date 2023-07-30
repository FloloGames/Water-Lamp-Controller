import 'dart:ui';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
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
  static Future<void> setColor(
      Color color, QualifiedCharacteristic? rxCharacteristic) {
    String command = _setColor.toString() +
        _splitChar +
        color.red.toString() +
        _splitChar +
        color.green.toString() +
        _splitChar +
        color.blue.toString();
    return BLEHolder.sendMessage(command, rxCharacteristic);
  }

  static Future<void> setColorMode(
      int mode, QualifiedCharacteristic? rxCharacteristic) {
    String command = _setColorMode.toString() + _splitChar + mode.toString();
    return BLEHolder.sendMessage(command, rxCharacteristic);
  }

  static Future<void> setLights(
      bool state, QualifiedCharacteristic? rxCharacteristic) {
    String command = "$_setLight$_splitChar$state";
    return BLEHolder.sendMessage(command, rxCharacteristic);
  }

  static Future<void> setWater(
      bool state, QualifiedCharacteristic? rxCharacteristic) {
    String command = _setWater.toString() + _splitChar + state.toString();
    return BLEHolder.sendMessage(command, rxCharacteristic);
  }

  static Future<void> setWaterSpeed(
      double speed, QualifiedCharacteristic? rxCharacteristic) {
    String command =
        _setWaterSpeed.toString() + _splitChar + speed.toInt().toString();
    return BLEHolder.sendMessage(command, rxCharacteristic);
  }

  static Future<void> setTimer(QualifiedCharacteristic? rxCharacteristic) {
    String command = _setTimer.toString();
    return BLEHolder.sendMessage(command, rxCharacteristic);
  }

  static Future<void> getState(QualifiedCharacteristic? rxCharacteristic) {
    String command = _getState.toString();
    return BLEHolder.sendMessage(command, rxCharacteristic);
  }

  static Future<void> setDateTime(QualifiedCharacteristic? rxCharacteristic) {
    String command = "$_setDateTime${_splitChar}setDateTime";
    return BLEHolder.sendMessage(command, rxCharacteristic);
  }
}
