//
//  UdpSocketManager.m
//  ProtoBufDemoTest
//
//  Created by Leejun on 2017/8/30.
//  Copyright © 2017年 Leejun. All rights reserved.
//

#import "UdpSocketManager.h"
#import "GCDAsyncUdpSocket.h"
#import "AppDelegate.h"
#import "GCDAsyncSocket.h"

#define UDP_SERVER_PORT 1024
#define TCP_SERVER_HOST @"172.16.3.79"
#define TCP_SERVER_PORT 11293

#define tcp_Timeout  -1

static NSInteger kAutoReconnectCount = 0;
static NSInteger kAutoReconnectMaxCount = 5;

@interface UdpSocketManager ()
<
GCDAsyncUdpSocketDelegate,
GCDAsyncSocketDelegate
>
{
    NSString *_udpReceiveIp;
    uint16_t _udpReceivePort;
    
    NSMutableDictionary *_onSmobaServiceBlockMap;
    
}

@property (nonatomic, strong) GCDAsyncUdpSocket *udpServerSoket;//udp对象

@property (nonatomic, strong) GCDAsyncSocket *tcpClientSocket;//tcp对象

@property (nonatomic, strong) GCDAsyncSocket *tcpServerSocket;

@end

@implementation UdpSocketManager

+ (instancetype)sharedInstance{
    static UdpSocketManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id )init
{
    self = [super init];
    if (self) {
        
        _onSmobaServiceBlockMap = [[NSMutableDictionary alloc] init];
        
        [self createUdpSocket];
        [self createTcpSocket];
    }
    return self;
}

- (void)logout{
    
    [_udpServerSoket close];
    _udpServerSoket = nil;
}

- (void)addOnSmobaServiceBlock:(onSmobaServiceBlock)block cmd:(WJCMD)cmd{
    [_onSmobaServiceBlockMap setObject:[block copy] forKey:[NSNumber numberWithInt:cmd]];
}

- (void)removeOnSmobaServiceBlockForCmd:(WJCMD)cmd{
    [_onSmobaServiceBlockMap removeObjectForKey:[NSNumber numberWithInt:cmd]];
}
- (onSmobaServiceBlock)getOnSmobaServiceBlockByCmd:(WJCMD)cmd{
    return [_onSmobaServiceBlockMap objectForKey:[NSNumber numberWithInt:cmd]];
}

#pragma mark -
#pragma mark - Getters and Setters

- (void)setAccountDic:(NSDictionary *)accountDic{
    _accountDic = accountDic;
}

#pragma mark -
#pragma mark - Methods

-(void)sendBackToHost:(NSString *)ip port:(uint16_t)port withMessage:(GPBMessage *)smobaMessage{
    
    if (!smobaMessage) {
        return;
    }

    NSData *sendData = nil;
    if ([smobaMessage isKindOfClass:[WJAccountInfoReq class]]) {
        
        //给模块账号回应
        sendData = [[SmobaDataManager sharedInstance] sendAccountInfoReqMessage:_accountDic];
        
    }
//    else if ([smobaMessage isKindOfClass:[WJChooseGameZoneReq class]]){
//        
//        sendData = [[SmobaDataManager sharedInstance] sendChooseGameZoneReqMessage];
//        
//    }
    else if ([smobaMessage isKindOfClass:[WJProgressResportReq class]]){
        
        WJProgressResportReq *progressResportReq = (WJProgressResportReq *)smobaMessage;
        
        [self sendTcpMessage:progressResportReq cmd:WJCMD_CmdUnknow];
        return;
        
    }else if ([smobaMessage isKindOfClass:[WJCreateRoomReq class]]){
        WJCreateRoomReq *createRoomReq = (WJCreateRoomReq *)smobaMessage;
        //创建房间
        sendData = [[SmobaDataManager sharedInstance] sendCreateRoomReqMessage:createRoomReq.roomType];
        
    }else if ([smobaMessage isKindOfClass:[WJCreateRoomResp class]]){
        
        [self sendTcpMessage:smobaMessage cmd:WJCMD_CmdUnknow];
        return;
    }else if ([smobaMessage isKindOfClass:[WJJoinRoomReq class]]){
        
        sendData = [[SmobaDataManager sharedInstance] sendJoinRoomReqMessage:smobaMessage];
        
    }else if ([smobaMessage isKindOfClass:[WJJoinRoomResp class]]){
        
        [self sendTcpMessage:smobaMessage cmd:WJCMD_CmdUnknow];
        return;
        
    }else if ([smobaMessage isKindOfClass:[WJBattleStartReq class]]){
        
//        sendData = [[SmobaDataManager sharedInstance] sendPublicReqMessage:WJCMD_CmdBattleStartReq];
        
    }else if ([smobaMessage isKindOfClass:[WJBattleStartResp class]]){
        
        [self sendTcpMessage:smobaMessage cmd:WJCMD_CmdUnknow];
        return;
        
    }else if ([smobaMessage isKindOfClass:[WJBattleFinishReq class]]){
        
        [self sendTcpMessage:smobaMessage cmd:WJCMD_CmdUnknow];
        
//        sendData = [[SmobaDataManager sharedInstance] sendPublicReqMessage:WJCMD_CmdBattleFinishResp];
        
    } else{
        
        return;
    }
    
    NSLog(@"SEND DATA WITH UDP>>>>>>>>>>>>\n");
    [_udpServerSoket sendData:sendData toHost:ip port:port withTimeout:60 tag:200];
    
}

- (void)sendTcpMessage:(GPBMessage *)smobaMessage cmd:(WJCMD)cmd{
    
    //收到服务器回应
    NSData *sendData = nil;
    if ([smobaMessage isKindOfClass:[WJProgressResportReq class]]) {
//        sendData = GenerateReqSmobaData(WJCMD_CmdProgressReportReq, WJRetCode_RcOk, smobaMessage);
    }else if ([smobaMessage isKindOfClass:[WJCreateRoomReq class]]){
        
        [self sendBackToHost:_udpReceiveIp port:_udpReceivePort withMessage:smobaMessage];
        return;
    }else if ([smobaMessage isKindOfClass:[WJCreateRoomResp class]]){
        
//        sendData = GenerateReqSmobaData(WJCMD_CmdCreateRoomResp, WJRetCode_RcOk, smobaMessage);
        
    }else if ([smobaMessage isKindOfClass:[WJJoinRoomReq class]]){
        [self sendBackToHost:_udpReceiveIp port:_udpReceivePort withMessage:smobaMessage];
        return;
    }else if ([smobaMessage isKindOfClass:[WJJoinRoomResp class]]){
//        sendData = GenerateReqSmobaData(WJCMD_CmdJoinRoomResp, WJRetCode_RcOk, smobaMessage);
    }else if ([smobaMessage isKindOfClass:[WJBattleStartReq class]]){
        [self sendBackToHost:_udpReceiveIp port:_udpReceivePort withMessage:smobaMessage];
        return;
    }else if ([smobaMessage isKindOfClass:[WJBattleStartResp class]]){
        
//        sendData = GenerateReqSmobaData(WJCMD_CmdBattleStartResp, WJRetCode_RcOk, smobaMessage);
        
    }else if ([smobaMessage isKindOfClass:[WJBattleFinishReq class]]){
        //游戏结果
//        sendData = GenerateReqSmobaData(WJCMD_CmdBattleFinishReq, WJRetCode_RcOk, smobaMessage);
        
    }else if ([smobaMessage isKindOfClass:[WJGetGameStatusResp class]]){
        //游戏状态 回应
        if (self.delegate && [self.delegate respondsToSelector:@selector(recGameStatus)]) {
            [self.delegate recGameStatus];
        }
//        onSmobaServiceBlock block = [self getOnSmobaServiceBlockByCmd:WJCMD_CmdAppSvrGetGameStatusResp];
//        if (block) {
//            [self removeOnSmobaServiceBlockForCmd:WJCMD_CmdAppSvrGetGameStatusResp];
//            block(smobaMessage);
//        }
        return;
    }else if ([smobaMessage isKindOfClass:[WJApplyAccountResp class]]){
        //请求账号 回应逻辑处理
        onSmobaServiceBlock block = [self getOnSmobaServiceBlockByCmd:WJCMD_CmdAppSvrAccountApplyResp];
        if (block) {
            [self removeOnSmobaServiceBlockForCmd:WJCMD_CmdAppSvrAccountApplyResp];
            block(smobaMessage);
        }
        return;
    }else if ([smobaMessage isKindOfClass:[WJReportLoginResultReq class]]){
        sendData = GenerateReqSmobaData(WJCMD_CmdAppSvrReportLoginResultReq, WJRetCode_RcOk, smobaMessage);
    }else if ([smobaMessage isKindOfClass:[WJGetBattleResultResp class]]){
        //服务器的游戏结果
        if (self.delegate && [self.delegate respondsToSelector:@selector(recBattleResult)]) {
            [self.delegate recBattleResult];
        }
    }
    
    //请求账号
    switch (cmd) {
            
        case WJCMD_CmdAppSvrGetGameStatusReq:
            sendData = [[SmobaDataManager sharedInstance] sendPublicReqMessage:WJCMD_CmdAppSvrGetGameStatusReq];
            break;
            
        case WJCMD_CmdAppSvrAccountApplyReq:
            sendData = [[SmobaDataManager sharedInstance] sendPublicReqMessage:WJCMD_CmdAppSvrAccountApplyReq];
            break;
            
        case WJCMD_CmdAppSvrGetBattleResultReq:
            sendData = [[SmobaDataManager sharedInstance] sendPublicReqMessage:WJCMD_CmdAppSvrGetBattleResultReq];
            break;
            
        case WJCMD_CmdAppGmReleaseAccountReq:
            sendData = [[SmobaDataManager sharedInstance] sendPublicReqMessage:WJCMD_CmdAppGmReleaseAccountReq];
            
            break;
            
        default:
            break;
    }
    
    
    if (!sendData) {
        return;
    }

    NSLog(@"SEND DATA WITH TCP>>>>>>>>>>>>\n");
    [self.tcpClientSocket writeData:sendData withTimeout:-1 tag:100];
}

- (void)requestBattleResultReq{
    
    [self sendTcpMessage:nil cmd:WJCMD_CmdAppSvrGetBattleResultReq];
}

- (void)requestReportLoginResultReq:(uint32_t)loginSucc{
    
    WJReportLoginResultReq *reqMsg = [WJReportLoginResultReq new];
    reqMsg.account = [SmobaDataManager sharedInstance].applyAccountResp.account;
    reqMsg.loginSucc = loginSucc;
    [self sendTcpMessage:reqMsg cmd:WJCMD_CmdUnknow];
}


- (GPBMessage *)receiveData:(NSData *)receiveMsg{
    
    return [[SmobaDataManager sharedInstance] parseSmobaData:receiveMsg];
}

//- (void)showBattleResultsViewController{
//    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
//    [appDelegate gotoGameResultVc];
//}


#pragma mark - 
#pragma mark - UDP
- (void)createUdpSocket{
    
    if (_udpServerSoket) {
        return;
    }
    
    dispatch_queue_t dQueue = dispatch_queue_create("My UDP Socket Queue", DISPATCH_QUEUE_CONCURRENT);
    //dispatch_get_main_queue()
    _udpServerSoket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dQueue];
    
    NSError *error = nil;
    
    bool b = [_udpServerSoket bindToPort:UDP_SERVER_PORT error:&error];
    
    NSLog(@"UDPServerSoket bindToPort --%o",b);
    
    [_udpServerSoket beginReceiving:&error];
    
    [_udpServerSoket enableBroadcast:YES error:&error];
    
}

#pragma mark -
#pragma mark - GCDAsyncUdpSocketDelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext{
    
    NSString *ip = [GCDAsyncUdpSocket hostFromAddress:address];
    uint16_t port = [GCDAsyncUdpSocket portFromAddress:address];
    _udpReceiveIp = ip;
    _udpReceivePort = port;
    
    if ([ip isEqualToString:@"127.0.0.1"] && port == UDP_SERVER_PORT) {
        
        return;
    }
    
//    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"来自于 UDP [%@:%u] 消息内容-----%p",ip, port,data);
    
    
    
    //解析收到的信息
    GPBMessage *smobaMessage = [self receiveData:data];
    
    [self sendBackToHost:ip port:port withMessage:smobaMessage];
    
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    NSLog(@"yeah! udp Socket send data succeed with tag:%lu\n\n\n\n",tag);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
    NSLog(@"error! udpSocket sendData failed tag:%lu error:%@",tag,[error localizedDescription]);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error{
    
    NSLog(@"udp didNotConnect error:%@",error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address{
    
}


#pragma mark - 
#pragma mark - TCP
- (void)createTcpSocket{
    
    if (self.tcpClientSocket) {
        return;
    }
    
    self.tcpClientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
//    self.tcpClientSocket.autoDisconnectOnClosedReadStream = NO;
    
    NSError *error = nil;
    [self.tcpClientSocket connectToHost:TCP_SERVER_HOST onPort:TCP_SERVER_PORT withTimeout:tcp_Timeout error:&error];
    NSLog(@"tcp connectToHost error :%@",[error description]);
    
}

//tcp重连 2s 4s 6s
- (void)autoReconnectTcpServer{
    
    kAutoReconnectCount ++;
    if (kAutoReconnectCount > kAutoReconnectMaxCount) {
        return;
    }
    
    NSLog(@"kAutoReconnectCount = %ld",kAutoReconnectCount);
    __weak __typeof(&*self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kAutoReconnectCount*sqrt(2) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf reconnectTcp];
    });
}

- (void)reconnectTcp{
    
    NSError *error = nil;
    [self.tcpClientSocket connectToHost:TCP_SERVER_HOST onPort:TCP_SERVER_PORT error:&error];
}

#pragma mark -
#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"tcp didConnectToHost [%@:%u]",host,port);
    kAutoReconnectCount = 0;
    //为收到消息做准备
    [sock readDataWithTimeout:tcp_Timeout tag:0];
    
    //每次连上server请求游戏状态
    [[UdpSocketManager sharedInstance] sendTcpMessage:nil cmd:WJCMD_CmdAppSvrGetGameStatusReq];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    //想要收到消息之前 先调用次方法
    [sock readDataWithTimeout:tcp_Timeout tag:0];
    
//    NSString *receive = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Read TCP Server Data: %p",data);
    
    GPBMessage *smobaMessage = [self receiveData:data];
    
    [self sendTcpMessage:smobaMessage cmd:WJCMD_CmdUnknow];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"tcp 连接断开了 error:%@",err);
    [self autoReconnectTcpServer];
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock{
    NSLog(@"%s",__func__);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"Yeah! TCP Socket send data succeed with tag:%lu\n\n\n\n",tag);
}

@end
