import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:water_mushroom/manager/bluetooth_manager.dart';
import 'device_controll_screen.dart';

class BluetoothDeviceSelectionScreen extends StatefulWidget {
  const BluetoothDeviceSelectionScreen({super.key});

  @override
  State<BluetoothDeviceSelectionScreen> createState() =>
      _BluetoothDeviceSelectionScreenState();
}

class _BluetoothDeviceSelectionScreenState
    extends State<BluetoothDeviceSelectionScreen> {
  final List<DiscoveredDevice> _devices = [];
  StreamSubscription<DiscoveredDevice>? _scanStream;

  Future<void> _listRefreshed() async {}

  @override
  void initState() {
    super.initState();
    try {
      _scanStream = BLEHolder.flutterReactiveBle.scanForDevices(
        withServices: [BLEHolder.serviceUuid],
      ).listen(
        (device) {
          if (_devices.any((element) => element.id == device.id)) return;
          _devices.add(device);
          setState(() {});
        },
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    _scanStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Bluetooth Device',
          style: TextStyle(
            color: Colors.black, // Set the app bar title color to black
          ),
        ),
        backgroundColor:
            Colors.white, // Set the app bar background color to white
      ),
      body: _body(),
    );
  }

// Center(
//           child: TextButton(
//             child: const Text("Test Screen"),
//             onPressed: () => {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => DeviceControlScreen(
//                     bluetoothDevice: DiscoveredDevice(
//                       id: "stset",
//                       manufacturerData: Uint8List.fromList([0]),
//                       name: "Test",
//                       rssi: 22,
//                       serviceData: const <Uuid, Uint8List>{},
//                       serviceUuids: const <Uuid>[],
//                       connectable: Connectable.available,
//                     ),
//                   ),
//                 ),
//               )
//             },
//           ),
//         ),
  Widget _body() {
    return RefreshIndicator(
      onRefresh: _listRefreshed,
      child: ListView.builder(
        itemCount: _devices.length,
        itemBuilder: _bluetoothListTile,
      ),
    );
  }

  Widget _bluetoothListTile(BuildContext context, int index) {
    return ListTile(
      enabled: true,
      title: Text(
        _devices[index].name.isEmpty ? "Empty Name" : _devices[index].name,
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        _devices[index].id,
        style: const TextStyle(
          fontSize: 12.0,
          color: Colors.grey,
        ),
      ),
      onTap: () {
        _scanStream?.cancel();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceControlScreen(
              bluetoothDevice: _devices[index],
            ),
          ),
        );
      },
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    );
  }
}
