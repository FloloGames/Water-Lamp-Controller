library bluetooth_manager;

import 'dart:async';
import 'dart:io';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:location_permissions/location_permissions.dart';

typedef BluetoothManagerChanged = void Function();
typedef OnBLEMsgReceived = void Function(String);

// enum BTManagerChanged {
//   connected,
//   connecting,
//   disconnecting,
//   disconnected,
//   newDeviceFound,
//   stopScan,
//   startScan,
// }
class BLEHolder {
  static final flutterReactiveBle = FlutterReactiveBle();
  static final Uuid serviceUuid =
      Uuid.parse("0000ffe0-0000-1000-8000-00805f9b34fb");
  static final Uuid characteristicUuid =
      Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb");
  static const _endChar = '\n';
  static Future<void> sendMessage(
      String message, QualifiedCharacteristic? rxCharacteristic) async {
    if (rxCharacteristic == null) return;
    message += _endChar;
    await flutterReactiveBle.writeCharacteristicWithoutResponse(
      rxCharacteristic,
      value: message.codeUnits,
    );
  }
}

class BluetoothManager {
  // These are the UUIDs of your device
  //to detect needed UUIDs check this out: https://osoyoo.com/wp-content/uploads/2016/10/ble-android.pdf
  static final Uuid _serviceUuid =
      Uuid.parse("0000ffe0-0000-1000-8000-00805f9b34fb");
  static final Uuid _characteristicUuid =
      Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb");

  static const _endChar = '\n';

  static final _flutterReactiveBle = FlutterReactiveBle();
  static final List<DiscoveredDevice> _devices = [];
  static List<DiscoveredDevice> getDevices() => _devices;

  static StreamSubscription<ConnectionStateUpdate>?
      _currentConnectionSubscription;
  static StreamSubscription<DiscoveredDevice>? _scanStream;
  static StreamSubscription<List<int>>? _characteristicSubscription;

  static QualifiedCharacteristic? _rxCharacteristic;

  // static bool _scanStarted = false;
  static bool scanStarted() => _scanStream != null;
  static bool isConnected() => _rxCharacteristic != null;
  static int _connectedIndex = -1;
  static int getConnectedIndex() => _connectedIndex;

  static BluetoothManagerChanged? _connectingToDeviceCB;
  static void _callConnectingToDeviceCB() => _connectingToDeviceCB?.call();
  static void setConnectingToDeviceCB(BluetoothManagerChanged? func) =>
      _connectingToDeviceCB = func;

  static BluetoothManagerChanged? _connectedToDeviceCB;
  static void _callConnectedToDeviceCB() => _connectedToDeviceCB?.call();
  static void setConnectedToDeviceCB(BluetoothManagerChanged? func) =>
      _connectedToDeviceCB = func;

  static BluetoothManagerChanged? _disconnectedCB;
  static void _callDisconnectedCB() => _disconnectedCB?.call();
  static void setDisconnectedCB(BluetoothManagerChanged? func) =>
      _disconnectedCB = func;

  static BluetoothManagerChanged? _disconnectingCB;
  static void _callDisconnectingCB() => _disconnectingCB?.call();
  static void setDisconnectingCB(BluetoothManagerChanged? func) =>
      _disconnectingCB = func;

  static BluetoothManagerChanged? _managerChangedCB;
  static void _callManagerChangedCB() => _managerChangedCB?.call();
  static void setManagerChangedCB(BluetoothManagerChanged? func) =>
      _managerChangedCB = func;

  static OnBLEMsgReceived? _onBLEMsgReceived;
  static void _callOnBLEMsgReceived(String msg) => _onBLEMsgReceived?.call(msg);
  static void setOnBLEMsgReceived(OnBLEMsgReceived? func) =>
      _onBLEMsgReceived = func;

  static String _receivedData = "";

  //BLE functions
  static Future<bool> startScan() async {
    if (scanStarted()) return true;

    _devices.clear();

    bool permGranted = false;
    PermissionStatus permission;

    if (Platform.isAndroid) {
      permission = await LocationPermissions().requestPermissions();
      if (permission == PermissionStatus.granted) permGranted = true;
    } else if (Platform.isIOS) {
      permGranted = true;
    }

    // final status = await _flutterReactiveBle.statusStream.first;
    // bool bluetoothEnabled = status == BleStatus.ready;

    if (!permGranted /*|| !bluetoothEnabled*/) return false;

    try {
      _scanStream = _flutterReactiveBle
          .scanForDevices(withServices: [_serviceUuid]).listen((device) {
        if (_devices.any((element) => element.id == device.id)) return;
        _devices.add(device);
        _callManagerChangedCB();
      });
      _callManagerChangedCB();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static void stopScan() {
    if (!scanStarted()) {
      return;
    }
    _scanStream!.cancel();
    _scanStream = null;
    _callManagerChangedCB();
  }

  static void connectToDevice(int index) {
    stopScan();

    disconnectDevice();

    Stream<ConnectionStateUpdate> currentConnectionStream =
        _flutterReactiveBle.connectToAdvertisingDevice(
      id: _devices[index].id,
      prescanDuration: const Duration(seconds: 1),
      withServices: [_serviceUuid, _characteristicUuid],
    );

    _currentConnectionSubscription = currentConnectionStream.listen((event) {
      print(event.connectionState);
      switch (event.connectionState) {
        case DeviceConnectionState.connecting:
          print("connecting");
          _callConnectingToDeviceCB();
          break;
        case DeviceConnectionState.connected:
          _rxCharacteristic = QualifiedCharacteristic(
              serviceId: _serviceUuid,
              characteristicId: _characteristicUuid,
              deviceId: event.deviceId);

          _connectedIndex = index;
          print("connected");
          _callConnectedToDeviceCB();
          break;
        case DeviceConnectionState.disconnecting:
          print("disconnecting");
          _callDisconnectingCB();
          break;
        case DeviceConnectionState.disconnected:
          print("disconnected");
          _callDisconnectedCB();
          if (event.failure == null) return;
          // disconnectDevice();
          if (event.failure!.message ==
              "A scan for a different service is running") {
            // Future.delayed(const Duration(seconds: 1), () {
            print("Retring");
            connectToDevice(index);
            // });
          }
          break;

        default:
      }
    }, onDone: () {
      print("STREAM DONE");
    }, onError: (Object o) {
      print("Error");
      print(o.toString());
    });
  }

  static void disconnectDevice() {
    if (_currentConnectionSubscription == null) return;
    _currentConnectionSubscription!.cancel();
    _currentConnectionSubscription = null;
    _rxCharacteristic = null;
    _connectedIndex = -1;
  }

  static Future<void> sendMessage(String message) async {
    message += _endChar;
    if (isConnected()) {
      await _flutterReactiveBle.writeCharacteristicWithoutResponse(
        _rxCharacteristic!,
        value: message.codeUnits,
      );
    }
  }

  static bool startReadingMessage() {
    if (_characteristicSubscription != null) return false;
    if (_rxCharacteristic == null) return false;
    try {
      _characteristicSubscription = _flutterReactiveBle
          .subscribeToCharacteristic(_rxCharacteristic!)
          .listen((event) {
        String value = String.fromCharCodes(event);
        _receivedData += value;
        print(_receivedData);

        if (_receivedData.endsWith(_endChar)) {
          _receivedData = _receivedData.substring(0, _receivedData.length - 1);
          _callOnBLEMsgReceived(_receivedData);
          _receivedData = "";
        }
      });
    } catch (e) {
      print(e);
      return false;
    }
    return true;
  }

  static void stopReadingMessages() => _cancelCharacteristicSubscription();

  static void _cancelCharacteristicSubscription() {
    if (_characteristicSubscription == null) return;
    _characteristicSubscription!.cancel();
    _characteristicSubscription = null;
  }

  static bool isBluetootEnabled() => false;
}
