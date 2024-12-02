import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:expense_tracker/models/google_signin_api.dart';
import 'dart:async';
import 'dart:convert' show json;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const List<String> scopes = <String>[
  'email',
  'https://www.googleapis.com/auth/contacts.readonly',
];

final _googleSignIn = GoogleSignIn(
  // Optional clientId
  // clientId: '467962354167-ftt32m0datbj6io2a783cb1ivlo8hs71.apps.googleusercontent.com',
  scopes: scopes,
);

class GoogleAuth extends StatefulWidget {
  const GoogleAuth({super.key});

  @override
  State<GoogleAuth> createState() => _GoogleAuthState();
}

class _GoogleAuthState extends State<GoogleAuth> {
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false; // has granted permissions?
  String _contactText = '';

  @override
  void initState() {
    super.initState();

    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
// #docregion CanAccessScopes
      // In mobile, being authenticated means being authorized...
      bool isAuthorized = account != null;
      // However, on web...
      if (kIsWeb && account != null) {
        isAuthorized = await _googleSignIn.canAccessScopes(scopes);
      }
// #enddocregion CanAccessScopes

      setState(() {
        _currentUser = account;
        _isAuthorized = isAuthorized;
      });

      // Now that we know that the user can access the required scopes, the app
      // can call the REST API.
      // if (isAuthorized) {
      //   unawaited(_handleGetContact(account!));
      // }
    });
  }

  // Calls the People API REST endpoint for the signed-in user to retrieve information.
  Future<void> _handleGetContact(GoogleSignInAccount user) async {
    setState(() {
      _contactText = 'Loading contact info...';
    });
    final http.Response response = await http.get(
      Uri.parse('https://people.googleapis.com/v1/people/me/connections'
          '?requestMask.includeField=person.names'),
      headers: await user.authHeaders,
    );
    if (response.statusCode != 200) {
      setState(() {
        _contactText = 'People API gave a ${response.statusCode} '
            'response. Check logs for details.';
      });
      print('People API ${response.statusCode} response: ${response.body}');
      return;
    }
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    final String? namedContact = _pickFirstNamedContact(data);
    setState(() {
      if (namedContact != null) {
        _contactText = 'I see you know $namedContact!';
      } else {
        _contactText = 'No contacts to display.';
      }
    });
  }

  String? _pickFirstNamedContact(Map<String, dynamic> data) {
    final List<dynamic>? connections = data['connections'] as List<dynamic>?;
    final Map<String, dynamic>? contact = connections?.firstWhere(
      (dynamic contact) => (contact as Map<Object?, dynamic>)['names'] != null,
      orElse: () => null,
    ) as Map<String, dynamic>?;

    if (contact != null) {
      final List<dynamic> names = contact['names'] as List<dynamic>;
      final Map<String, dynamic>? name = names.firstWhere(
        (dynamic name) =>
            (name as Map<Object?, dynamic>)['displayName'] != null,
        orElse: () => null,
      ) as Map<String, dynamic>?;
      if (name != null) {
        return name['displayName'] as String?;
      }
    }
    return null;
  }

  Future<void> _loginWithGoogle() async {
    try {
      final user = await _googleSignIn.signIn();
      final googleKey = await user?.authentication;
      print('signed in successfully');
      print(user);
      print(googleKey?.accessToken);
      print(googleKey?.idToken);
      print(_googleSignIn.currentUser?.displayName);
    } catch (error) {
      print('error occured while suignining in');
      print(error);
    }
  }

  Future<void> _handleAuthorizeScopes() async {
    final bool isAuthorized = await _googleSignIn.requestScopes(scopes);
    // #enddocregion RequestScopes
    setState(() {
      _isAuthorized = isAuthorized;
    });
    // #docregion RequestScopes
    // if (isAuthorized) {
    //   unawaited(_handleGetContact(_currentUser!));
    // }
    // #enddocregion RequestScopes
  }

  void _logoutWithGoogle() async {
    debugPrint('Loggin in with google');
    await _googleSignIn.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final GoogleSignInAccount? user = _currentUser;
    if (user != null) {
      return Expanded(
        child: Column(
          children: [
            ListTile(
              leading: GoogleUserCircleAvatar(
                identity: user,
              ),
              title: Text(user.displayName ?? ''),
              subtitle: Text(user.email),
            ),
            const Text('Signed in successfully.'),
            ElevatedButton(
              onPressed: _logoutWithGoogle,
              child: const Text('Logout Google'),
            ),
          ],
        ),
      );
    } else {
      return Expanded(
        child: Column(
          children: [
            const Text('You are not currently signed in.'),
            ElevatedButton(
              onPressed: _loginWithGoogle,
              child: const Text('Login with Google'),
            ),
          ],
        ),
      );
    }
  }
}
