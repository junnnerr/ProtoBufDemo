//
//  SmobaDataManager.h
//  ProtoBufDemoTest
//
//  Created by Leejun on 2017/8/24.
//  Copyright © 2017年 Leejun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SmobaData.pbobjc.h"

#define TEST_ACCOUNT_ID  2

#define SmobaDataMagic 0xfeed121

NSData *GenerateReqSmobaData(WJCMD cmd, WJRetCode code, GPBMessage *message);

typedef enum : NSUInteger {
    SmobaFlagsNone=0,
    SmobaFlagsInitInfo=1, //授权信息
    SmobaFlagsChooseGameServer=3, //区号
    SmobaFlagsRoomDataInfo=5,
    SmobaFlagsRoomPlayerInfo=7,
    SmobaFlagsBattleInfo=9,
} SmobaFlags;

@interface SmobaDataManager : NSObject

@property (nonatomic, strong) WJApplyAccountResp *applyAccountResp;

@property (nonatomic, strong) WJGetGameStatusResp *getGameStatusResp;

@property (nonatomic, strong) WJGetBattleResultResp *battleFinishReq;

@property (nonatomic, strong) NSString *currentPlayerUid;

+ (instancetype)sharedInstance;

- (BOOL)hasAccoutLoggedin;
- (void)clearAccountInfo;
- (WJGameStatus)currentGameStatus;

//解析header & body
- (GPBMessage *)parseSmobaData:(NSData *)data;

//UDP
- (NSData *)sendAccountInfoReqMessage:(NSDictionary *)dic;

- (NSData *)sendPublicReqMessage:(WJCMD)cmd;



- (NSData *)sendCreateRoomReqMessage:(WJRoomType)roomType;
- (NSData *)sendJoinRoomReqMessage:(GPBMessage *)joinRoomReq;

- (NSData *)sendChooseGameZoneReqMessage;


@end
