import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gsheets/gsheets.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:dropdownfield/dropdownfield.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:introduction_screen/introduction_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'EXPENSIVO'),
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
  //WIDGET FECHA
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  GoogleSignIn _googleSignIn;
  User _user;

  WelcomeUserWidget(User user, GoogleSignIn signIn) {
    _user = user;
    _googleSignIn = signIn;
  }

  Future<Null> _selectDate(BuildContext context) async {
    final TimeOfDay picked_s = await showTimePicker(
        context: context,
        initialTime: selectedTime,
        builder: (BuildContext context, Widget child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child,
          );
        });

    if (picked_s != null && picked_s != selectedTime)
      setState(() {
        selectedTime = picked_s;
      });
  }

  //CONTROLADORES PARA LOS TEXTFIELD Y DROPDOWNLIST///
  final my_controller = TextEditingController();
  final my_controller_concepto = TextEditingController();
  final my_controller_cantidad = TextEditingController();
  final my_controller_dni = TextEditingController();
  var tipo;
  DocumentReference ref;
  final databaseReferencef = Firestore.instance;

  Map<String, dynamic> formData;
  List<String> tipos = [
    'Hipoteca/alquiler',
    'Compras',
    'Luz',
    'Agua',
    'Otros gastos',
  ];
//metodo para salir de la aplicación
  void salir() {
    setState(() {
      exit(0);
    });
  }

  //METODO PARA MOSTRAR MENSAJE AL PULSAR EN SALIR
  void mostrarMensaje() {
    // set up the buttons
    Widget YesButton = FlatButton(
      child: Text("SI"),
      onPressed: () {
        salir();
      },
    );
    Widget NoButton = FlatButton(
      child: Text("NO"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    //MUESTRA UN CUADRO DE DIALOGO AL PULSAR EN SALIR
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("SALIR"),
              content: Text("¿Desea salir de la aplicacion?"),
              actions: <Widget>[NoButton, YesButton],
            ));
  }

  @override
  Widget build(BuildContext context) {
    //BARRA DE ACCION
    return Scaffold(
      drawer: MenuLateral(),
      appBar: AppBar(
        backgroundColor: Color(0xff1976d2),
        title: Text('EXPENSIVO'),
        centerTitle: true,
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 20,
              ),
              TextField(
                controller: my_controller_dni,
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 13.0,
                    height: 1.0,
                    fontWeight: FontWeight.w400),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                    icon: Icon((LineAwesomeIcons.address_card)),
                    hintText: 'DNI',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2.0),
                    )),
              ),
              TextField(
                controller: my_controller_cantidad,
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 13.0,
                    height: 1.0,
                    fontWeight: FontWeight.w400),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                    icon: Icon((LineAwesomeIcons.donate)),
                    hintText: 'Introduzca la cantidad',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2.0),
                    )),
              ),
              SizedBox(
                height: 20,
              ),
              DropDownField(
                  value: formData,
                  required: false,
                  strict: true,
                  labelText: 'Tipo de gasto',
                  icon: Icon((LineAwesomeIcons.stream)),
                  items: tipos,
                  controller: my_controller,
                  setter: (dynamic newValue) {
                    my_controller.text = newValue;
                  }),
              SizedBox(
                height: 30,
              ),
              TextField(
                controller: my_controller_concepto,
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 13.0,
                    height: 1.0,
                    fontWeight: FontWeight.w400),
                keyboardType: TextInputType.text,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                    icon: Icon((LineAwesomeIcons.comment)),
                    hintText: 'Concepto o Nota',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2.0),
                    )),
              ),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                  width: 350,
                  height: 50,
                  child: RaisedButton.icon(
                    icon: Icon((LineAwesomeIcons.save)),
                    textColor: Colors.white,
                    color: Colors.lightBlue,
                    label: const Text('GUARDAR'),
                    onPressed: () async {
                      if (my_controller.text == null ||
                          my_controller.text == "" &&
                              my_controller_cantidad.text == null ||
                          my_controller_cantidad.text == "" &&
                              my_controller_concepto.text == null ||
                          my_controller_concepto.text == "" ||
                          my_controller_dni.text == null ||
                          my_controller_dni.text == "") {
                        Widget OKButton = FlatButton(
                          child: Text("OK"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        );
                        showDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                                  title: Text("ERROR AL INSERTAR"),
                                  content: Text("No debe haber campos vacios"),
                                  actions: <Widget>[OKButton],
                                ));
                      } else {
                        ref = await databaseReferencef.collection("Gastos").add(
                          {
                            'DNI': my_controller_dni.text,
                            'Concepto': my_controller_concepto.text,
                            'fecha': new DateFormat('yyyy-MM-dd – kk:mm')
                                .format(DateTime.now()),
                            'Tipo': my_controller.text,
                            'Cantidad': my_controller_cantidad.text,
                          },
                        );

                        final gsheets = GSheets(r"""
{
  "type": "service_account",
  "project_id": "sylvan-shuttle-289806",
  "private_key_id": "0a0cb424507ac2f5f862db571920caaea5022bfb",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCdjSO3kZ7j/NSq\nhN5YWJm/bY4gFHv703uDgk06vcBDWwflUaJjArfoEMKjCfrUx0UUwBYgjxUg2o6f\n/02N6VbVsCE95A9gyp4jwWdLd+7LLbji2wm3vGnpFvIaeCMcPTUkmnjV3XFxkvwU\n1XAZvgh/5pCkoYE8puZC/BA2hNTCoUb8vUnwWUtQSCm89uyH7QZoBNTlLSIH9ZkB\nx1kTDDhkfU1YH0DVbLkhGlS73Tb5rLZYaerfxkeX3fdFZkun3iikTMSWp19tzJTz\nu+4S15BENu4u3hge1cMUC+23Ea+Mxr4OER8wcLBWRV0Bg8WeukpaXPomnB3ckfex\nF+x+dSfpAgMBAAECggEATWLalNuflm+FC/64cd+PIVJQGZzGK3L8u6NAiOZULiFj\n9vUKlKRsrb2xxMBtpp78ZQ1WsQZmw9zmaltN/jMLVmmtYkeHcC0F0R05vf16Wu0p\n36/kDY4r3XRKVcsFv+SmmkSPrsiW5MjkLd2KsvI/HYekK2Ey6BY4itVhp03GbZRh\nzagGJM6fonJiWQ3zti5XAEREJOOxSgKe+dRXLf0H5uEZ40KUBlYsfqs1Ya5bQXVL\n0XNw4pSmy68CeRoR9vYz//gD73WOWeeR51UpCG7gyuNVG33Ud/Jg4Olr1tHrOJ5E\nv77XJy0uKs4g6+r0O4Qu/K0zrnKEdp7SuYUcfPPIwwKBgQDJAvXISWOPgdvgQGib\nzcrEsQt/43dtwt11WB2sKGh6eEYEqdP5jYp7kPG38Jm7KcOHIB1UyLh9y4CPILNY\nZHLlIuNETJ2Gc6sjUoiqffD8La/j65JiS4ii1JIKDKRjqhCVskN8oI+US3eKyMEi\n+K5H6TlGtdpwI/GQe2U0O9Z13wKBgQDIpp2kKwYIdiDjuY7xBRA28zF9jliKlqIz\nlp0ZJ1EUMJvY3BDbIBZKve65hRZkgBsFhKiUd7C2G9x2EEe9bXae0g5QEINTbrF/\n9ATKK/I7NgHRNTtiPqfInoowtYrugllrNma1Y8qHeo5svdEzDqMO7Lz3NjkyILuG\n5PbMZVbLNwKBgFrrXtZ/82t2tkhhea93Ts7Wsbff4CYibN7lw04aXN+ARVNYqYuH\n7OplLiAf0Lkqc8lLyliODXzArl6O0PAbRyjDNf6vlNS6vt7UNwK+wmCeHZ++7tBN\nD/luoruu6jA2PRgosIPPcAIIfIKmuU0jJFlccU69dJcieuH6HlWY9zELAoGAGx+C\nsb1rHFuziHT94JC5p2Pqbbl/OISyOl0CsXLCIAOOHZtp3+UPflz8VzGpXD6A6JcN\nHryrM4LCo2cB+5Y/caqdaq9AwVd2QQCgYR/dp6leR4R1mYs0rQbZUUpJFIKkSbzZ\n12085GFpvUNPcyJoYk0YIia/RopsLwjmX6zXNbMCgYAtgyt2+e6Uyiwuw4M7JjAk\nkEtkU45i3qN4O1lkQUd7vvGqXO7lMvDpQ3wMz/pcADPbf8T5JPlfXqr98Py2LDM/\nveenCFhi2HtmLvLMfvbT36aSkBOrOxnO/htk5WTyxlbtBduMXWfD/pWIMZ9NEQJn\nCrwFLPU3lm6mu78xy5Hx2w==\n-----END PRIVATE KEY-----\n",
  "client_email": "gsheets@sylvan-shuttle-289806.iam.gserviceaccount.com",
  "client_id": "112240124153226324660",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/gsheets%40sylvan-shuttle-289806.iam.gserviceaccount.com"
}

""");
                        // fetch spreadsheet by its id
                        final ss = await gsheets.spreadsheet(
                            '1YV9YYQ9XN6WXm4Le3wIAFgRw7UQ6w2HCGzvFwoFw9T8');
                        // get worksheet by its title
                        var sheet = await ss.worksheetByTitle('datos');
                        // create worksheet if it does not exist yet
                        sheet ??= await ss.addWorksheet('datos');

                        await sheet.values.appendRow(
                          [
                            my_controller_dni.text,
                            my_controller.text,
                            my_controller_cantidad.text,
                            my_controller_concepto.text,
                            DateTime.now().toString(),
                          ],
                        );
                        Widget OKButton = FlatButton(
                          child: Text("OK"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        );
                        showDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                                  title: Text("GUARDAR"),
                                  content: Text("Se ha guardado con exito"),
                                  actions: <Widget>[OKButton],
                                ));
                        my_controller_dni.clear();
                        my_controller.clear();
                        my_controller_concepto.clear();
                        my_controller_cantidad.clear();
                      }
                    },
                  )),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                  width: 350,
                  height: 50,
                  child: RaisedButton.icon(
                      icon: Icon((LineAwesomeIcons.list_ul)),
                      textColor: Colors.white,
                      color: Colors.teal,
                      label: const Text('VER LISTADO'),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) => Listado()));
                      })),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                  height: 120,
                  child: Container(
                    decoration: new BoxDecoration(
                        image: new DecorationImage(
                            image: new AssetImage("assets/gastos.png"),
                            fit: BoxFit.cover)),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

//MENU LATERAL CON UN APARTADO PARA ALGUNAS FUNCIONALIDADES DE LA APLICACION
class MenuLateral extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Drawer(
      child: ListView(
        children: <Widget>[
          Container(
              padding: EdgeInsets.only(top: 40),
              child: DrawerHeader(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage("assets/gastos.png"),
                          alignment: Alignment.topCenter)))),
          Ink(
            color: Colors.grey,
            child: new ListTile(
              title: Text("INFORMACION"),
              trailing: Icon(Icons.arrow_forward),
              leading: Icon((LineAwesomeIcons.exclamation_circle)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => Informacion()));
              },
            ),
          ),
          new ListTile(
              title: Text("DEMOSTRACION"),
              trailing: Icon(Icons.arrow_forward),
              leading: Icon((LineAwesomeIcons.photo_video)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => Demo()));
              }),
          new ListTile(
              title: Text("COMPRAS ONLINE"),
              trailing: Icon(Icons.arrow_forward),
              leading: Icon((LineAwesomeIcons.add_to_shopping_cart)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => Tienda()));
              }),
          new ListTile(
              title: Text("GOOGLE SHEETS"),
              trailing: Icon(Icons.arrow_forward),
              leading: Icon((LineAwesomeIcons.excel_file)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => Excel()));
              }),
          new ListTile(
            title: Text("SALIR DE LA APLICACION"),
            leading: Icon((LineAwesomeIcons.arrow_circle_left)),
            onTap: () {
              Widget yesButton = FlatButton(
                child: Text("SI"),
                onPressed: () {
                  exit(0);
                },
              );
              Widget noButton = FlatButton(
                child: Text("NO"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              );
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("SALIR"),
                  content: Text("¿Desea salir de la aplicacion?"),
                  actions: <Widget>[noButton, yesButton],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class Listado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listado de Gastos'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Gastos')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            return new ListView(
                children:
                    snapshot.data.docs.map((DocumentSnapshot documentSnapshot) {
              return Card(
                  child: ListTile(
                leading: documentSnapshot.data()['Tipo'] == 'Hipoteca/alquiler'
                    ? CircleAvatar(child: Icon((LineAwesomeIcons.home)))
                    : documentSnapshot.data()['Tipo'] == 'Compras'
                        ? CircleAvatar(
                            child:
                                Icon((LineAwesomeIcons.add_to_shopping_cart)))
                        : documentSnapshot.data()['Tipo'] == 'Luz'
                            ? CircleAvatar(
                                child: Icon((LineAwesomeIcons.lightbulb)))
                            : documentSnapshot.data()['Tipo'] == 'Agua'
                                ? CircleAvatar(
                                    child: Icon((LineAwesomeIcons.tint)))
                                : documentSnapshot.data()['Tipo'] ==
                                        'Otros gastos'
                                    ? CircleAvatar(
                                        child: Icon((LineAwesomeIcons.coins)))
                                    : CircleAvatar(
                                        backgroundColor: Colors.black),
                title: Text(documentSnapshot.data()['fecha']),
                subtitle: Text(documentSnapshot.data()['Cantidad']),
              ));
            }).toList());
          }
        },
      ),
    );
  }
}

//Clase informacion
class Informacion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/flutter.jpg'), fit: BoxFit.cover)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("Información"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.blueAccent,
        ),
        body: Container(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: 10),
              ),
              Text(
                ' EXPENSIVO es una aplicación creada para llevar un registro '
                'personal de los gastos que produce el usuario sin necesidad de '
                'sincronizar con entidades bancarias, por lo que el usuario es'
                ' el unico que puede acceder a los datos de sus gastos',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    height: 1,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              SizedBox(
                width: 200,
                height: 250,
              ),
              Text(
                ' Desarrollado por David Fuentes Fernandez ',
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: Colors.white,
                    height: 5,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//CLASE PARA COMPRAS ONLINE
class Tienda extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Compras online"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/amazon.gif"),
                  alignment: Alignment.topCenter)),
          child: Column(children: <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: 190),
            ),
            SizedBox(
                width: 370,
                height: 50,
                child: RaisedButton.icon(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0))),
                    icon: Icon((LineAwesomeIcons.shopping_cart_arrow_down)),
                    textColor: Colors.white,
                    color: Colors.blueGrey,
                    label: const Text('IR A TIENDA AMAZON'),
                    onPressed: () async {
                      const url = 'https://www.amazon.com';
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    })),
            SizedBox(
              width: 100,
              height: 50,
            ),
            SizedBox(
              width: 380.0,
              height: 150.0,
              child: Image.asset('assets/aliexpress.gif'),
            ),
            SizedBox(
                width: 350,
                height: 50,
                child: RaisedButton.icon(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0))),
                    icon: Icon((LineAwesomeIcons.shopping_cart_arrow_down)),
                    textColor: Colors.white,
                    color: Colors.deepOrangeAccent,
                    label: const Text('IR A LA WEB'),
                    onPressed: () async {
                      const url = 'https://www.aliexpress.com';
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    })),
          ])),
    );
  }
}

//CLASE QUE VISUALIZA LA HOJA DE CALCULO CONECTADA CON GOOGLE SHEETS Y FIREBASE
class Excel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Google Sheets"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.blueAccent,
        ),
        body: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/excel.png"),
                    alignment: Alignment.topCenter)),
            child: Column(children: <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: 120),
              ),
              SizedBox(
                width: 380.0,
                height: 320.0,
                child: Image.asset('assets/animacion.gif'),
              ),
              SizedBox(
                  width: 350,
                  height: 50,
                  child: RaisedButton.icon(
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10.0))),
                      icon: Icon((LineAwesomeIcons.excel_file)),
                      textColor: Colors.white,
                      color: Colors.green,
                      label: const Text('VISUALIZAR HOJA DE CALCULO'),
                      onPressed: () async {
                        const url =
                            'https://docs.google.com/spreadsheets/d/1YV9YYQ9XN6WXm4Le3wIAFgRw7UQ6w2HCGzvFwoFw9T8/edit?ouid=118032955474758436982&usp=sheets_home&ths=true';
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          throw 'Could not launch $url';
                        }
                      })),
            ])));
  }
}
//CLASE QUE VISUALIZA DESLIZANTE DEMOSTRATIVO DEL USO DE LA APLICACION

class Demo extends StatelessWidget {
  final introKey = GlobalKey<IntroductionScreenState>();

  void _onIntroEnd(context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MyHomePage()),
    );
  }

  Widget _buildImage(String assetName) {
    return Align(
      child: Image.asset('assets/$assetName.jpg', width: 350.0),
      alignment: Alignment.bottomCenter,
    );
  }
  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);
    const pageDecoration = const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      descriptionPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      key: introKey,
      pages: [
        PageViewModel(
          title: "Conecta con Google",
          body:
          "Mediante un inicio de sesion sencillo conectaras con Google inmediatamente",
          image: Image.asset('assets/google2.jpg'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Facil insercion de tus gastos",
          body:
          "Rellena los campos para guardar tus gastos correctamente",
          image: Image.asset('assets/gestion2.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Listado intuitivo y sencillo",
          body: "Visualiza tus gastos de la manera mas sencilla diferenciando cada tipo",
          image: Image.asset('assets/lista.jpg'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Webs de Compras online",
          body:
          "Realiza tus compras desde la misma aplicacion redirigiendo a las paginas web",
          image: Image.asset('assets/compras3.png'),
          decoration: pageDecoration,
        ),

        PageViewModel(
          title: "Guarda en Drive hoja de cálculo",
          body: "Guarda tus gastos en una hoja de calculo que podra descargar en un futuro si lo desea",
          image: Image.asset('assets/sheets.jpg'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Ya esta todo listo",
          bodyWidget: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text("Pulsa sobre el botón", style: bodyStyle),

            ],
          ),
          image: Image.asset('assets/ok.gif'),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      //onSkip: () => _onIntroEnd(context), // You can override onSkip callback
      showSkipButton: true,
      skipFlex: 0,
      nextFlex: 0,
      skip: const Text('Saltar'),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Hecho', style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}








