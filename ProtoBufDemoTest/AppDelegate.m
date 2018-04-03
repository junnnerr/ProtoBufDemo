//
//  AppDelegate.m
//  ProtoBufDemoTest
//
//  Created by Leejun on 2017/8/24.
//  Copyright © 2017年 Leejun. All rights reserved.
//

#import "AppDelegate.h"
#import "ResultsDisplayViewController.h"
#import "UdpSocketManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [UdpSocketManager sharedInstance];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];//开启后台任务
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    [[UIApplication sharedApplication] endBackgroundTask:UIBackgroundTaskInvalid];//结束后台任务
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)gotoGameResultVc{
    //游戏结果跳转
    ResultsDisplayViewController *sendVc = [[ResultsDisplayViewController alloc] init];
    UINavigationController *nav = nil;
    if ([self.window.rootViewController isKindOfClass:[UINavigationController class]]) {
        nav = (UINavigationController *)self.window.rootViewController;
    }
    
    [nav pushViewController:sendVc animated:YES];
}

-(NSDictionary *)getParamDictFromUrl:(NSURL *)url{
    
    NSURLComponents* urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    
    NSMutableDictionary<NSString *, NSString *>* queryParams = [NSMutableDictionary<NSString *, NSString *> new];
    for (NSURLQueryItem* queryItem in [urlComponents queryItems])
    {
        if (queryItem.value == nil)
        {
            continue;
        }
        [queryParams setObject:queryItem.value forKey:queryItem.name];
    }
    return queryParams;
}

- (BOOL)handleOpenURL:(NSURL *)url {
    NSLog(@"query=%@,scheme=%@,host=%@", url.query, url.scheme, url.host);
    NSString *scheme = [url scheme];
    
    if([scheme isEqualToString:@"wyopen"]){
        
//        NSString *lastCompment = [[url path] lastPathComponent];
        NSString *host = [url host];
        if ([host isEqualToString:@"battleResult"]) {
            NSDictionary *paramDic = [self getParamDictFromUrl:url];
            [SmobaDataManager sharedInstance].currentPlayerUid = [paramDic objectForKey:@"playerUid"];
            //跳转至游戏结果页面
            [self gotoGameResultVc];
            
        }
        return YES;
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [self handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"openURL url=%@, sourceApplication=%@, annotation=%@", url, sourceApplication, annotation);
    return [self handleOpenURL:url];
}

@end
