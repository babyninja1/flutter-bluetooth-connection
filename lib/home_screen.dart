import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BluetoothConnection? connection;
  bool isConnected = false;
  Timer? _reconnectTimer;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    connectToDevice();
  }

  Future<void> connectToDevice() async {
    try {
      connection = await BluetoothConnection.toAddress("00:22:09:01:FA:CD");
     // print('Connected to the device');
      setState(() {
        isConnected = true;
      });
      _audioPlayer.play(AssetSource('audio/connected.mp3'));

      connection!.input?.listen((Uint8List data) {
        handleDataReceived(data);
      }).onDone(() {
        handleDisconnection();
      });
    } catch (e) {
     // print('Cannot connect, exception occurred: $e');
      setState(() {
        isConnected = false;
      });
      startReconnectTimer();
    }
  }

  void handleDataReceived(Uint8List data) {
  //  print('Data incoming: ${ascii.decode(data)}');
    Map<String, dynamic> parsedData = jsonDecode(ascii.decode(data));
    double distance = parsedData['distance'];
    int water = parsedData['water'];
    if(distance <=10){
      _audioPlayer.play(AssetSource('audio/10.mp3'));
    }
    else
    if(distance <=20){
      _audioPlayer.play(AssetSource('audio/20.mp3'));
    }
    else
    if(distance <=30){
      _audioPlayer.play(AssetSource('audio/30.mp3'));
    }
    else
    if(distance <=40){
        _audioPlayer.play(AssetSource('audio/40.mp3'));
      }
  else  if (distance <= 50) {
      _audioPlayer.play(AssetSource('audio/50.mp3'));
    } else if (distance <= 100) {
      _audioPlayer.play(AssetSource('audio/100.mp3'));
    } else if (distance <= 150) {
      _audioPlayer.play(AssetSource('audio/150.mp3'));
    } else if (water > 300) {
      _audioPlayer.play(AssetSource('audio/water.mp3'));
    }

    if (ascii.decode(data).contains('!')) {
      connection?.finish(); // Closing connection
    //  print('Disconnecting by local host');
      _audioPlayer.play(AssetSource('audio/disconnected.mp3'));
    }
  }

  void handleDisconnection() {
    //print('Disconnected by remote request');
    setState(() {
      isConnected = false;
    });
    _audioPlayer.play(AssetSource('audio/disconnected.mp3'));
    startReconnectTimer(); // Start trying to reconnect
  }

  void startReconnectTimer() {
    _reconnectTimer?.cancel(); // Cancel any existing timer
    _reconnectTimer =
        Timer.periodic(const Duration(seconds: 5), (Timer t) async {
      if (!isConnected) {
      //  print('Attempting to reconnect...');
        try {
          await connectToDevice();
        } catch (e) {
        //  print('Reconnect failed: $e');
        }
      }
      if (isConnected) {
      //  print("Reconnection successful.");
        setState(() {
          _reconnectTimer
              ?.cancel(); // Stop the timer if connection is reestablished
        });
      }
    });
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    connection?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isConnected ? "Connected" : "Disconnected"),
            ElevatedButton(
                onPressed: () {
                  if (!isConnected) {
                    connectToDevice();
                  }
                },
                child: const Text("Connect")),
          ],
        ),
      ),
    );
  }
}
