import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'principal.dart';

void main() => runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: LoginPageWidget()));

class LoginPageWidget extends StatefulWidget {
  @override
  LoginPageWidgetState createState() => LoginPageWidgetState();
}

class LoginPageWidgetState extends State<LoginPageWidget> {
  GoogleSignIn _googleSignIn = GoogleSignIn();
  FirebaseAuth _auth;

  bool isUserSignedIn = false;

  @override
  void initState() {
    super.initState();

    initApp();
  }
//INICIA LA APLICACIÓN CON FIREBASE
  void initApp() async {
    FirebaseApp defaultApp = await Firebase.initializeApp();
    _auth = FirebaseAuth.instanceFor(app: defaultApp);
    checkIfUserIsSignedIn();
  }
//METODO QUE COMPRUEBA SI HA INICIADO SESION
  void checkIfUserIsSignedIn() async {
    var userSignedIn = await _googleSignIn.isSignedIn();

    setState(() {
      isUserSignedIn = userSignedIn;
    });
  }

  //PANTALLA DE INICIO DE SESION
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Iniciar Sesion'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        decoration: new BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/google.gif"),
                alignment: Alignment.topCenter)),
        child: Center(

          child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[

                FlatButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () {
                    onGoogleSignIn(context);
                  },
                  color: isUserSignedIn ? Colors.teal : Colors.blueAccent,
                  child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.account_circle, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                              isUserSignedIn
                                  ? 'Ha iniciado sesión'
                                  : 'Bienvenido/a',
                              style: TextStyle(color: Colors.white)),
                        ],
                      )),
                ),
              ]),
        ),
      ),
    );
  }
//METODO ASINCRONO PARA INICIO DE SESIÓN
  Future<User> _handleSignIn() async {
    User user;
    bool userSignedIn = await _googleSignIn.isSignedIn();

    setState(() {
      isUserSignedIn = userSignedIn;
    });

    if (isUserSignedIn) {
      user = _auth.currentUser;
    } else {
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      user = (await _auth.signInWithCredential(credential)).user;
      userSignedIn = await _googleSignIn.isSignedIn();
      setState(() {
        isUserSignedIn = userSignedIn;
      });
    }

    return user;
  }
//METODO QUE INICIA LA SESION DEL USUARIO
  void onGoogleSignIn(BuildContext context) async {
    User user = await _handleSignIn();
    var userSignedIn = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => WelcomeUserWidget(user, _googleSignIn)),
    );

    setState(() {
      isUserSignedIn = userSignedIn == null ? true : false;
    });
  }
}
//CLASE QUE DA LA BIENVENIDA AL USUARIO
class WelcomeUserWidget extends StatelessWidget {
  GoogleSignIn _googleSignIn;
  User _user;

  WelcomeUserWidget(User user, GoogleSignIn signIn) {
    _user = user;
    _googleSignIn = signIn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Sesión iniciada'),
          backgroundColor: Colors.blueAccent,
          iconTheme: IconThemeData(color: Colors.black),
          elevation: 0,
        ),
        body: Container(
            color: Colors.white,
            padding: EdgeInsets.all(10),
            child: Align(
                alignment: Alignment.center,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 380.0,
                        height: 150.0,
                        child: Image.asset('assets/google.gif'),
                      ),
                      ClipOval(
                          child: Image.network(_user.photoURL,
                              width: 100, height: 100, fit: BoxFit.cover)),
                      SizedBox(height: 20),
                      Text('Bienvenido/a,', textAlign: TextAlign.center),
                      Text(_user.displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 25)),
                      SizedBox(height: 20),
                      FlatButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onPressed: () {
                            _googleSignIn.signOut();
                            Navigator.pop(context, false);
                          },
                          color: Colors.redAccent,
                          child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Icon(Icons.exit_to_app, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text('Cerrar sesión',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ))),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.all(30),
                                child: FlatButton(
                                    color: Colors.blueAccent,
                                    shape: new RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => MyHomePage()),
                                      );
                                    },
                                    child: SizedBox(
                                      width: 240,
                                      height: 50,
                                      child: Center(
                                        child: Text("ENTRAR EN EXPENSIVOO",
                                            textAlign: TextAlign.center),
                                      ),
                                    )),
                              ),
                            ],
                          ),
                        ],
                      )
                    ]))));
  }
}
