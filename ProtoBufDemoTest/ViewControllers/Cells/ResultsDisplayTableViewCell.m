//
//  ResultsDisplayTableViewCell.m
//  ProtoBufDemoTest
//
//  Created by miqu on 2017/9/1.
//  Copyright © 2017年 Leejun. All rights reserved.
//

#import "ResultsDisplayTableViewCell.h"
#import <SDWebImage/SDWebImageManager.h>
#import <UIImageView+WebCache.h>

@interface ResultsDisplayTableViewCell()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UIImageView *equip1ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *equip2ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *equip3ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *equip4ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *equip5ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *equip6ImageView;
@property (weak, nonatomic) IBOutlet UILabel *namelabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *coinLabel;
@property (weak, nonatomic) IBOutlet UILabel *mvpLabel;


@end


@implementation ResultsDisplayTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setPlayer:(WJBattlePlayerData *)player {
    _player = player;
    
    NSURL *heroImgUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://118.190.44.176/pic/smoba/%@.png",player.heroSkin]];
    [self.iconImageView sd_setImageWithURL:heroImgUrl placeholderImage:nil];
    
    self.namelabel.text = _player.playerInfo.playerName;
    __weak typeof(self) weakSelf = self;
    
    self.mvpLabel.text = [NSString stringWithFormat:@"%.1f",_player.battleDetailData.score / 100.0];
    
    if (_player.battleDetailData.equipIdsArray.count > 0) {
        [weakSelf.equip1ImageView sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ossweb-img.qq.com/images/bangbang/mobile/wzry/equip/%u.png?v=1",[_player.battleDetailData.equipIdsArray valueAtIndex:0]]] placeholderImage:nil];
    }
    if (_player.battleDetailData.equipIdsArray.count > 1) {
        [weakSelf.equip2ImageView sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ossweb-img.qq.com/images/bangbang/mobile/wzry/equip/%u.png?v=1",[_player.battleDetailData.equipIdsArray valueAtIndex:1]]] placeholderImage:nil];
    }
    if (_player.battleDetailData.equipIdsArray.count > 2) {
        [weakSelf.equip3ImageView sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ossweb-img.qq.com/images/bangbang/mobile/wzry/equip/%u.png?v=1",[_player.battleDetailData.equipIdsArray valueAtIndex:2]]] placeholderImage:nil];
    }
    if (_player.battleDetailData.equipIdsArray.count > 3) {
        [weakSelf.equip4ImageView sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ossweb-img.qq.com/images/bangbang/mobile/wzry/equip/%u.png?v=1",[_player.battleDetailData.equipIdsArray valueAtIndex:3]]] placeholderImage:nil];
    }
    if (_player.battleDetailData.equipIdsArray.count > 4) {
        [weakSelf.equip5ImageView sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ossweb-img.qq.com/images/bangbang/mobile/wzry/equip/%u.png?v=1",[_player.battleDetailData.equipIdsArray valueAtIndex:4]]] placeholderImage:nil];
    }
    if (_player.battleDetailData.equipIdsArray.count > 5) {
        [weakSelf.equip6ImageView sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ossweb-img.qq.com/images/bangbang/mobile/wzry/equip/%u.png?v=1",[_player.battleDetailData.equipIdsArray valueAtIndex:5]]] placeholderImage:nil];
    }
    
    
    self.coinLabel.text = [NSString stringWithFormat:@"%u",_player.battleDetailData.totalCoin];
    self.scoreLabel.text = [NSString stringWithFormat:@"%u / %u / %u", _player.battleDetailData.kill, _player.battleDetailData.dead, _player.battleDetailData.assist];

}




@end
