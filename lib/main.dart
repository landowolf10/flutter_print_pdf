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
  double precioTotal;

  bool _connected = false;
  BluetoothDevice _device;
  String tips = 'no device connect';
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

    listaCantidad.add(2);
    listaCantidad.add(5);
    listaCantidad.add(1);
    listaCantidad.add(10);

    listaPrecios.add(20.45);
    listaPrecios.add(5);
    listaPrecios.add(15);
    listaPrecios.add(100.50);

    precioTotal = 140.95;

    print(listaProductos);

    WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initBluetooth() async {
    bluetoothPrint.startScan(timeout: Duration(seconds: 4));

    bool isConnected=await bluetoothPrint.isConnected;

    bluetoothPrint.state.listen((state) {
      print('cur device status: $state');

      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if(isConnected) {
      setState(() {
        _connected=true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('BluetoothPrint example app'),
          ),
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
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        child: Text(tips),
                      ),
                    ],
                  ),
                  Divider(),
                  StreamBuilder<List<BluetoothDevice>>(
                    stream: bluetoothPrint.scanResults,
                    initialData: [],
                    builder: (c, snapshot) => Column(
                      children: snapshot.data.map((d) => ListTile(
                        title: Text(d.name??''),
                        subtitle: Text(d.address),
                        onTap: () async {
                          setState(() {
                            _device = d;
                          });
                        },
                        trailing: _device!=null && _device.address == d.address?Icon(
                          Icons.check,
                          color: Colors.green,
                        ):null,
                      )).toList(),
                    ),
                  ),
                  Divider(),
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            OutlineButton(
                              child: Text('connect'),
                              onPressed:  _connected?null:() async {
                                if(_device!=null && _device.address !=null){
                                  await bluetoothPrint.connect(_device);
                                }else{
                                  setState(() {
                                    tips = 'please select device';
                                  });
                                  print('please select device');
                                }
                              },
                            ),
                            SizedBox(width: 10.0),
                            OutlineButton(
                              child: Text('disconnect'),
                              onPressed:  _connected?() async {
                                await bluetoothPrint.disconnect();
                              }:null,
                            ),
                          ],
                        ),
                        OutlineButton(
                          child: Text('Imprimir ticket'),
                          onPressed:  _connected?() async {
                            Map<String, dynamic> config = Map();
                            List<LineText> list = List();
                            ByteData data = await rootBundle.load("img/botanaxLogo.png");
                            List<int> imageBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
                            String base64Image = base64Encode(imageBytes);
                            list.add(LineText(type: LineText.TYPE_IMAGE, content: base64Image, align: LineText.ALIGN_LEFT, linefeed: 1));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: 'Botanax del Puerto', size:10, align: LineText.ALIGN_CENTER, linefeed: 1));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: 'RFC: 454613545342154', size:10, align: LineText.ALIGN_CENTER, linefeed: 1));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: 'Ciudad Lázaron Cárdenas', size:10, align: LineText.ALIGN_CENTER, linefeed: 1));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: 'Col. Comunal Morelos', size:10, align: LineText.ALIGN_CENTER, linefeed: 1));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: vendedor, size:10, align: LineText.ALIGN_CENTER, linefeed: 1));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: cliente, size:10, align: LineText.ALIGN_CENTER, linefeed: 1));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: 'Producto:', size:10, align: LineText.ALIGN_LEFT, linefeed: 1));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: listaProductos.toString()
                                                                                                .replaceAll(",", "\n").
                                                                                                replaceAll("[", " ").
                                                                                                replaceAll("]", ""),
                                                                                                weight: 1, align: LineText.ALIGN_LEFT, linefeed: 1));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: 'Cant:', size:10, align: LineText.ALIGN_CENTER));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: listaCantidad.toString()
                                                                                                .replaceAll(",", "\n").
                                                                                                replaceAll("[", " ").
                                                                                                replaceAll("]", ""),
                                                                                                weight: 1, align: LineText.ALIGN_CENTER, linefeed: 1));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: 'P/u:', size:10, align: LineText.ALIGN_RIGHT));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: listaPrecios.toString()
                                                                                                .replaceAll(",", "\n").
                                                                                                replaceAll("[", " ").
                                                                                                replaceAll("]", ""),
                                                                                                weight: 1, align: LineText.ALIGN_RIGHT, linefeed: 1));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: 'P/t:', size:10, align: LineText.ALIGN_CENTER));
                            list.add(LineText(type: LineText.TYPE_TEXT, content: "Precio total: $precioTotal", size:10, align: LineText.ALIGN_CENTER, linefeed: 1));

                            await bluetoothPrint.printReceipt(config, list);
                          }:null,
                        ),
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
                  onPressed: () => bluetoothPrint.startScan(timeout: Duration(seconds: 4)));
            }
          },
        ),
      ),
    );
  }
}