import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  AccessToken? _accessToken;
  Map<String, dynamic>? _userData;
  String _photoUrl = '';

  String prettyPrint(Map json) {
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    String pretty = encoder.convert(json);
    return pretty;
  }

  void _printCredentials() {
    print('pretty printing accesstoken');
    print(
      prettyPrint(_accessToken!.toJson()),
    );
  }

  void _loginWithFacebook() async {
    debugPrint('Loggin in with facebok');
    print("FaceBook");
    final LoginResult result = await FacebookAuth.instance.login();
    // by default we request the email and the public profile
    // or FacebookAuth.i.login()
    if (result.status == LoginStatus.success) {
      // you are logged
      _accessToken = result.accessToken!;
      _printCredentials();

      // get the user data
      // by default we get the userId, email,name and picture
      final userData = await FacebookAuth.instance.getUserData(
          fields: "name,email,picture.width(200),birthday,friends,gender,link");
      // final userData = await FacebookAuth.instance.getUserData(fields: "email,birthday,friends,gender,link");

      setState(() {
        _userData = userData;
      });

      if (_userData != null) {
        _photoUrl = _userData?['picture']['data']['url'] +
            "?height=500&access_token=" +
            _accessToken?.token;
      }

      print(_userData);
      print(_userData?['picture']['data']['url']);
      print(_photoUrl);
    } else {
      print(result.status);
      print(result.message);
    }
  }

  Future<void> _logOut() async {
    await FacebookAuth.instance.logOut();
    _accessToken = null;
    _userData = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_userData != null) {
      return Expanded(
        child: Column(
          children: [
            ListTile(
              // leading: const Image(
              //   image: NetworkImage(
              //       'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg'),
              // ),
              title: Text(_userData!['name']),
              subtitle: Text(_userData!['email']),
            ),
            const Text('Signed in successfully in FB.'),
            ElevatedButton(
              onPressed: _logOut,
              child: const Text('Logout Facebook'),
            ),
          ],
        ),
      );
    } else {
      return Expanded(
        child: Column(
          children: [
            const Text('Not signed in FB yet.'),
            ElevatedButton(
              onPressed: _loginWithFacebook,
              child: const Text('Login with Facebook'),
            ),
          ],
        ),
      );
    }
  }
}
