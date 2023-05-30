import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'TradePage.dart'; //1번째 페이지 부분
import 'GraphPage.dart'; // 2번째 페이지 부분
import 'login.dart';

void main() {
  runApp(LoginApp()); //시작하면 로그인 화면에서 시작하고 로그인 성공하면 메인으로 넘어감
}

class MainAppStateless extends StatelessWidget {
  Socket? socket;
  String flag = '';
  var broadcastStream;
  dynamic listener;

  MainAppStateless(pSocket, pFlag, pBroadcastStream, pListener){
    socket = pSocket;
    flag = pFlag;
    broadcastStream = pBroadcastStream;
    listener = pListener;
    // 비밀번호를 정확히 입력해도 매매가 진행중이면, 실시간으로 수익률을 보내 로그인 성공 후
    // 확인버튼을 늦게 누르면 login쪽 listen에서 수익률을 계속 받아 비정상 작동함.
    //따라서 mainapp이 실행될 때 ok사인을 보냈을 때 수익률을 보내도록 함
    socket!.write("ok");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: (){ //# onWillpop : 뒤로가기 클릭할 때 발생하는 이벤트 부분
      AlertDialog dialog = AlertDialog(
        title: Text('종료'),
        content: Text('애플리케이션을 종료하시겠습니까?', style: TextStyle(fontSize: 17)),
        actions: [
          ElevatedButton(onPressed: (){
            socket!.close();
            SystemNavigator.pop();
          }, child: Text('YES')),

          ElevatedButton(onPressed: (){
            Navigator.of(context).pop(); //????????????????????
          }, child: Text('NO'))
        ],
      );
      showDialog(context: context, builder: (BuildContext context) => dialog);
      return Future.value(true);
    }, child: MaterialApp( // ### 앱 화면 부분
      title: 'BitSejong',
      home: MainApp(socket, flag, broadcastStream, listener), theme: ThemeData(primarySwatch: Colors.indigo),
    ));
  }
}

class MainApp extends StatefulWidget {
  Socket? socket;
  String flag = '';
  var broadcastStream;
  dynamic listener;

  MainApp(pSocket, pFlag, pBroadcastStream, pListener){
    socket = pSocket;
    flag = pFlag;
    broadcastStream = pBroadcastStream;
    listener = pListener;
  }

  @override
  State<StatefulWidget> createState() {
    return _MainApp();
  }
}

class _MainApp extends State<MainApp> with SingleTickerProviderStateMixin {
  TabController? controller;
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold( //로그인 한 후 기본 화면 (탭바로 두개 화면 전환)
      body: IndexedStack(
        index: _currentIndex,
        children: <Widget>[TradePage(widget.socket, widget.flag, widget.listener), //탭바 요소들 2개
         GraphPage(widget.socket, widget.flag, widget.broadcastStream, widget.listener)],
        //controller: controller,
      ),
      bottomNavigationBar: Container(
        child: TabBar(
          onTap: onTabTapped,
          tabs: [
            Container(height: 90, child : Column(
                children: <Widget>[Tab(icon: Image.asset("images/currency-exchange.png"),height: 50),
                  Text("자동매매", style: TextStyle(fontSize: 20))])),
            Container(height: 90, child : Column(
                children: <Widget>[Tab(icon: Image.asset("images/stock-market.png"), height: 50),
                  Text("그래프", style: TextStyle(fontSize: 20),)])),
          ], controller: controller,
        ), color: Colors.indigo,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}