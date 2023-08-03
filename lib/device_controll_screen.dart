import 'package:bottom_picker/bottom_picker.dart';
import 'package:bottom_picker/resources/arrays.dart';

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

  String _debugText = "_debugText";

  int _lastSendDataTime = 0;

  void _toggleLights(bool value) {
    WaterLampManager.lightsOn = value;
    setState(() {});
    if (_canSendData()) {
      WaterLampManager.setLights();
    }
  }

  void _toggleWater(bool value) {
    WaterLampManager.waterOn = value;

    setState(() {});
    if (_canSendData()) WaterLampManager.setWater();
  }

  void _changeColor(Color color) {
    WaterLampManager.selectedColor = color;
    if (color.red != 0 || color.green != 0 || color.blue != 0) {
      WaterLampManager.lightsOn = true;
    }
    setState(() {});
    if (_canSendData()) {
      WaterLampManager.setColor();
    }
  }

  void _setWater(double newValue) {
    WaterLampManager.waterSpeed = newValue;
    // if (newValue != 0) WaterLampManager.waterOn = true;
    setState(() {});
    if (_canSendData()) {
      WaterLampManager.setWaterSpeed();
    }
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
    BluetoothManager.setOnCurrConnectionStreamChanged(() {
      if (BluetoothManager.getCurrentConnectionState() ==
          DeviceConnectionState.connected) {
        BluetoothManager.startReadingMessage();
      }
      setState(() {});
    });
    BluetoothManager.setOnCurrConnectionStreamDone(() {
      Navigator.pop(context);
    });
    BluetoothManager.setOnCurrConnectionStreamError((p0) {
      Navigator.pop(context);
    });
    BluetoothManager.connectToDevice(widget.bluetoothDevice);
    BluetoothManager.setOnBLEMsgReceived((String value) {
      WaterLampManager.computeMessage(value);
      _debugText = value;
      setState(() {});
    });
  }

  @override
  void dispose() {
    BluetoothManager.setOnCurrConnectionStreamChanged(null);
    BluetoothManager.setOnCurrConnectionStreamDone(null);
    BluetoothManager.setOnCurrConnectionStreamError(null);
    BluetoothManager.setOnBLEMsgReceived(null);
    BluetoothManager.stopReadingMessages();
    BluetoothManager.disconnectDevice();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.bluetoothDevice.name}: ${BluetoothManager.getCurrentConnectionState().name}',
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
              visible: BluetoothManager.getCurrentConnectionState() !=
                  DeviceConnectionState.connected,
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
              visible: BluetoothManager.getCurrentConnectionState() ==
                  DeviceConnectionState.connected,
              child: Column(
                children: [
                  _lightsControll(),
                  _waterControll(),
                  _timerControll(),
                  const SizedBox(height: 20),
                  Text(_debugText),
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.replay_outlined),
                    onPressed: () {
                      WaterLampManager.getState();
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
                value: WaterLampManager.lightsOn,
                onChanged: (bool newValue) {
                  _toggleLights(newValue);
                },
                activeColor: CupertinoColors.activeGreen,
              ),
            ],
          ),
        ),
        Visibility(
          visible: WaterLampManager.lightsOn,
          child: HueRingPicker(
            pickerColor: WaterLampManager.selectedColor,
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
                  value: WaterLampManager.lightsOn,
                  onChanged: (bool newValue) {
                    _toggleLights(newValue);
                  },
                  activeColor: CupertinoColors.activeGreen,
                ),
              ],
            ),
            Visibility(
              visible: WaterLampManager.lightsOn,
              child: HueRingPicker(
                pickerColor: WaterLampManager.selectedColor,
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
                  value: WaterLampManager.waterOn,
                  onChanged: (bool newValue) {
                    _toggleWater(newValue);
                  },
                  activeColor: CupertinoColors.activeGreen,
                ),
              ],
            ),
            Visibility(
              visible: WaterLampManager.waterOn,
              child: CupertinoSlider(
                value: WaterLampManager.waterSpeed,
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

  Widget _timerControll() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
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
                  'Timer',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                CupertinoSwitch(
                  value: WaterLampManager.timerOn,
                  onChanged: (bool newValue) {
                    if (!WaterLampManager.lightsOn &&
                        !WaterLampManager.waterOn) {
                      newValue = false;
                    }
                    WaterLampManager.timerOn = newValue;
                    setState(() {});
                  },
                  activeColor: CupertinoColors.activeGreen,
                ),
              ],
            ),
            Visibility(
              visible: WaterLampManager.timerOn,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(height: 20),
                  CupertinoButton(
                    onPressed: () async {
                      BottomPicker.time(
                        title: 'Set the timer to shut down',
                        titleStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                        displaySubmitButton: true,
                        buttonSingleColor: Colors.black,
                        dismissable: true,
                        displayCloseIcon: false,
                        buttonAlignement: MainAxisAlignment.center,
                        onSubmit: (selectedTime) {
                          // DateTime time = (DateTime)selectedTime;
                          print("index");
                          print(selectedTime);
                        },
                        onClose: () {
                          print('Picker closed');
                        },
                        bottomPickerTheme: BottomPickerTheme.blue,
                        use24hFormat: true,
                      ).show(context);
                    },
                    color: CupertinoColors.systemGrey,
                    child: const Text(
                      'Set Timer',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  // TextButton(
                  //   onPressed: () async {
                  //     BottomPicker.time(
                  //       title: 'Set your next meeting time',
                  //       titleStyle: const TextStyle(
                  //         fontWeight: FontWeight.bold,
                  //         fontSize: 15,
                  //         color: Colors.orange,
                  //       ),
                  //       onSubmit: (index) {
                  //         print(index);
                  //       },
                  //       onClose: () {
                  //         print('Picker closed');
                  //       },
                  //       bottomPickerTheme: BottomPickerTheme.orange,
                  //       use24hFormat: true,
                  //     ).show(context);
                  //   },
                  //   child: const Text("Pick Time"),
                  // ),
                  // // TimePickerSpinnerPopUp(
                  // //   mode: CupertinoDatePickerMode.time,
                  // //   initTime: DateTime.now(),
                  // //   onChange: (dateTime) {
                  // //     // Implement your logic with select dateTime
                  // //   },
                  // // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
