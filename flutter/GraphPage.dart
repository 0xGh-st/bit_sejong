import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'dart:convert';
import 'dart:io';

class GraphPage extends StatefulWidget {
  dynamic socket;
  String flag = '';
  var broadcastStream;
  dynamic listener;

  GraphPage(dynamic pSocket, pFlag, pBroadcastStream, pListener){
    socket = pSocket;
    flag = pFlag;
    broadcastStream = pBroadcastStream;
    listener = pListener;
  }

  @override
  _GraphPage createState() => _GraphPage();
}

class _GraphPage extends State<GraphPage> {
  List<charts.Series<BarChartModel, String>> _data = [];
  //수익률
  double _ror = 0.0;
  //수익금
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _data = [
      charts.Series<BarChartModel, String>(
        id: 'Auto Trade',
        domainFn: (BarChartModel data, _) => data.label,
        measureFn: (BarChartModel data, _) => data.value,
        // 그래프 색상 설정 함수
        colorFn: (BarChartModel data, _) {
          if (data.label == '만원투자') {
            // '원금' 데이터는 파란색으로 표시
            return charts.ColorUtil.fromDartColor(Colors.green);
          } else {
            return _ror >= 0
                ? charts.ColorUtil.fromDartColor(Colors.blue) // 수익이 0 이상인 경우 파란색으로 표시
                : charts.ColorUtil.fromDartColor(Colors.red); // 음수인 경우 빨간색으로 표시
          }
        },
        data: [
          BarChartModel(label: '만원투자', value: 0),
          BarChartModel(label: '빛세종 수익', value: 0),
        ],
        labelAccessorFn: (BarChartModel data, _) => '${data.value.toStringAsFixed(2)}',
        // labelAccessorFn은 그래프에서 각 막대의 값 레이블을 표시하기 위한 함수
        // data.value를 가져와 소수점 2자리까지 문자열로 변환한 값을 반환
      ),
    ];
    updateChart();
  }

  void updateChart() {
    //widget.listener.resume();
    try {
      widget.broadcastStream.listen((data) {
        sleep(const Duration(seconds: 1));
        _ror = double.parse(utf8.decode(data));
        _total = 10000.0 * (_ror / 100.0 + 1.0);
        setState(() {
          _data[0].data.clear();
          _data[0].data.add(BarChartModel(label: '만원투자', value: 10000));
          _data[0].data.add(BarChartModel(label: '빛세종 수익', value: _total));
        });
      });
    }
    catch(error){
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bit Chart'),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: charts.BarChart(
                _data,
                animate: true,
                domainAxis: charts.OrdinalAxisSpec(
                  renderSpec: charts.SmallTickRendererSpec(
                    labelRotation: 30,
                  ),
                ),
                primaryMeasureAxis: charts.NumericAxisSpec(
                  renderSpec: charts.GridlineRendererSpec(
                    labelStyle: charts.TextStyleSpec(
                      fontSize: 12,
                    ),
                    lineStyle: charts.LineStyleSpec(
                      thickness: 1,
                    ),
                  ),
                  tickProviderSpec: charts.BasicNumericTickProviderSpec(
                    desiredTickCount: 21,
                  ),
                  tickFormatterSpec: charts.BasicNumericTickFormatterSpec(
                        (num? value) => value != null ? value.toStringAsFixed(2) : '',
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              '수익률 : ${_ror.toStringAsFixed(2)+'%'}',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.0),
            Text(
              'Total : ${_total.toStringAsFixed(2)+'￦'}', // 총액 표시
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class BarChartModel {
  final String label;
  final double value;

  BarChartModel({required this.label, required this.value});
}

