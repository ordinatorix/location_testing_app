import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import './logger.dart';
import './services/location_service.dart';
import './models/location_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // set log level to info
  Logger.level = Level.debug;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  final LocationService _locationService = LocationService();
  final log = getLogger('MyApp');
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<DeviceLocation>.value(
          value: _locationService.locationStream,
        ),
      ],
      child: MaterialApp(
        title: 'Location Tester',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final log = getLogger('homePage');
  DeviceLocation _currentLocation =
      DeviceLocation(latitude: 0.0, longitude: 0.0, accuracy: 0.0);

  @override
  Widget build(BuildContext context) {
    _currentLocation = Provider.of<DeviceLocation>(context, listen: true);
    log.d('$_currentLocation');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'The streamed location is:',
            ),
            Consumer<DeviceLocation>(
              builder: (context, location, _) {
                return Text(
                  '$_currentLocation',
                  style: Theme.of(context).textTheme.headline4,
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
