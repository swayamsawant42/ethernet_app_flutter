import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  String _profileData = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    var data = await _api.getProfile();
    setState(() {
      _profileData = data != null ? data.toString() : "Error loading profile";
    });
  }

  void _logout() async {
    // Use ApiService.logout() which handles API call and local storage cleanup
    await _api.logout();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [IconButton(icon: Icon(Icons.logout), onPressed: _logout)],
      ),
      body: Center(child: Text(_profileData)),
    );
  }
}
