//
//  ResultsDisplayViewController.m
//  ProtoBufDemoTest
//
//  Created by miqu on 2017/9/1.
//  Copyright © 2017年 Leejun. All rights reserved.
//

#import "ResultsDisplayViewController.h"
#import "ResultsDisplayTableViewCell.h"
#import "SmobaDataManager.h"
#import "UdpSocketManager.h"

@interface ResultsDisplayViewController ()<UITableViewDelegate, UITableViewDataSource,UdpSocketManagerDelegate>
{
    WJCampSider _campSider;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray <WJBattlePlayerData*>*play1Array;
@property (nonatomic, strong) NSMutableArray <WJBattlePlayerData*>*play2Array;

@end

@implementation ResultsDisplayViewController

- (void)dealloc{
    
    [[SmobaDataManager sharedInstance] clearAccountInfo];
    [UdpSocketManager sharedInstance].delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [UdpSocketManager sharedInstance].delegate = self;
    [[UdpSocketManager sharedInstance] requestBattleResultReq];
    
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self refreshData];
    
}

- (void)refreshData{
    NSLog(@"getdata = %@", [SmobaDataManager sharedInstance].battleFinishReq.battlePlayerDataArray);
    NSMutableArray *playerArray = [NSMutableArray arrayWithArray:[SmobaDataManager sharedInstance].battleFinishReq.battlePlayerDataArray];
    
    self.play1Array = [NSMutableArray array];
    self.play2Array = [NSMutableArray array];
    
    _campSider = [SmobaDataManager sharedInstance].battleFinishReq.campSiderWin;
    for (WJBattlePlayerData *player in playerArray) {
        if (player.playerInfo.playerUid < 10) {
            continue;
        }
        if (player.playerInfo.playerUid == [[SmobaDataManager sharedInstance].currentPlayerUid integerValue]) {
            _campSider = player.campSider;
            break;
        }
    }
    
    
    for (WJBattlePlayerData *player in playerArray) {
        if (player.playerInfo.playerUid < 10 && !player.playerInfo.playerName) {
            continue;
        }
        if (player.campSider == _campSider) {
            [self.play1Array addObject:player];
        }else {
            [self.play2Array addObject:player];
        }
    }
    
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.play1Array.count;
    } else {
        
    }
    return self.play2Array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CELLREUSE = @"ResultsDisplayTableViewCell";
    ResultsDisplayTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELLREUSE];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:CELLREUSE owner:nil options:nil] firstObject];
        UIView *sbgView = [[UIView alloc] init];
        cell.backgroundView = sbgView;
    }
    
    WJBattlePlayerData *playerData;
    if (indexPath.section == 0) {
        if (self.play1Array.count > indexPath.row) {
            playerData = self.play1Array[indexPath.row];
        }
    } else {
        if (self.play2Array.count > indexPath.row) {
            playerData = self.play2Array[indexPath.row];
        }
    }
    cell.player = playerData;
    
    if (playerData.playerInfo.playerUid == [[SmobaDataManager sharedInstance].currentPlayerUid integerValue]) {
        cell.backgroundView.backgroundColor = [UIColor colorWithRed:217/255.0 green:237/255.0 blue:248/255.0 alpha:1.0];
    }else{
        cell.backgroundView.backgroundColor = [UIColor clearColor];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 51;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20);
    view.backgroundColor = [UIColor lightGrayColor];
    
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor whiteColor];
    label.frame = view.bounds;
    if (section == 0) {
        
        if (_campSider == [SmobaDataManager sharedInstance].battleFinishReq.campSiderWin) {
            label.text = @"我方胜利";
//            label.backgroundColor = [UIColor blueColor];
        }else{
            label.text = @"我方失败";
//            label.backgroundColor = [UIColor redColor];
        }
        if (_campSider == WJCampSider_CampSiderBlue) {
            label.backgroundColor = [UIColor blueColor];
        }else if (_campSider == WJCampSider_CampSiderRed){
            label.backgroundColor = [UIColor redColor];
        }
    } else if (section == 1){
        
        if (_campSider == [SmobaDataManager sharedInstance].battleFinishReq.campSiderWin) {
            label.text = @"敌方失败";
//            label.backgroundColor = [UIColor redColor];
        }else{
            label.text = @"敌方胜利";
//            label.backgroundColor = [UIColor blueColor];
        }
        if (_campSider == WJCampSider_CampSiderBlue) {
            label.backgroundColor = [UIColor redColor];
        }else if (_campSider == WJCampSider_CampSiderRed){
            label.backgroundColor = [UIColor blueColor];
        }
    }
    [view addSubview:label];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark -
#pragma mark - UdpSocketManagerDelegate
- (void)recBattleResult{
    [self refreshData];
}

@end
