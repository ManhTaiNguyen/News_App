import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String avatarUrl = '';

  @override
  void initState() {
    super.initState();
    setAvatarUrl();
  }

  Future<String> getAvatarUrl() async {
    await Future.delayed(const Duration(seconds: 2));
    return "https://imgupscaler.com/images/samples/animal-after.webp";
  }

  Future<void> setAvatarUrl() async {
    avatarUrl = await getAvatarUrl();
    setState(() {}); // Update the UI after setting the avatarUrl
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Async in Flutter'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: CircleAvatar(
          radius: 120,
          backgroundImage:
              NetworkImage(avatarUrl), // Provide the avatarUrl here
        ),
      ),
    );
  }
}
