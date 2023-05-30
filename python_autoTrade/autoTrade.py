#https://github.com/youtube-jocoding/pyupbit-autotrade/blob/main/bitcoinAutoTrade.py
import time
import pyupbit
import datetime
import socket
import threading
import hmac
import select
import hashlib
import datetime as dt
import random

access = "your access key"
secret = "your private key"
global upbit

def get_hmac(key):
    """10초 단위로 키에 대한 hmac 계산"""
    x = dt.datetime.now()
    value = int(x.timestamp()) - (x.second%10)
    # 키와 데이터를 바이트로 변환
    key_bytes = key.encode('utf-8')
    value_bytes = str(value).encode('utf-8')
    # HMAC을 계산
    hmac_hash = hmac.new(key_bytes, value_bytes, hashlib.sha256)
    # 해시 값 반환.
    return hmac_hash.hexdigest()

def get_target_price(ticker, k):
    """변동성 돌파 전략으로 매수 목표가 조회"""
    df = pyupbit.get_ohlcv(ticker, interval="day", count=2)#2일치 데이터  조회
    target_price = df.iloc[0]['close'] + (df.iloc[0]['high'] - df.iloc[0]['low']) * k#close가 결국 다음날 시가
    return target_price

def get_start_time(ticker):
    """시작 시간 조회"""
    df = pyupbit.get_ohlcv(ticker, interval="day", count=1)# ohlcv를 일봉으로 조회하면 시작시간 9시로 설정
    start_time = df.index[0]#첫번째 인덱스 시간값
    return start_time

def get_balance(ticker):
    """잔고 조회"""
    balances = upbit.get_balances()
    for b in balances:
        if b['currency'] == ticker:
            if b['balance'] is not None:
                return float(b['balance'])
            else:
                return 0
    return 0

def get_current_price(ticker):
    """현재가 조회"""
    return pyupbit.get_orderbook(ticker=ticker)["orderbook_units"][0]["ask_price"]

def get_percent(a, b):
    """수익률 계산(둘째자리까지)"""
    return round((b - a) / a * 100, 2)

# 테스트 트레이딩
def test_trade(stop_event):
    # 투자 금액(시작 10,000원)
    money = 10000
    # 기존 비트코인 개수
    preBTC = 0
    # 자동매매로 산  비트코인 개수
    buyBTC = 0
    # 자동매매로 산 비트코인 금액
    buyPrice = 0
    # 매매 flag
    flag = 0
    # 수익률
    percentage = 0
    
    # 수익률
    percentage = 0
    while True:
        print('test trading')
        # buy test
        preBTC = get_balance("BTC")
        upbit.buy_market_order("KRW-BTC", 10000*0.9995)#수수료 0.05
        print('매수금액 : {}'.format(get_current_price('KRW-BTC')))
        buyPrice = get_current_price("KRW-BTC")
        buyBTC = get_balance("BTC") - preBTC
        time.sleep(4)

        # sell test
        upbit.sell_market_order("KRW-BTC", buyBTC*0.9995)
        print('매도금액 : {}'.format(get_current_price('KRW-BTC')))
        testData = float(random.randrange(20000000, 60000000))
        current_price = get_current_price("KRW-BTC")
        percentage = get_percent(testData, current_price)
        print('test 수익률 : {}'.format(percentage))
        if client_socket != 0 and client_recv_sign != 0:
            time.sleep(1)
            client_socket.send(str(round(percentage,2)).encode())
        time.sleep(4)
        if stop_event.is_set():
            return
 
# 변동성 돌파 전략을 사용하는 자동매매 함수
def auto_trade(stop_event):
    #global upbit
    # 투자 금액(시작 10,000원)
    money = 10000
    # 기존 비트코인 개수
    preBTC = 0
    # 자동매매로 산  비트코인 개수
    buyBTC = 0
    # 자동매매로 산 비트코인 금액
    buyPrice = 0
    # 매매 flag
    flag = 0
    # 수익률
    percentage = 0
    print('start')
    while True:
        try:
            now = datetime.datetime.now()
            time.sleep(0.5) # get_start_time이 너무 빨리 받아오면 None을 반환
            start_time = get_start_time("KRW-BTC") #9:00
            end_time = start_time + datetime.timedelta(days=1) #9:00 + 1일 
            #시작시간과 끝나는 시간이 같지 않도록 끝나는 시간에 10초를 빼 8시 59분 50초로 설정 9:00 < 현재 < 8:59
            if start_time < now < end_time - datetime.timedelta(seconds=10):
                # flag가 0이면 매수 진행
                if flag == 0:
                    target_price = get_target_price("KRW-BTC", 0.5)
                    current_price = get_current_price("KRW-BTC")
                    if target_price < current_price:
                        krw = get_balance("KRW")
                        #보유 잔고가 투자금액 money보다 많으면 매수 진행
                        if krw >= money:
                            preBTC = get_balance("BTC")
                            upbit.buy_market_order("KRW-BTC", money*0.9995)#수수료 0.05
                            buyPrice = get_current_price("KRW-BTC")
                            #기존 구매 후 비트코인 보유량 - 기존 비트코인 보유량 = 구매한 비트코인 개수
                            buyBTC = get_balance("BTC") - preBTC
                            flag = 1

            else:
                if buyBTC > 0.00008:#최소 매매 금액
                    # 코인을 팔고 난 잔고 - 팔기 전 잔고 = 내가 판 금액(이 금액으로 money를 갱신해 투자금액 업데이트)
                    pre_balance = get_balance("KRW")
                    upbit.sell_market_order("KRW-BTC", buyBTC*0.9995)
                    money = get_balance("KRW") - pre_balance
                    client_socket.send(str(get_percent(10000.0, money)).encode())
                    buyBTC = 0
                    flag = 0
            # 자동매매 종료
            if stop_event.is_set():
                # 자동매매 종료했을 때, 자동매매로 인해 매수한 비트코인이 있다면 팔기
                if flag == 1 and buyBTC > 0.00008:
                    pre_balance = get_balance("KRW")
                    upbit.sell_market_order("KRW-BTC", buyBTC*0.9995)
                    money = get_balance("KRW") - pre_balance
                    # 자동매매 종료시 최종 매도 후 수익률 전송
                    client_socket.send(str(get_percent(10000.0, money)).encode())
                return
            # 매수했다면 실시간으로 매수금 대비 수익률을 전송
            if flag == 1 and client_socket != 0 and client_recv_sign == 1:
                time.sleep(1)
                percentage = get_percent(buyPrice, get_current_price("KRW-BTC"))
                client_socket.send(str(percentage).encode())
        except Exception as e:
            print(e)
            time.sleep(1)

if __name__ == '__main__':
    # 로그인
    upbit = pyupbit.Upbit(access, secret)

    # 서버 소켓 생성
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # 같은 포트로 바로 실행할 수 있게
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server_socket.bind(("your ip", 1234))#your ip your port
    server_socket.listen(1)
    client_socket = 0
    # client가 recv에 대한 사인을 보내면 수익률을 전송
    client_recv_sign = 0
    #thread 종료 이벤트
    stop_event = threading.Event()
    #thread에 대한 실행 유무 flag
    tFlag = 0

    while True:
        if client_socket == 0:
            # 클라이언트 연결
            print('연결준비')
            client_socket, client_address = server_socket.accept()
            inputs = [client_socket]
            readable, _, _ = select.select(inputs, [], [])

            # 클라이언트가 보낸 값이 get_hmac()과 다르면 연결 종료
            if client_socket.recv(1024).decode() != get_hmac('your password') and client_socket != 0:
                print('비밀번호 에러')
                client_socket.send(b'-1')
                client_socket.close()
                client_socket = 0
        # 클라이언트가 인증에 성공하면
        else:
            print('연결 성공')
            # 인증 성공 시 현재 쓰레드가 돌아가고 있는지 tFlag로 알려줘 flutter 버튼 설정하도록 함
            client_socket.send(str(tFlag).encode())
            # 상대방이 ok 사인을 보내야지만 수익률을 전송
            if(client_socket.recv(32).decode() == 'ok'):
                client_recv_sign = 1
                print('recv 가능 확인')
            inputs = [client_socket]
            readable, _, _ = select.select(inputs, [], [])
            try:
                for sock in readable:
                    while True:
                        data = client_socket.recv(32)
                        # 연결이 끊어졌을 경우 소켓 닫음
                        if not data:
                            sock.close()
                            client_recv_sign = 0
                            inputs.remove(sock)
                        # 클라이언트로 데이터를 받았을 경우
                        print("Received data:", data)
                        received_data = data.decode()
                        # 1이면 쓰레드 실행
                        if received_data == "1" and tFlag == 0:
                            # 클라이언트가 1을 보냈을 때 auto_trade() 함수를 쓰레드로 실행
                            stop_event.clear()  # 종료 신호 초기화
                            trade_thread = threading.Thread(target=auto_trade, args=(stop_event,))
                            #trade_thread = threading.Thread(target=test_trade, args=(stop_event,)) # 테스트 트레이딩 함수
                            trade_thread.start()
                            tFlag = 1
                        # 0이면 쓰레드 종료
                        elif received_data == "0" and tFlag == 1:
                            client_recv_sign = 0
                            # 클라이언트가 0을 보냈을 때 auto_trade() 쓰레드 강제 종료
                            if trade_thread is not None:
                                stop_event.set()  # auto_trade() 쓰레드 종료 신호 전달
                                tFlag = 0
            except Exception as e:
                if client_socket != 0:
                    client_socket.close()
                client_recv_sign = 0
                client_socket = 0
                print(e)


