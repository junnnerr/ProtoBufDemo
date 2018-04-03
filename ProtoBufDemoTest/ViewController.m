//
//  ViewController.m
//  ProtoBufDemoTest
//
//  Created by Leejun on 2017/8/24.
//  Copyright © 2017年 Leejun. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncUdpSocket.h"
#import "SendViewController.h"
#import "SmobaData.pbobjc.h"
#import "QQGameViewController.h"
#import "SmobaDataManager.h"

#import "UdpSocketManager.h"
#import "AppDelegate.h"

@interface ViewController ()
<
GCDAsyncUdpSocketDelegate,
UdpSocketManagerDelegate
>
{
    //udp对象
    GCDAsyncUdpSocket *_udpServerSoket;
}

@property (nonatomic, weak) IBOutlet UIButton *applyAcccountButton;

@end

@implementation ViewController

- (IBAction)qqLoginGameAction:(id)sender{
    
    WJGameStatus gameStatus = [[SmobaDataManager sharedInstance] currentGameStatus];
    
    if (gameStatus != WJGameStatus_GameStatusInit) {
        return;
    }
    
    if ([[SmobaDataManager sharedInstance] hasAccoutLoggedin] ) {
        QQGameViewController *qqVc = [[QQGameViewController alloc] init];
        [self.navigationController pushViewController:qqVc animated:NO];
        return;
    }
    
    [[UdpSocketManager sharedInstance] addOnSmobaServiceBlock:^(GPBMessage *smobaMessage) {
        
        if ([smobaMessage isKindOfClass:[WJApplyAccountResp class]]) {
            WJApplyAccountResp *applyAccountResp = (WJApplyAccountResp *)smobaMessage;
            if (applyAccountResp.account.length > 0 && applyAccountResp.password.length > 0) {
                //自动授权
                QQGameViewController *qqVc = [[QQGameViewController alloc] init];
                [self.navigationController pushViewController:qqVc animated:NO];
            }
        }
        
    } cmd:WJCMD_CmdAppSvrAccountApplyResp];
    [[UdpSocketManager sharedInstance] sendTcpMessage:nil cmd:WJCMD_CmdAppSvrAccountApplyReq];
    
}

- (IBAction)weChatAction:(id)sender{
    
    NSURL *url = [NSURL URLWithString:@"weixin://app/wx95a3a4d7c627e07d/auth/?scope=snsapi_base%2Csnsapi_userinfo%2Csnsapi_friend%2Csnsapi_message&state=weixin"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

-(void)showNavItem{
    UIBarButtonItem *sendMyself = [[UIBarButtonItem alloc] initWithTitle:@"释放账号" style:UIBarButtonItemStylePlain target:self action:@selector(sendMyself)];
    self.navigationItem.rightBarButtonItem = sendMyself;
}

- (void)sendMyself{
    
    //账号释放请求
    [[UdpSocketManager sharedInstance] sendTcpMessage:nil cmd:WJCMD_CmdAppGmReleaseAccountReq];
    //清除本地信息
    [[SmobaDataManager sharedInstance] clearAccountInfo];
    //重新请求游戏状态
    [[UdpSocketManager sharedInstance] sendTcpMessage:nil cmd:WJCMD_CmdAppSvrGetGameStatusReq];
    return;
    SendViewController *sendVc = [[SendViewController alloc] init];
    [self.navigationController pushViewController:sendVc animated:YES];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self requestGameStatuse];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self showNavItem];
    [UdpSocketManager sharedInstance].delegate = self;
}

- (void)requestGameStatuse{
    
    NSLog(@"requestGameStatuse !!!!!!");
    [[UdpSocketManager sharedInstance] sendTcpMessage:nil cmd:WJCMD_CmdAppSvrGetGameStatusReq];
}

- (void)refreshUI{
    
    WJGameStatus gameStatus = [[SmobaDataManager sharedInstance] currentGameStatus];
    if (gameStatus == WJGameStatus_GameStatusInit) {
        self.applyAcccountButton.enabled = YES;
    }else{
        self.applyAcccountButton.enabled = NO;
    }
}


#pragma mark -
#pragma mark - UdpSocketManagerDelegate
- (void)recGameStatus{
    [self refreshUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
