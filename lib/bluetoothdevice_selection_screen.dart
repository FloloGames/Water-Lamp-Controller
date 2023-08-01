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
  Future<void> _listRefreshed() async {
    await BluetoothManager.stopScan();
    await Future.delayed(const Duration(seconds: 1));
    await BluetoothManager.startScan();
  }

  @override
  void initState() {
    super.initState();
    BluetoothManager.setOnScanStreamChanged(() => setState(() {}));
    BluetoothManager.startScan();
  }

  @override
  void dispose() {
    BluetoothManager.setOnScanStreamChanged(null);
    BluetoothManager.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Bluetooth Device',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
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
        itemCount: BluetoothManager.getDevices().length,
        itemBuilder: _bluetoothListTile,
      ),
    );
  }

  Widget _bluetoothListTile(BuildContext context, int index) {
    return ListTile(
      enabled: true,
      title: Text(
        BluetoothManager.getDevices()[index].name.isEmpty
            ? "Empty Name"
            : BluetoothManager.getDevices()[index].name,
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        BluetoothManager.getDevices()[index].id,
        style: const TextStyle(
          fontSize: 12.0,
          color: Colors.grey,
        ),
      ),
      onTap: () {
        BluetoothManager.stopScan();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceControlScreen(
              bluetoothDevice: BluetoothManager.getDevices()[index],
            ),
          ),
        );
      },
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    );
  }
}
