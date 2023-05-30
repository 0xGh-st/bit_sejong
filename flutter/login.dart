import 'package:flutter/material.dart';
import 'main.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String password = ''; //비밀번호
  Socket? _socket;  //소켓
  String _response = ''; //연결시 서버로부터 받은 응답
  var broadcastStream;
  dynamic listener;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField( //텍스트 입력 부분
              onChanged: (value) {
                setState(() {
                  password = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async{
                try {
                  //소켓 연결
                  _socket = await Socket.connect('your IP', 1234);//your ip, your port
                  //입력한 비밀번호로 시간값과 함께 hmac값을 구해 전송
                  _socket!.write(get_hmac(password));
                  //listen를 다른곳에서도 사용하기 위해 broadcast 설정
                  broadcastStream = _socket!.asBroadcastStream(
                    onCancel: (controller) {
                      print('Stream paused');
                      controller.pause();
                    },
                    onListen: (controller) async {
                      if (controller.isPaused) {
                        print('Stream resumed');
                        controller.resume();
                      }
                    },
                  );
                  //listen 내부에 로직을 구현해 데이터를 못받아오는 경우를 해결
                  listener = broadcastStream.listen((data) {
                    _response = utf8.decode(data);
                    //0이나 1이면 인증 성공, 이 때 0이면 매매 x, 1이면 매매가 진행 중
                    if (_response == '1' || _response == '0') {
                      // Password is correct, perform login actions here
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Login Successful'),
                            content: Text('You have successfully logged in.'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                                      builder: (context) =>
                                          MainAppStateless(_socket, _response, broadcastStream, listener)), (route)=>false);
                                }, // 로그인 성공하고 알림위젯 뜨는것에서 OK 클릭까지 하면 메인 앱 화면을 추가함
                              ),
                            ],
                          );
                        },
                      );
                    } else{ // -1이면 인증 실패
                      // Password is incorrect, show an error message
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Login Failed'),
                            content: Text('Incorrect password. Please try again.'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  });
                }
                catch (error){ //예외처리, ex) 서버가 꺼져 있을 경우.
                  print(error);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Login Failed'),
                        content: Text('Connection Error'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text('Login'), //버튼 텍스트
            ),
          ],
        ),
      ),
    );
  }

  //listen 취소
  @override
  void dispose(){
    //listen pause
    listener.cancel();
    super.dispose();
  }

  // 10초단위로 key에 대한 hmac값 생성
  String get_hmac(String key){
    DateTime dt = DateTime.now();
    //10초 단위로 유효함, 끝 세자리가 millisecond이므로 1000으로 나눠 제거
    int value = (dt.millisecondsSinceEpoch/1000).toInt() - (dt.second%10);
    // 키를 바이트로 변환합니다.
    List<int> keyBytes = utf8.encode(key);
    // 데이터를 바이트로 변환합니다.
    List<int> dataBytes = utf8.encode(value.toString());
    // HMAC을 생성합니다.
    Hmac hmac = Hmac(sha256, keyBytes);
    // HMAC 해시를 계산합니다.
    Digest digest = hmac.convert(dataBytes);
    // 해시 값을 출력합니다.
    return digest.toString();
  }
}
