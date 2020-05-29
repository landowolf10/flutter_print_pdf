import 'dart:async';
import 'dart:convert';

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  List<String> listaProductos = new List<String>();
  List<int> listaCantidad = new List<int>();
  List<double> listaPrecios = new List<double>();
  List<double> listaTotalCantidad = new List<double>();
  double precioTotal;

  bool _connected = false;
  BluetoothDevice _device;
  String tips = 'Impresora no conectada';
  String vendedor, cliente;

  @override
  void initState() {
    super.initState();

    vendedor = "Vendedor de prueba";
    cliente = "Cliente de prueba";

    listaProductos.add("Producto 1");
    listaProductos.add("Producto 2");
    listaProductos.add("Producto 3");
    listaProductos.add("Producto 4");
    listaProductos.add("Producto 5");
    listaProductos.add("Producto 6");
    listaProductos.add("Producto 7");
    listaProductos.add("Producto 8");

    listaCantidad.add(2);
    listaCantidad.add(5);
    listaCantidad.add(1);
    listaCantidad.add(10);
    listaCantidad.add(2);
    listaCantidad.add(3);
    listaCantidad.add(2);
    listaCantidad.add(6);

    listaPrecios.add(20.45);
    listaPrecios.add(5);
    listaPrecios.add(15);
    listaPrecios.add(100.50);
    listaPrecios.add(10);
    listaPrecios.add(5);
    listaPrecios.add(2.50);
    listaPrecios.add(8);

    listaTotalCantidad.add(40.9);
    listaTotalCantidad.add(25);
    listaTotalCantidad.add(15);
    listaTotalCantidad.add(1005);
    listaTotalCantidad.add(20);
    listaTotalCantidad.add(15);
    listaTotalCantidad.add(5);
    listaTotalCantidad.add(48);

    precioTotal = 1173.9;

    WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initBluetooth() async {
    bluetoothPrint.startScan(timeout: Duration(seconds: 4));

    bool isConnected = await bluetoothPrint.isConnected;

    bluetoothPrint.state.listen((state) {
      print('cur device status: $state');

      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'Conexión exitosa';
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'Desconexión exitosa';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if (isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: RefreshIndicator(
          onRefresh: () =>
              bluetoothPrint.startScan(timeout: Duration(seconds: 4)),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      child: Text(tips),
                    ),
                  ],
                ),
                Divider(),
                StreamBuilder<List<BluetoothDevice>>(
                  stream: bluetoothPrint.scanResults,
                  initialData: [],
                  builder: (c, snapshot) => Column(
                    children: snapshot.data
                        .map((d) => ListTile(
                              title: Text(d.name ?? ''),
                              subtitle: Text(d.address),
                              onTap: () async {
                                setState(() {
                                  _device = d;
                                });
                              },
                              trailing: _device != null &&
                                      _device.address == d.address
                                  ? Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    )
                                  : null,
                            ))
                        .toList(),
                  ),
                ),
                Divider(),
                Container(
                  padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                  child: Column(
                    children: <Widget>[
                      OutlineButton(
                        child: Text('Conectar impresora'),
                        onPressed: _connected
                            ? null
                            : () async {
                                if (_device != null &&
                                    _device.address != null) {
                                  await bluetoothPrint.connect(_device);
                                } else {
                                  setState(() {
                                    tips = 'Favor de seleccionar una impresora';
                                  });
                                }
                              },
                      ),
                      SizedBox(width: 10.0),
                      OutlineButton(
                        child: Text('Desconectar impresora'),
                        onPressed: _connected
                            ? () async {
                                await bluetoothPrint.disconnect();
                              }
                            : null,
                      ),
                      OutlineButton(
                        child: Text('Imprimir ticket'),
                        onPressed: _connected
                            ? () async {
                                Map<String, dynamic> config = Map();
                                List<LineText> list = List();
                                ByteData data = await rootBundle
                                    .load("img/botanaxLogo.png");
                                List<int> imageBytes = data.buffer.asUint8List(
                                    data.offsetInBytes, data.lengthInBytes);
                                String base64Image = base64Encode(imageBytes);
                                list.add(LineText(
                                    type: LineText.TYPE_IMAGE,
                                    content: base64Image,
                                    align: LineText.ALIGN_LEFT,
                                    linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'Botanax del Puerto',
                                    size: 10,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'RFC: 454613545342154',
                                    size: 10,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'Ciudad Lázaron Cárdenas',
                                    size: 10,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'Col. Comunal Morelos',
                                    size: 10,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: vendedor,
                                    size: 10,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: cliente,
                                    size: 10,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'Producto:',
                                    size: 10,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: listaProductos
                                        .toString()
                                        .replaceAll("[", " ")
                                        .replaceAll("]", ""),
                                    weight: 1,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'Cantidad:',
                                    size: 10,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: listaCantidad
                                        .toString()
                                        .replaceAll("[", " ")
                                        .replaceAll("]", ""),
                                    weight: 1,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'Precio unitario:',
                                    size: 10,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: listaPrecios
                                        .toString()
                                        .replaceAll("[", " ")
                                        .replaceAll("]", ""),
                                    weight: 1,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'Precio total x cantidad:',
                                    size: 10,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: listaTotalCantidad
                                        .toString()
                                        .replaceAll("[", " ")
                                        .replaceAll("]", ""),
                                    weight: 1,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: "Precio total: $precioTotal",
                                    size: 10,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));

                                await bluetoothPrint.printReceipt(config, list);
                              }
                            : null,
                      ),
                      Container(
                        height: 350.0,
                        child: ListView(
                          //padding: const EdgeInsets.all(20.0),
                          children: <Widget>[
                            SizedBox(
                                height: 320,
                                child: ListView(children: <Widget>[
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: Column(
                                        children: <Widget>[
                                          Image.asset("img/botanaxLogo.png"),
                                          Text("Botanax del Puerto"),
                                          Text("RFC: 454613545342154"),
                                          Text("Ciudad Lázaron Cárdenas"),
                                          Text("Col. Comunal Morelos"),
                                          Text(vendedor),
                                          Text(cliente),
                                          Text(""),
                                          Text("Producto: " +
                                              listaProductos
                                                  .toString()
                                                  .replaceAll("[", " ")
                                                  .replaceAll("]", "")),
                                          Text(""),
                                          Text("Cantidad: " +
                                              listaCantidad
                                                  .toString()
                                                  .replaceAll("[", " ")
                                                  .replaceAll("]", "")),
                                          Text(""),
                                          Text("Precio unitario: " +
                                              listaPrecios
                                                  .toString()
                                                  .replaceAll("[", " ")
                                                  .replaceAll("]", "")),
                                          Text(""),
                                          Text("Precio total x cantidad: " +
                                              listaTotalCantidad
                                                  .toString()
                                                  .replaceAll("[", " ")
                                                  .replaceAll("]", "")),
                                          Text(""),
                                          Text(""),
                                          Text("Total a pagar: " +
                                              precioTotal.toString()),
                                          Text(""),
                                          Text("Firma: "),
                                        ],
                                      ))
                                ])),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        floatingActionButton: StreamBuilder<bool>(
          stream: bluetoothPrint.isScanning,
          initialData: false,
          builder: (c, snapshot) {
            if (snapshot.data) {
              return FloatingActionButton(
                child: Icon(Icons.stop),
                onPressed: () => bluetoothPrint.stopScan(),
                backgroundColor: Colors.red,
              );
            } else {
              return FloatingActionButton(
                  child: Icon(Icons.search),
                  onPressed: () =>
                      bluetoothPrint.startScan(timeout: Duration(seconds: 4)));
            }
          },
        ),
      ),
    );
  }
}
