// import 'package:bottom_picker/bottom_picker.dart';
// import 'package:bottom_picker/resources/arrays.dart';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:water_mushroom/manager/bluetooth_manager.dart';
import 'package:water_mushroom/manager/water_lamp_manager.dart';

class DeviceControlScreen extends StatefulWidget {
  final DiscoveredDevice bluetoothDevice;

  const DeviceControlScreen({super.key, required this.bluetoothDevice});

  @override
  // ignore: library_private_types_in_public_api
  _DeviceControlScreenState createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  final int _maxDataSendInterval = 100; //in ms
  DeviceConnectionState _currentConnectionState =
      DeviceConnectionState.disconnected;
  StreamSubscription<ConnectionStateUpdate>? _currentConnectionSubscription;
  static StreamSubscription<List<int>>? _characteristicSubscription;
  QualifiedCharacteristic? _rxCharacteristic;

  String _debugText = "_debugText";
  Color _selectedColor = Colors.white;
  double _waterSpeed = 0;
  bool _lightsOn = false;
  bool _waterOn = false;
  // bool _timerOn = false;
  int _lastSendDataTime = 0;

  void _toggleLights(bool value) {
    _lightsOn = value;
    setState(() {});
    if (_canSendData())
      WaterLampManager.setLights(_lightsOn, _rxCharacteristic);
  }

  void _toggleWater(bool value) {
    _waterOn = value;
    if (_waterOn) {
      _setWater(125);
    } else {
      _setWater(0);
    }
    setState(() {});
    if (_canSendData()) WaterLampManager.setWater(_waterOn, _rxCharacteristic);
  }

  void _changeColor(Color color) {
    _selectedColor = color;
    if (_selectedColor.red != 0 ||
        _selectedColor.green != 0 ||
        _selectedColor.blue != 0) {
      _lightsOn = true;
    }
    setState(() {});
    if (_canSendData())
      WaterLampManager.setColor(_selectedColor, _rxCharacteristic);
  }

  void _setWater(double newValue) {
    _waterSpeed = newValue;
    if (newValue != 0) _waterOn = true;
    setState(() {});
    if (_canSendData())
      WaterLampManager.setWaterSpeed(_waterSpeed, _rxCharacteristic);
  }

  bool _canSendData() {
    if ((DateTime.now().millisecondsSinceEpoch - _lastSendDataTime) >
        _maxDataSendInterval) {
      _lastSendDataTime = DateTime.now().millisecondsSinceEpoch;
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    Stream<ConnectionStateUpdate> currentConnectionStream =
        BLEHolder.flutterReactiveBle.connectToAdvertisingDevice(
      id: widget.bluetoothDevice.id,
      prescanDuration: const Duration(seconds: 1),
      withServices: [BLEHolder.serviceUuid, BLEHolder.characteristicUuid],
    );
    _currentConnectionSubscription = currentConnectionStream.listen(
      (event) {
        _currentConnectionState = event.connectionState;
        setState(() {});
        if (_currentConnectionState == DeviceConnectionState.connected) {
          _rxCharacteristic = QualifiedCharacteristic(
            serviceId: BLEHolder.serviceUuid,
            characteristicId: BLEHolder.characteristicUuid,
            deviceId: event.deviceId,
          );
          _characteristicSubscription = BLEHolder.flutterReactiveBle
              .subscribeToCharacteristic(_rxCharacteristic!)
              .listen((event) {
            String value = String.fromCharCodes(event);
            print(value);
          });
        } else {
          _rxCharacteristic = null;
        }
      },
      onDone: () {
        Navigator.pop(context);
      },
      onError: (e) {
        Navigator.pop(context);
      },
    );
  }

  @override
  void dispose() {
    _currentConnectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.bluetoothDevice.name}: ${_currentConnectionState.name}',
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return Center(
      child: ListView(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
            child: Visibility(
              visible:
                  _currentConnectionState != DeviceConnectionState.connected,
              child: Container(
                margin: const EdgeInsets.all(16.0),
                child: const CircularProgressIndicator.adaptive(),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 750),
            curve: Curves.fastOutSlowIn,
            child: Visibility(
              visible:
                  _currentConnectionState == DeviceConnectionState.connected,
              child: Column(
                children: [
                  _lightsControll(),
                  _waterControll(),
                  // _timerControll(),
                  const SizedBox(height: 20),
                  Text(_debugText),
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.replay_outlined),
                    onPressed: () {
                      WaterLampManager.getState(_rxCharacteristic);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lightsControll() {
    Column(
      children: [
        Container(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Lights',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              CupertinoSwitch(
                value: _lightsOn,
                onChanged: (bool newValue) {
                  _toggleLights(newValue);
                },
                activeColor: CupertinoColors.activeGreen,
              ),
            ],
          ),
        ),
        Visibility(
          visible: _lightsOn,
          child: HueRingPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => _changeColor(color),
            enableAlpha: false,
            displayThumbColor: true,
            portraitOnly: true,
          ),
        ),
      ],
    );
    return AnimatedSize(
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Lights',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                CupertinoSwitch(
                  value: _lightsOn,
                  onChanged: (bool newValue) {
                    _toggleLights(newValue);
                  },
                  activeColor: CupertinoColors.activeGreen,
                ),
              ],
            ),
            Visibility(
              visible: _lightsOn,
              child: HueRingPicker(
                pickerColor: _selectedColor,
                onColorChanged: (color) => _changeColor(color),
                enableAlpha: false,
                displayThumbColor: true,
                portraitOnly: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waterControll() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Water',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                CupertinoSwitch(
                  value: _waterOn,
                  onChanged: (bool newValue) {
                    _toggleWater(newValue);
                  },
                  activeColor: CupertinoColors.activeGreen,
                ),
              ],
            ),
            Visibility(
              visible: _waterOn,
              child: CupertinoSlider(
                value: _waterSpeed,
                min: 0.0,
                max: 255.0,
                onChanged: (newValue) => _setWater(newValue),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget _timerControll() {
  //   return AnimatedSize(
  //     duration: const Duration(milliseconds: 250),
  //     curve: Curves.fastOutSlowIn,
  //     child: Container(
  //       color: Colors.white,
  //       margin: const EdgeInsets.symmetric(vertical: 4.0),
  //       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
  //       child: Column(
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               const Text(
  //                 'Timer',
  //                 style: TextStyle(
  //                   fontSize: 16.0,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //               const Spacer(),
  //               CupertinoSwitch(
  //                 value: _timerOn,
  //                 onChanged: (bool newValue) {
  //                   if (!_lightsOn && !_waterOn) {
  //                     newValue = false;
  //                   }
  //                   setState(() {
  //                     _timerOn = newValue;
  //                   });
  //                 },
  //                 activeColor: CupertinoColors.activeGreen,
  //               ),
  //             ],
  //           ),
  //           Visibility(
  //             visible: _timerOn,
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //               children: [
  //                 const SizedBox(height: 20),
  //                 CupertinoButton(
  //                   onPressed: () {},
  //                   color: CupertinoColors.systemGrey,
  //                   child: const Text(
  //                     'Set Timer',
  //                     style: TextStyle(fontSize: 18),
  //                   ),
  //                 ),
  //                 TextButton(
  //                   onPressed: () async {
  //                     BottomPicker.time(
  //                       title: 'Set your next meeting time',
  //                       titleStyle: const TextStyle(
  //                         fontWeight: FontWeight.bold,
  //                         fontSize: 15,
  //                         color: Colors.orange,
  //                       ),
  //                       onSubmit: (index) {
  //                         print(index);
  //                       },
  //                       onClose: () {
  //                         print('Picker closed');
  //                       },
  //                       bottomPickerTheme: BottomPickerTheme.orange,
  //                       use24hFormat: true,
  //                     ).show(context);
  //                   },
  //                   child: const Text("Pick Time"),
  //                 ),
  //                 TimePickerSpinnerPopUp(
  //                   mode: CupertinoDatePickerMode.time,
  //                   initTime: DateTime.now(),
  //                   onChange: (dateTime) {
  //                     // Implement your logic with select dateTime
  //                   },
  //                 )
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
