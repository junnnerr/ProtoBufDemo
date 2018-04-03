//
//  SmobaDataManager.m
//  ProtoBufDemoTest
//
//  Created by Leejun on 2017/8/24.
//  Copyright © 2017年 Leejun. All rights reserved.
//

#import "SmobaDataManager.h"
#import "UdpSocketManager.h"

#define smoba_header_size 20

struct smoba_header {
    uint32_t magic;   // 0xfeed121
    uint32_t seq;     // 0x1
    uint32_t cmd;
    uint32_t code;
    uint32_t length;
};

struct smoba_header header;

@implementation SmobaDataManager

+ (instancetype)sharedInstance{
    static SmobaDataManager *sharedInstance = nil;
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
        
    }
    return self;
}

- (BOOL)hasAccoutLoggedin{
    
    return (_applyAccountResp.account.length > 0 && _applyAccountResp.password.length > 0);
}

- (void)clearAccountInfo{
    
    self.applyAccountResp = nil;
    self.getGameStatusResp.gameStatus = WJGameStatus_GameStatusInit;
    self.battleFinishReq = nil;
    
    NSLog(@"accountInfo been clear.");
}

- (WJGameStatus)currentGameStatus{
    
    return _getGameStatusResp.gameStatus;
}

#pragma mark -
#pragma mark - Request
NSData *GenerateReqSmobaData(WJCMD cmd, WJRetCode code, GPBMessage *message) {
    struct smoba_header header = GetSmoba_header(cmd, code, (uint32_t)[[message data] length]);
    
    NSMutableData *headerData = [NSMutableData dataWithBytes:&header length:sizeof(header)];
    [headerData appendData:[message data]];
    
    NSLog(@"<<<<<<<<<<<<SEND DATA WITH header.cmd:%d  message:%@",cmd,message);
    
    return [headerData copy];
}

struct smoba_header GetSmoba_header(WJCMD cmd, WJRetCode code, uint32_t length) {
    struct smoba_header header;
    header.magic = OSSwapHostToBigInt32(SmobaDataMagic);
    header.seq = OSSwapHostToBigInt32(0x1);
    header.cmd = OSSwapHostToBigInt32(cmd);
    header.code = OSSwapHostToBigInt32(code);
    header.length = OSSwapHostToBigInt32(length);
    return header;
}

- (NSData *)sendCreateRoomReqMessage:(WJRoomType)roomType{
    
    WJCreateRoomReq *createRoomReqMsg = [WJCreateRoomReq new];
    createRoomReqMsg.roomType = roomType;
    
    return nil;
//    NSData *reqData = GenerateReqSmobaData(WJCMD_CmdCreateRoomReq, WJRetCode_RcOk, createRoomReqMsg);
//    return reqData;
}

- (NSData *)sendJoinRoomReqMessage:(GPBMessage *)joinRoomReq{
    
    return nil;
//    NSData *reqData = GenerateReqSmobaData(WJCMD_CmdJoinRoomReq, WJRetCode_RcOk, joinRoomReq);
//    return reqData;
}

- (NSData *)sendAccountInfoReqMessage:(NSDictionary *)dic{
    
    WJAccountInfoResp *reqMsg = [WJAccountInfoResp new];
    WJAccountInfo *accountInfo = [WJAccountInfo new];
    accountInfo.platformType = @"qq_m";
    accountInfo.openid = dic[@"openid"];
    accountInfo.accessToken = dic[@"access_token"];
    accountInfo.payToken = dic[@"pay_token"];
    accountInfo.launchFrom = @"sq_gamecenter";
    accountInfo.account = _applyAccountResp.account;
    reqMsg.accountInfo = accountInfo;
    
    NSData *reqData = GenerateReqSmobaData(WJCMD_CmdAppSmobaAccountInfoResp, WJRetCode_RcOk, reqMsg);
    return reqData;
}

- (NSData *)sendChooseGameZoneReqMessage{
    
    return nil;
//    WJChooseGameZoneResp *reqMsg = [WJChooseGameZoneResp new];
//    WJZoneInfo *zoneInfo = [WJZoneInfo new];
//    zoneInfo.zoneId = self.applyAccountResp.zoneInfo.zoneId;
//    zoneInfo.zoneName = self.applyAccountResp.zoneInfo.zoneName;
//    reqMsg.zoneInfo = zoneInfo;
//    
//    NSData *reqData = GenerateReqSmobaData(WJCMD_CmdChooseGameZoneResp, WJRetCode_RcOk, reqMsg);
//    return reqData;
}

- (NSData *)sendPublicReqMessage:(WJCMD)cmd{

    GPBMessage *reqMsg;
    switch (cmd) {
            
        case WJCMD_CmdAppSvrGetGameStatusReq:
            reqMsg = [WJGetGameStatusReq new];
            break;
            
        case WJCMD_CmdAppSvrAccountApplyReq:
            reqMsg = [WJApplyAccountReq new];
            break;
            
        case WJCMD_CmdAppSvrGetBattleResultReq:
            reqMsg = [WJGetBattleResultReq new];
            break;
            
        case WJCMD_CmdAppGmReleaseAccountReq:
            reqMsg = [WJGMReleaseAccountReq new];
            break;
            
        default:
            break;
    }
    
    NSData *reqData = GenerateReqSmobaData(cmd, WJRetCode_RcOk, reqMsg);
    return reqData;
    
}

#pragma mark -
#pragma mark - TCP

#pragma mark -
#pragma mark - Response
- (GPBMessage *)parseRespSmobaData:(NSData *)responseData{
    
//    Byte *respByte = (Byte*)[responseData bytes];
    if (responseData.length < smoba_header_size) {
        return nil;
    }
    struct smoba_header header;
    NSData *headerData = [responseData subdataWithRange:NSMakeRange(0, smoba_header_size)];
    [headerData getBytes:&header length:sizeof(header)];
    
    header.magic = OSSwapHostToBigInt32(header.magic);
    header.seq = OSSwapHostToBigInt32(header.seq);
    header.cmd = OSSwapHostToBigInt32(header.cmd);
    header.code = OSSwapHostToBigInt32(header.code);
    header.length = OSSwapHostToBigInt32(header.length);
    
    if (header.magic != SmobaDataMagic) {
        NSLog(@"Warming: magic: 0x%x",header.magic);
        return nil;
    }
    
    WJRetCode code = header.code;
    NSLog(@"parse\n     retCode : %d \n     header.length : %d \n     header.cmd : %d",code,header.length,header.cmd);
    if (code != WJRetCode_RcOk) {
        return nil;
    }
    
    if (responseData.length < (smoba_header_size+header.length)) {
        NSLog(@"header.length >-> right");
        return nil;
    }
    
    NSData *msgData = [responseData subdataWithRange:NSMakeRange(smoba_header_size, header.length)];
    
    NSError *error = nil;
    GPBMessage *smobaMessage;
    switch (header.cmd) {
            
        case WJCMD_CmdAppSvrGetGameStatusResp:{
            smobaMessage = [WJGetGameStatusResp parseFromData:msgData error:&error];
            _getGameStatusResp = (WJGetGameStatusResp *)smobaMessage;
        }
            break;
            
        case WJCMD_CmdAppSvrAccountApplyResp:{
            smobaMessage = [WJApplyAccountResp parseFromData:msgData error:&error];
            _applyAccountResp = (WJApplyAccountResp *)smobaMessage;
        }
            break;
            
        case WJCMD_CmdAppSvrReportLoginResultResp:{
            smobaMessage = [WJReportLoginResultResp parseFromData:msgData error:&error];
        }
            break;
            
        case WJCMD_CmdAppSvrGetBattleResultResp:{
            smobaMessage = [WJGetBattleResultResp parseFromData:msgData error:&error];
            _battleFinishReq = (WJGetBattleResultResp *)smobaMessage;
        }
            break;
            
        case WJCMD_CmdAppSmobaAccountInfoReq:
        {
            smobaMessage = [WJAccountInfoReq parseFromData:msgData error:&error];
        }
            break;
            
//        case WJCMD_CmdChooseGameZoneReq:
//        {
//            smobaMessage = [WJChooseGameZoneReq parseFromData:msgData error:&error];
//        }
//            break;
            
//        case WJCMD_CmdProgressReportReq:{
//            smobaMessage = [WJProgressResportReq parseFromData:msgData error:&error];
//            _progressResportReq = (WJProgressResportReq *)smobaMessage;
//        }
//            break;
            
//        case WJCMD_CmdCreateRoomReq:{
//            smobaMessage = [WJCreateRoomReq parseFromData:msgData error:&error];
//        }
//            break;
//            
//        case WJCMD_CmdCreateRoomResp:{
//            smobaMessage = [WJCreateRoomResp parseFromData:msgData error:&error];
//        }
//            break;
//            
//        case WJCMD_CmdJoinRoomReq:{
//            smobaMessage = [WJJoinRoomReq parseFromData:msgData error:&error];
//        }
//            break;
//            
//        case WJCMD_CmdJoinRoomResp:{
//            smobaMessage = [WJJoinRoomResp parseFromData:msgData error:&error];
//        }
//            break;
//            
//        case WJCMD_CmdBattleStartReq:{
//            smobaMessage = [WJBattleStartReq parseFromData:msgData error:&error];
//        }
//            break;
//            
//        case WJCMD_CmdBattleStartResp:{
//            smobaMessage = [WJBattleStartResp parseFromData:msgData error:&error];
//        }
//            break;
            
        default:
            break;
    }
    
    if (error) {
        NSLog(@"parse smobadata error :%@",[error localizedDescription]);
        return nil;
    }
    
    return smobaMessage;
}

- (GPBMessage *)parseSmobaData:(NSData *)data{
    
    GPBMessage *smobaMessage = [self parseRespSmobaData:data];
    
    if (smobaMessage) {
        [self parseData:smobaMessage];
    }
    return smobaMessage;
}

- (void)parseData:(GPBMessage *)smobaMessage{
    
    NSLog(@"parse PB Data:-------%@\n\n\n\n",smobaMessage);

}

@end
