//
//  UdpSocketManager.h
//  ProtoBufDemoTest
//
//  Created by Leejun on 2017/8/30.
//  Copyright © 2017年 Leejun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SmobaDataManager.h"

typedef void(^onSmobaServiceBlock)(GPBMessage *smobaMessage);

@protocol UdpSocketManagerDelegate;

@interface UdpSocketManager : NSObject

@property (nonatomic, strong) NSDictionary *accountDic;//登录的授权信息

@property (nonatomic, assign) id <UdpSocketManagerDelegate> delegate;

+ (instancetype)sharedInstance;
- (void)logout;

- (void)addOnSmobaServiceBlock:(onSmobaServiceBlock)block cmd:(WJCMD)cmd;
//- (void)removeOnSmobaServiceBlockForCmd:(WJCMD)cmd;


//udp send
- (void)sendBackToHost:(NSString *)ip port:(uint16_t)port withMessage:(GPBMessage *)smobaMessage;

//tcp send
- (void)sendTcpMessage:(GPBMessage *)smobaMessage cmd:(WJCMD)cmd;

//游戏结果请求
- (void)requestBattleResultReq;
//登录成功失败请求-- 0:失败；1:成功
- (void)requestReportLoginResultReq:(uint32_t)loginSucc;

@end


@protocol UdpSocketManagerDelegate <NSObject>

@optional
- (void)recBattleResult;
- (void)recGameStatus;

@end
