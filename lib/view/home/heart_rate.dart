import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(MaterialApp(
    home: MainApp(),
    theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
  ));
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text("Salowê Fitness"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: media.width * 0.02),
            HeartRateMonitor(),
            SizedBox(height: media.width * 0.05),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _enableNotifications = true;
  double _heartRateThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
      _heartRateThreshold = prefs.getDouble('heartRateThreshold') ?? 100.0;
    });
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableNotifications', _enableNotifications);
    await prefs.setDouble('heartRateThreshold', _heartRateThreshold);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Enable Heart Rate Alerts'),
            value: _enableNotifications,
            onChanged: (bool value) {
              setState(() {
                _enableNotifications = value;
                _saveSettings();
              });
            },
          ),
          ListTile(
            title: Text('Heart Rate Alert Threshold'),
            subtitle: Text('${_heartRateThreshold.round()} BPM'),
            trailing: Slider(
              value: _heartRateThreshold,
              min: 60.0,
              max: 180.0,
              divisions: 120,
              label: _heartRateThreshold.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _heartRateThreshold = value;
                  _saveSettings();
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HeartRateMonitor extends StatefulWidget {
  @override
  _HeartRateMonitorState createState() => _HeartRateMonitorState();
}

class _HeartRateMonitorState extends State<HeartRateMonitor> {
  StreamSubscription? _scanSubscription;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _heartRateCharacteristic;

  List<FlSpot> allSpots = [];
  int currentTime = 0;
  bool isScanning = false;
  int currentBPM = 0;
  bool isSimulationMode = false;
  
  // Statistical tracking
  int maxBPM = 0;
  int minBPM = 1000;
  double averageBPM = 0;
  int totalReadings = 0;

  // Notification threshold
  bool _enableNotifications = true;
  double _heartRateThreshold = 100.0;

  // Fingerprint authentication
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _isFingerPrintMode = false;
  int _fingerPrintHeartRate = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _requestPermissions();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
      _heartRateThreshold = prefs.getDouble('heartRateThreshold') ?? 100.0;
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
    startScan();
  }

  void _checkHeartRateAlert(int bpm) {
    if (_enableNotifications && bpm > _heartRateThreshold) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('High Heart Rate Alert: $bpm BPM'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateHeartRateStats(int bpm) {
    maxBPM = bpm > maxBPM ? bpm : maxBPM;
    minBPM = bpm < minBPM ? bpm : minBPM;
    
    totalReadings++;
    averageBPM = ((averageBPM * (totalReadings - 1)) + bpm) / totalReadings;
  }

  Future<void> startScan() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        print("Bluetooth not supported");
        _startSimulation("Bluetooth not supported");
        return;
      }

      if (await FlutterBluePlus.isOn == false) {
        await FlutterBluePlus.turnOn();
      }

      setState(() {
        isScanning = true;
        isSimulationMode = false;
      });

      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 4),
        androidUsesFineLocation: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.platformName.toLowerCase().contains("heart") || 
              result.device.platformName.toLowerCase().contains("hrm") ||
              result.device.platformName.toLowerCase().contains("polar") ||
              result.device.platformName.toLowerCase().contains("wahoo") ||
              result.device.platformName.toLowerCase().contains("garmin")) {
            _connectToDevice(result.device);
            return;
          }
        }
      });

      FlutterBluePlus.isScanning.listen((scanning) {
        if (scanning == false && mounted) {
          setState(() {
            isScanning = false;
          });
          if (_device == null) {
            _startSimulation("No heart rate device found");
          }
        }
      });
    } catch (e) {
      print("Error scanning: $e");
      _startSimulation("Scan error: $e");
    }
  }

  void _startSimulation(String reason) {
    if (mounted) {
      setState(() {
        isSimulationMode = true;
        isScanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Simulation Mode Active: $reason'),
          backgroundColor: Colors.orange,
        ),
      );

      Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted && _device == null) {
          setState(() {
            currentBPM = 60 + (DateTime.now().second % 40);
            _checkHeartRateAlert(currentBPM);
            _updateHeartRateStats(currentBPM);
            allSpots.add(FlSpot(currentTime.toDouble(), currentBPM.toDouble()));
            if (allSpots.length > 50) {
              allSpots.removeAt(0);
            }
            currentTime++;
          });
        } else {
          timer.cancel();
        }
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _device = device;
      await _discoverServices();
    } catch (e) {
      print("Error connecting to device: $e");
      _startSimulation("Device connection error");
    }
  }

  Future<void> _discoverServices() async {
    try {
      List<BluetoothService> services = await _device!.discoverServices();
      for (var service in services) {
        if (service.uuid == Guid("0000180d-0000-1000-8000-00805f9b34fb")) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == Guid("00002a37-0000-1000-8000-00805f9b34fb")) {
              _heartRateCharacteristic = characteristic;
              await _startReading();
              return;
            }
          }
        }
      }
      print("Heart rate service not found");
      _startSimulation("Heart rate service not found");
    } catch (e) {
      print("Error discovering services: $e");
      _startSimulation("Service discovery error");
    }
  }

  Future<void> _startReading() async {
    try {
      await _heartRateCharacteristic?.setNotifyValue(true);
      _heartRateCharacteristic?.onValueReceived.listen((value) {
        if (value.isNotEmpty) {
          int flag = value[0] & 0x01;
          int heartRate;
          if (flag == 0) {
            heartRate = value[1];
          } else {
            heartRate = (value[2] << 8) + value[1];
          }

          if (mounted) {
            setState(() {
              currentBPM = heartRate;
              _checkHeartRateAlert(heartRate);
              _updateHeartRateStats(heartRate);
              allSpots.add(FlSpot(currentTime.toDouble(), heartRate.toDouble()));
              if (allSpots.length > 50) {
                allSpots.removeAt(0);
              }
              currentTime++;
            });
          }
        }
      });
    } catch (e) {
      print("Error starting notifications: $e");
      _startSimulation("Notification setup error");
    }
  }

  Future<void> stop() async {
    try {
      _scanSubscription?.cancel();
      await FlutterBluePlus.stopScan();
      if (_device != null) {
        await _device?.disconnect();
      }
    } catch (e) {
      print("Error stopping: $e");
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  Widget _buildHeartRateStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text('Max', style: TextStyle(color: Colors.white70)),
            Text('$maxBPM', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        Column(
          children: [
            Text('Min', style: TextStyle(color: Colors.white70)),
            Text('${minBPM == 1000 ? '-' : minBPM}', 
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        Column(
          children: [
            Text('Avg', style: TextStyle(color: Colors.white70)),
            Text('${averageBPM.toStringAsFixed(1)}', 
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Future<void> _authenticateAndMeasureHeartRate() async {
  try {
    bool canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
    if (!canCheckBiometrics) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Biometric authentication not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Attempt fingerprint authentication
    bool authenticated = await _localAuthentication.authenticate(
      localizedReason: 'Scan fingerprint to measure heart rate',
      options: AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );

    if (authenticated) {
      // If fingerprint authentication is successful, start measuring heart rate
      if (_device != null) {
        // If a Bluetooth device is connected, use actual heart rate readings
        setState(() {
          _isFingerPrintMode = false;
          currentBPM = _fingerPrintHeartRate; // Set this to the actual heart rate from the Bluetooth device
          _checkHeartRateAlert(currentBPM);
          _updateHeartRateStats(currentBPM);
        });
      } else {
        // Simulated heart rate measurement based on fingerprint authentication
        int simulatedHeartRate = _simulateHeartRateFromFingerprint();
        
        setState(() {
          _isFingerPrintMode = true;
          _fingerPrintHeartRate = simulatedHeartRate;
          currentBPM = simulatedHeartRate;
          _checkHeartRateAlert(simulatedHeartRate);
          _updateHeartRateStats(simulatedHeartRate);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulation Mode: Fingerprint scan used to simulate heart rate measurement.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fingerprint authentication failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print("Error during authentication: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error during authentication: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  int _simulateHeartRateFromFingerprint() {
    // Advanced biometric heart rate simulation
    DateTime now = DateTime.now();
    int baseRate = 60;
    int variation = now.second % 20;  // Add some variation
    int timeOfDayFactor = now.hour < 12 ? 5 : -5;
    
    return baseRate + variation + timeOfDayFactor;
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    final lineBarsData = [
      LineChartBarData(
        spots: allSpots,
        isCurved: true,
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.4),
              Colors.blue.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
         gradient: LinearGradient(colors: [Colors.blue, Colors.green]),),
    
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: media.width * 0.5,  // Slightly increased height
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
             
              if (isSimulationMode)
                Positioned(
                  top: 12,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Simulation Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "HR(Heart Rate)",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "Current BPM: ",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "$currentBPM",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    if (_device != null)
                      Text(
                        "Connected to: ${_device!.platformName}",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: LineChart(
                    LineChartData(
                      lineBarsData: lineBarsData,
                      minY: 40,
                      maxY: 120,
                      titlesData: FlTitlesData(show: false),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.transparent),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeartRateStats(),
                    ElevatedButton.icon(
                      onPressed: _authenticateAndMeasureHeartRate,
                      icon: Icon(Icons.fingerprint),
                      label: Text('Measure HR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isFingerPrintMode)
                Positioned(
                  top: 12,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Fingerprint Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}