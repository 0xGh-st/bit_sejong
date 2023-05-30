import 'package:flutter/material.dart';
import 'dart:io';

class TradePage extends StatefulWidget {
  int flag = 0; // 자동매매가 켜져있는지 아닌지 정하는 값
  dynamic socket;
  dynamic listener;

  TradePage(dynamic pSocket, String pFlag, dynamic pListener){
    socket = pSocket;
    flag = int.parse(pFlag);
    listener = pListener;
  }

  @override
  State<StatefulWidget> createState() {
    return _TradePage();
  }
}

class _TradePage extends State<TradePage> {
  List<String> iconlist = ["images/power-off.png", "images/power-on.png"]; //전원 아이콘 2개
  List<String> textstrL = ['OFF', 'ON'];
  int flag = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('BitSejong'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Padding(padding: EdgeInsets.all(100)),
              IconButton(onPressed: (){
                setState(() {
                  try {
                    if (flag == 0) {
                      _sendData("1"); //stateful 부분 값을 사용
                      flag = 1;
                    }
                    else {
                      _sendData("0");
                      flag = 0;
                    }
                  }
                  catch(error){
                    print(error);
                  }
                });
              }, icon: Image.asset(iconlist[flag]), iconSize: 180,),
              Padding(padding: EdgeInsets.all(27),
                  child: Text(textstrL[flag], style: TextStyle(fontSize: 35))),
            ],
          ),
        )
    );
  }

  void _sendData(String data) {
    try {
      widget.socket.write(data);
    }
    catch(error){
      print(error);
    }
  }

  @override
  void initState() {
    flag = widget.flag;
    super.initState();
  }
}