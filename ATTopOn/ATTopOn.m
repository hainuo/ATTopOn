//
//  ATTopOn.m
//  ATTopOn
//
//  Created by hainuo on 2021/9/2.
//

#import "ATTopOn.h"
#import "apicloud/NSDictionaryUtils.h"
#import <AnyThinkSDK/AnyThinkSDK.h>
#import "apicloud/UZAppDelegate.h"
#import "apicloud/UZAppUtils.h"
#import <AnyThinkSplash/AnyThinkSplash.h>
#import <AdSupport/AdSupport.h>
#if __has_include(<AdServices/AAAttribution.h>)
#import <AdServices/AAAttribution.h>
#endif
#if __has_include(<iAd/ADClient.h>)
#import <iAd/ADClient.h>
#endif

#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AnyThinkInterstitial/AnyThinkInterstitial.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <AnyThinkRewardedVideo/AnyThinkRewardedVideo.h>


@interface ATTopOn ()<ATSplashDelegate,ATInterstitialDelegate,ATAdLoadingDelegate,ATRewardedVideoDelegate>

@property (nonatomic) BOOL initializeTopOnResult;
@property (nonatomic, strong) NSObject *splashAdObserver;
@property (nonatomic, strong) NSObject *interstitialAdObserver;
@property (nonatomic, strong) NSObject *rewardedAdObserver;
@property (nonatomic) BOOL showSplash;
@property (nonatomic) BOOL showInterstitial;
@property (nonatomic) BOOL showRewarded;

@end

@implementation ATTopOn
#pragma mark - Override
+ (void)onAppLaunch:(NSDictionary *)launchOptions {
	// 方法在应用启动时被调用

	NSLog(@" TopOn 被启动了");
	[ATAPI setLogEnabled:YES];//Turn on debug logs
	[ATAPI integrationChecking];
	[ATAPI setAdLogoVisible:YES];

	NSDictionary *feature = [theApp getFeatureByName:@"ATTopOn"];
	NSString *appKey = [feature stringValueForKey:@"appKey" defaultValue:@""];
	NSString *appId = [feature stringValueForKey:@"appId" defaultValue:@""];

	if (@available(iOS 14.0, *)) {

		//iOS 14
		NSLog(@"TopOn 初始化3");
		sleep(3);
		[ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
		         NSLog(@"ATAPI status %lu",(unsigned long)status);
		         NSLog(@"ATAPI IDFA:%@",[[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString]);
		         //to do something，like preloading
		         NSLog(@"TopOn 初始化");
		         [[ATAPI sharedInstance] startWithAppID:appId appKey:appKey error:nil];
		 }];


	}else{
		[[ATAPI sharedInstance] startWithAppID:appId appKey:appKey error:nil];
	}
}

- (id)initWithUZWebView:(UZWebView *)webView {
	if (self = [super initWithUZWebView:webView]) {

		NSDictionary *feature = [theApp getFeatureByName:@"ATTopOn"];
		NSString *appKey = [feature stringValueForKey:@"appKey" defaultValue:@""];
		NSString *appId = [feature stringValueForKey:@"appId" defaultValue:@""];

		if(!self.initializeTopOnResult) {
			if (@available(iOS 14, *)) {
				//iOS 14
				[ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
				         // 初始化方法
				         NSLog(@"TopOn 初始化 - 授权操作后");
				         self.initializeTopOnResult  = [[ATAPI sharedInstance] startWithAppID:appId appKey:appKey error:nil];
				         NSLog(@"ATAPI 初始化结果 %@",self.initializeTopOnResult?@"成功了":@"失败了");
				 }];
			} else {
				// 初始化方法
				NSLog(@"TopOn 初始化 - 未授权");
				self.initializeTopOnResult  = [[ATAPI sharedInstance] startWithAppID:appId appKey:appKey error:nil];
				NSLog(@"ATAPI 初始化结果 %@",self.initializeTopOnResult?@"成功了":@"失败了");
			}
		}
	}
	return self;
}

- (void)dispose {
	// 方法在模块销毁之前被调用
    [self removeSplashADNotification];
    [self removeInterstitialADNotification];
    [self removeRewardedADNotification];
}

#pragma mark - js_method
/**
   同步方法，结果直接以return的方式返回给js，方法名以jsmethod_sync_作为前缀，如：- (id)jsmethod_sync_systemVersion:(UZModuleMethodContext *)context，为了方便一般使用JS_METHOD_SYNC宏来定义
 */
JS_METHOD_SYNC(systemVersion:(UZModuleMethodContext *)context) {
	return [UIDevice currentDevice].systemVersion;
}
JS_METHOD_SYNC(getIDFA:(UZModuleMethodContext *)context) {
	return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}
#pragma mark - common delegate
- (void)didFinishLoadingADWithPlacementID:(NSString *)placementID {
	NSLog(@"AD Demo: didFinishLoadingADWithPlacementID %@",placementID);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"adLoaded",@"adId":placementID,@"spalshAdType":@"load",@"msg":@"广告加载成功！",@"code":@1}];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnInterstitialAdObserver" object:@{@"eventType":@"adLoaded",@"adId":placementID,@"interstitialAdType":@"load",@"msg":@"广告加载成功！",@"code":@1}];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnRewardedAdObserver" object:@{@"eventType":@"adLoaded",@"adId":placementID,@"rewardedAdType":@"load",@"msg":@"广告加载成功！",@"code":@1}];
}

- (void)didFailToLoadADWithPlacementID:(NSString* )placementID error:(NSError *)error {
	NSLog(@"AD Demo: failed to load:%@ placementId:%@", error,placementID);

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"adLoadFailed",@"adId":placementID,@"spalshAdType":@"load",@"userInfo":error.userInfo,@"msg":@"广告加载失败！",@"code":@0}];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnInterstitialAdObserver" object:@{@"eventType":@"adLoadFailed",@"adId":placementID,@"interstitialAdType":@"load",@"userInfo":error.userInfo,@"msg":@"广告加载失败！",@"code":@0}];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnRewardedAdObserver" object:@{@"eventType":@"adLoadFailed",@"adId":placementID,@"interstitialAdType":@"load",@"userInfo":error.userInfo,@"msg":@"广告加载失败！",@"code":@0}];
	sleep(1);
	if(!self.showSplash) {
		[self removeSplashADNotification];
	}
	if(!self.showInterstitial) {
		[self removeInterstitialADNotification];
	}

	if(!self.showRewarded) {
		[self removeInterstitialADNotification];
	}

}

- (void)didFinishLoadingSplashADWithPlacementID:(NSString *)placementID isTimeout:(BOOL)isTimeout {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"isTimeout",@"adId":placementID,@"spalshAdType":@"load",@"isTimeout":@(isTimeout),@"msg":@"广告加载是否超时！",@"code":@1}];
}


- (void)didTimeoutLoadingSplashADWithPlacementID:(NSString *)placementID {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"timeout",@"adId":placementID,@"spalshAdType":@"load",@"msg":@"广告加载超时！",@"code":@0}];
	//加载超时移除回调通知
	[self removeSplashADNotification];
}


#pragma mark - load splash Ad
JS_METHOD(loadSplashAD:(UZModuleMethodContext *)context) {
	NSDictionary *param = context.param;
	NSString *adId = [param stringValueForKey:@"adId" defaultValue:nil];
	self.showSplash = YES;

	__weak typeof(self) _self = self;
	[self removeSplashADNotification];
//    __weak typeof(context) _context=context;
	if(!self.splashAdObserver) {
		self.splashAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadTopOnSplashAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
		                                 NSLog(@"接收到 loadTopOnSplashAdObserver 通知，%@",note.object);
		                                 __strong typeof(_self) self = _self;
		                                 if(!self) return;
		                                 NSString *placeId = [note.object stringValueForKey:@"adId" defaultValue:nil];
		                                 NSLog(@"place Id %@",placeId);
		                                 NSLog(@"ad Id %@",adId);
		                                 if([placeId isEqual: adId]) {
							 [context callbackWithRet:note.object err:nil delete:NO];
						 }else{
							 NSLog(@" placeid 和 adid不相等");

							 [context callbackWithRet:note.object err:nil delete:NO];
						 }
					 }];
	}

	[[ATAdManager sharedManager] loadADWithPlacementID:adId extra:@{kATSplashExtraTolerateTimeoutKey:@5.5} delegate:self containerView:nil];
	NSLog(@"TopOnSplashAd is starting to load");
	[context callbackWithRet:@{@"eventType":@"doLoad",@"adId":adId,@"spalshAdType":@"load",@"msg":@"加载开屏广告命令执行成功！",@"code":@1} err:nil delete:NO];


}
JS_METHOD(checkSplashAdIsReady:(UZModuleMethodContext *)context) {
	NSDictionary *param = context.param;
	NSString *adId = [param stringValueForKey:@"adId" defaultValue:nil];


	ATCheckLoadModel *checkLoadModel = [[ATAdManager sharedManager] checkSplashLoadStatusForPlacementID:adId];
	if(checkLoadModel.isLoading) {
		NSLog(@"检查结果 %@",@{@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adOfferInfo":@{}});

		[context callbackWithRet:@{@"code":@0,@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adOfferInfo":@{},@"msg":@"检查开屏广告是否准备就绪命令执行成功！"} err:nil delete:YES];
		return;
	}
	NSDictionary *adOfferInfo = nil;

	if(checkLoadModel.isReady) {
		adOfferInfo = checkLoadModel.adOfferInfo;
		NSLog(@"检查结果 %@",@{@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adOfferInfo":adOfferInfo});

		[context callbackWithRet:@{@"code":@1,@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adId":adId,@"adOfferInfo":adOfferInfo,@"msg":@"检查开屏广告是否准备就绪命令执行成功！"} err:nil delete:YES];
		return;
	}
	[context callbackWithRet:@{@"code":@0,@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adOfferInfo":@{},@"adId":adId,@"msg":@"开屏广告就绪状态异常！"} err:nil delete:YES];



}
JS_METHOD(showSplashAd:(UZModuleMethodContext *)context) {
	NSDictionary *param = context.param;
	NSString *adId = [param stringValueForKey:@"adId" defaultValue:nil];
	__weak typeof(self) _self = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		__strong typeof(_self) self = _self;
		if(!self) {
			return;
		}
		UIWindow *mainWindow = nil;
		if (@available(iOS 13.0, *)) {
			mainWindow = [UIApplication sharedApplication].windows.firstObject;
			[mainWindow makeKeyWindow];
		}else {
			mainWindow = [UIApplication sharedApplication].keyWindow;
		}
		[[ATAdManager sharedManager] showSplashWithPlacementID:adId window:mainWindow delegate:self];

		[context callbackWithRet:@{@"eventType":@"doShow",@"adId":adId,@"spalshAdType":@"show",@"msg":@"展示开屏广告命令执行成功！",@"code":@1} err:nil delete:YES];
	});

}
-(void) removeSplashADNotification {
	//同时移除监听

	NSLog(@"移除通知监听");
	[[NSNotificationCenter defaultCenter] removeObserver:self.splashAdObserver name:@"loadTopOnSplashAdObserver" object:nil];
	self.splashAdObserver = nil;
	self.showSplash = NO;
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"onAdRemove",@"adeventType":@"onAdRemoved",@"msg":@"广告移除成功！",@"code":@1}];
}

#pragma mark - loading Splash Ad delegate


- (void)splashDeepLinkOrJumpForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra result:(BOOL)success {
	NSLog(@"Splash Demo: splashDeepLinkOrJumpForPlacementID placementId %@ extra:%@  result%d",placementID,extra,success?1:0);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"deepLinkJump",@"adId":placementID,@"spalshAdType":@"show",@"msg":@"广告deepLink 跳转！",@"extra":extra,@"success":@(success),@"code":@1}];
}

- (void)splashDetailDidClosedForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {

	NSLog(@"Splash Demo: splashDetailDidClosedForPlacementID placementId %@ extra:%@ ",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"detailClosed",@"adId":placementID,@"spalshAdType":@"show",@"msg":@"广告详情页面关闭了！",@"extra":extra,@"code":@1}];
}

- (void)splashDidClickForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {
	NSLog(@"Splash Demo: splashDidClickForPlacementID placementId %@ extra:%@ ",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"adClicked",@"adId":placementID,@"spalshAdType":@"show",@"msg":@"广告被点击了！",@"extra":extra,@"code":@1}];

}

- (void)splashDidCloseForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {
	NSLog(@"Splash Demo: splashDidCloseForPlacementID placementId %@ extra:%@ ",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"adClosed",@"adId":placementID,@"spalshAdType":@"show",@"msg":@"广告关闭了！",@"extra":extra,@"code":@1}];

	[self removeSplashADNotification];

}

- (void)splashDidShowFailedForPlacementID:(NSString *)placementID error:(NSError *)error extra:(NSDictionary *)extra {
	NSLog(@"Splash Demo: splashDidShowFailedForPlacementID placementId %@ extra:%@ ",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"adShowFailed",@"adId":placementID,@"spalshAdType":@"show",@"msg":@"广告显示失败了！",@"extra":extra,@"code":@0}];
	[self removeSplashADNotification];

}

- (void)splashDidShowForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {
	NSLog(@"Splash Demo: splashDidShowForPlacementID placementId %@ extra:%@ ",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"adShowed",@"adId":placementID,@"spalshAdType":@"show",@"msg":@"广告展示了！",@"extra":extra,@"code":@1}];
	self.showSplash=YES;
}

- (void)splashZoomOutViewDidClickForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {
	NSLog(@"Splash Demo: splashZoomOutViewDidClickForPlacementID placementId %@ extra:%@ ",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"adZoomOutClicked",@"adId":placementID,@"spalshAdType":@"show",@"msg":@"广告zoomout被点击了！",@"extra":extra,@"code":@1}];

}

- (void)splashZoomOutViewDidCloseForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {
	NSLog(@"Splash Demo: splashZoomOutViewDidCloseForPlacementID placementId %@ extra:%@ ",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"adZoomOutClosed",@"adId":placementID,@"spalshAdType":@"show",@"msg":@"广告zommout被关闭了！",@"extra":extra,@"code":@1}];
}

- (void)splashCountdownTime:(NSInteger)countdown forPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {

	NSLog(@"Splash Demo: splashCountdownTime placementId %@ extra:%@ ",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnSplashAdObserver" object:@{@"eventType":@"splashCountdownTime",@"adId":placementID,@"spalshAdType":@"show",@"msg":@"广告zommout被关闭了！",@"extra":extra,@"code":@1}];
}



#pragma mark - 全屏广告
JS_METHOD(loadInterstitialAD:(UZModuleMethodContext *)context) {
	NSDictionary *param = context.param;
	NSString *adId = [param stringValueForKey:@"adId" defaultValue:nil];
    self.showInterstitial = YES;
	__weak typeof(self) _self = self;
	[self removeInterstitialADNotification];
	if(!self.interstitialAdObserver) {
		self.interstitialAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadTopOnInterstitialAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
		                                       NSLog(@"接收到 loadTopOnInterstitialAdObserver 通知，%@",note.object);
		                                       __strong typeof(_self) self = _self;
		                                       if(!self) return;
		                                       NSString *placeId = [note.object stringValueForKey:@"adId" defaultValue:nil];
		                                       NSLog(@"place Id %@",placeId);
		                                       NSLog(@"ad Id %@",adId);
		                                       if([placeId isEqual: adId]) {
							       [context callbackWithRet:note.object err:nil delete:NO];
						       }else{

							       [context callbackWithRet:note.object err:nil delete:NO];
						       }
					       }];
	}

	[[ATAdManager sharedManager] loadADWithPlacementID:adId extra:nil delegate:self];
	

	NSLog(@"TopOnInterstitial is starting to load");
	[context callbackWithRet:@{@"eventType":@"doLoad",@"adId":adId,@"interstitialAdType":@"load",@"msg":@"加载插屏广告命令执行成功！",@"code":@1} err:nil delete:NO];
}
JS_METHOD(checkInterstitialAdIsReady:(UZModuleMethodContext *)context) {
	NSDictionary *param = context.param;
	NSString *adId = [param stringValueForKey:@"adId" defaultValue:nil];


	ATCheckLoadModel *checkLoadModel = [[ATAdManager sharedManager] checkInterstitialLoadStatusForPlacementID:adId];
	if(checkLoadModel.isLoading) {
		NSLog(@"检查结果 %@",@{@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adOfferInfo":@{}});

		[context callbackWithRet:@{@"code":@0,@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adOfferInfo":@{},@"msg":@"检查插屏广告是否准备就绪命令执行成功！"} err:nil delete:YES];
		return;
	}
	NSDictionary *adOfferInfo = nil;

	if(checkLoadModel.isReady) {
		adOfferInfo = checkLoadModel.adOfferInfo;
		NSLog(@"检查结果 %@",@{@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adOfferInfo":adOfferInfo});

		[context callbackWithRet:@{@"code":@1,@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adId":adId,@"adOfferInfo":adOfferInfo,@"msg":@"检查插屏广告是否准备就绪命令执行成功！"} err:nil delete:YES];
		return;
	}
	[context callbackWithRet:@{@"code":@0,@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adOfferInfo":@{},@"adId":adId,@"msg":@"插屏广告就绪状态异常！"} err:nil delete:YES];



}
JS_METHOD(showInterstitialAd:(UZModuleMethodContext *)context) {
	NSDictionary *param = context.param;
	NSString *adId = [param stringValueForKey:@"adId" defaultValue:nil];

	NSString *scene = [param stringValueForKey:@"scene" defaultValue:nil];
	__weak typeof(self) _self = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		__strong typeof(_self) self = _self;
		if(!self) {
			return;
		}
		UIWindow *mainWindow = nil;
		if (@available(iOS 13.0, *)) {
			mainWindow = [UIApplication sharedApplication].windows.firstObject;
			[mainWindow makeKeyWindow];
		}else {
			mainWindow = [UIApplication sharedApplication].keyWindow;
		}
		[[ATAdManager sharedManager] showInterstitialWithPlacementID:adId scene:scene inViewController:mainWindow.rootViewController delegate:self];

		[context callbackWithRet:@{@"eventType":@"doShow",@"adId":adId,@"interstitialAdType":@"show",@"msg":@"展示插屏告命令执行成功！",@"code":@1} err:nil delete:YES];

	});



}
-(void) removeInterstitialADNotification {
	//同时移除监听
	NSLog(@"移除通知监听");
	[[NSNotificationCenter defaultCenter] removeObserver:self.interstitialAdObserver name:@"loadTopOnInterstitialAdObserver" object:nil];
	self.interstitialAdObserver = nil;
	self.showInterstitial = NO;

//    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnInterstitialAdObserver" object:@{@"eventType":@"adLoaded",@"adId":placementID,@"interstitialAdType":@"load",@"msg":@"广告加载成功！",@"code":@1}];
}
#pragma mark - loading interstitial Ad delegate
- (void)interstitialDeepLinkOrJumpForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra result:(BOOL)success {
	NSLog(@"Interstitial Demo: interstitialDeepLinkOrJumpForPlacementID placementId %@ extra:%@  result%d",placementID,extra,success?1:0);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnInterstitialAdObserver" object:@{@"eventType":@"deepLinkJump",@"adId":placementID,@"interstitialAdType":@"show",@"msg":@"广告deepLink跳转",@"extra":extra,@"code":@1}];
}

- (void)interstitialDidClickForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {
	NSLog(@"Interstitial Demo: interstitialDidClickForPlacementID placementId %@ extra:%@",placementID,extra);    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnInterstitialAdObserver" object:@{@"eventType":@"adClicked",@"adId":placementID,@"interstitialAdType":@"show",@"msg":@"广告被点击了",@"extra":extra,@"code":@1}];
}

- (void)interstitialDidCloseForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {
	NSLog(@"Interstitial Demo: interstitialDidCloseForPlacementID placementId %@ extra:%@",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnInterstitialAdObserver" object:@{@"eventType":@"adClosed",@"adId":placementID,@"interstitialAdType":@"show",@"msg":@"广告关闭了",@"extra":extra,@"code":@1}];
    [self removeInterstitialADNotification];
}

- (void)interstitialDidEndPlayingVideoForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {
	NSLog(@"Interstitial Demo: interstitialDidEndPlayingVideoForPlacementID placementId %@ extra:%@",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnInterstitialAdObserver" object:@{@"eventType":@"adVideoPlayEnded",@"adId":placementID,@"interstitialAdType":@"show",@"extra":extra,@"msg":@"广告视频播放结束了",@"code":@1}];
}

- (void)interstitialDidFailToPlayVideoForPlacementID:(NSString *)placementID error:(NSError *)error extra:(NSDictionary *)extra {
	NSLog(@"Interstitial Demo: interstitialDidFailToPlayVideoForPlacementID placementId %@ extra:%@",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnInterstitialAdObserver" object:@{@"eventType":@"adVideoPlayFailed",@"adId":placementID,@"interstitialAdType":@"show",@"userInfo":error.userInfo,@"extra":extra,@"msg":@"广告视频播放失败",@"code":@0}];
}

- (void)interstitialDidShowForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {

	NSLog(@"Interstitial Demo: interstitialDidShowForPlacementID placementId %@ extra:%@",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnInterstitialAdObserver" object:@{@"eventType":@"adShowded",@"adId":placementID,@"interstitialAdType":@"show",@"msg":@"广告展示了",@"extra":extra,@"code":@1}];
}

- (void)interstitialDidStartPlayingVideoForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {

	NSLog(@"Interstitial Demo: interstitialDidStartPlayingVideoForPlacementID placementId %@ extra:%@",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnInterstitialAdObserver" object:@{@"eventType":@"adVideoPlayStarted",@"adId":placementID,@"interstitialAdType":@"show",@"extra":extra,@"msg":@"广告展视频开始播放",@"code":@1}];
}

- (void)interstitialFailedToShowForPlacementID:(NSString *)placementID error:(NSError *)error extra:(NSDictionary *)extra {

	NSLog(@"Interstitial Demo: interstitialFailedToShowForPlacementID placementId %@ extra:%@",placementID,extra);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnInterstitialAdObserver" object:@{@"eventType":@"adShowdFailed",@"adId":placementID,@"interstitialAdType":@"show",@"userInfo":error.userInfo,@"extra":extra,@"msg":@"广告展示失败",@"code":@0}];
	[self removeInterstitialADNotification];
}
#pragma mark - gad test suit 打开测试套件页面
JS_METHOD(openTest:(UZModuleMethodContext *)context) {
//    NSDictionary *param = context.param;
	UIWindow *mainWindow = nil;
	if (@available(iOS 13.0, *)) {
		mainWindow = [UIApplication sharedApplication].windows.firstObject;
		[mainWindow makeKeyWindow];
	}else {
		mainWindow = [UIApplication sharedApplication].keyWindow;
	}
	dispatch_async(dispatch_get_main_queue(), ^{
		[GADMobileAds.sharedInstance presentAdInspectorFromViewController:mainWindow.rootViewController completionHandler:^(NSError * _Nullable error) {
		         NSLog(@"TEST ERROR IS %@",error);
		 }];

	});
	[context callbackWithRet:@{@"code":@1} err:nil delete:YES];
}

#pragma mark 激励视频
JS_METHOD(loadRewardedAD:(UZModuleMethodContext *)context) {
	NSDictionary *param = context.param;
	NSString *adId = [param stringValueForKey:@"adId" defaultValue:nil];

	NSString *deviceId = [param stringValueForKey:@"deviceId" defaultValue:nil];
    self.showRewarded = YES;
    
	__weak typeof(self) _self = self;
	[self removeRewardedADNotification];
	self.rewardedAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadTopOnRewardedAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
	                                   NSLog(@"接收到 loadTopOnRewardedAdObserver 通知，%@",note.object);
	                                   __strong typeof(_self) self = _self;
	                                   if(!self) return;
	                                   NSString *placeId = [note.object stringValueForKey:@"adId" defaultValue:nil];
	                                   NSLog(@"place Id %@",placeId);
	                                   NSLog(@"ad Id %@",adId);
	                                   if([placeId isEqual: adId]) {
						   [context callbackWithRet:note.object err:nil delete:NO];
					   }else{

						   [context callbackWithRet:note.object err:nil delete:NO];
					   }
				   }];

	[[ATAdManager sharedManager] loadADWithPlacementID:adId extra:@{kATAdLoadingExtraUserIDKey:deviceId} delegate:self];


	NSLog(@"TopOnInterstitial is starting to load");
	[context callbackWithRet:@{@"eventType":@"doLoad",@"adId":adId,@"rewardedAdType":@"load",@"msg":@"加载激励广告命令执行成功！",@"code":@1} err:nil delete:NO];
}
JS_METHOD(checkRewardedAdIsReady:(UZModuleMethodContext *)context) {
	NSDictionary *param = context.param;
	NSString *adId = [param stringValueForKey:@"adId" defaultValue:nil];


	ATCheckLoadModel *checkLoadModel = [[ATAdManager sharedManager] checkRewardedVideoLoadStatusForPlacementID:adId];
	if(checkLoadModel.isLoading) {
		NSLog(@"检查结果 %@",@{@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adOfferInfo":@{}});

		[context callbackWithRet:@{@"code":@0,@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adOfferInfo":@{},@"msg":@"检查激励广告是否准备就绪命令执行成功！"} err:nil delete:YES];
		return;
	}
	NSDictionary *adOfferInfo = nil;

	if(checkLoadModel.isReady) {
		adOfferInfo = checkLoadModel.adOfferInfo;
		NSLog(@"检查结果 %@",@{@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adOfferInfo":adOfferInfo});
		[context callbackWithRet:@{@"code":@1,@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adId":adId,@"adOfferInfo":adOfferInfo,@"msg":@"检查激励广告是否准备就绪命令执行成功！"} err:nil delete:YES];
		return;
	}
	[context callbackWithRet:@{@"code":@0,@"isReady":@(checkLoadModel.isReady),@"isLoading":@(checkLoadModel.isLoading),@"adOfferInfo":@{},@"adId":adId,@"msg":@"激励广告就绪状态异常！"} err:nil delete:YES];

}
JS_METHOD(showRewardedAd:(UZModuleMethodContext *)context) {
	NSDictionary *param = context.param;
	NSString *adId = [param stringValueForKey:@"adId" defaultValue:nil];

	__weak typeof(self) _self = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		__strong typeof(_self) self = _self;
		if(!self) {
			return;
		}
		UIWindow *mainWindow = nil;
		if (@available(iOS 13.0, *)) {
			mainWindow = [UIApplication sharedApplication].windows.firstObject;
			[mainWindow makeKeyWindow];
		}else {
			mainWindow = [UIApplication sharedApplication].keyWindow;
		}
        [[ATAdManager sharedManager] showRewardedVideoWithPlacementID:adId inViewController:mainWindow.rootViewController delegate:self];
		[context callbackWithRet:@{@"eventType":@"doShow",@"adId":adId,@"rewardedAdType":@"show",@"msg":@"展示插屏告命令执行成功！",@"code":@1} err:nil delete:YES];
	});
}
-(void) removeRewardedADNotification {

	NSLog(@"移除通知监听");
	[[NSNotificationCenter defaultCenter] removeObserver:self.rewardedAdObserver name:@"loadTopOnRewardedAdObserver" object:nil];
	self.rewardedAdObserver = nil;
	self.showRewarded = NO;

}

#pragma mark - loading rewarded Ad delegate
/**
 激励视频广告播放开始

 */
- (void)rewardedVideoDidStartPlayingForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {
    NSLog(@"ATRewardedVideoVideoViewController::rewardedVideoDidRewardSuccessForPlacemenID:%@ extra:%@",placementID,extra);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnRewardedAdObserver" object:@{@"eventType":@"adVideoPlay",@"adId":placementID,@"rewardedAdType":@"show",@"msg":@"广告开始播放！",@"code":@1}];
}

/**
 激励视频广告播放失败
 */
- (void)rewardedVideoDidFailToPlayForPlacementID:(NSString *)placementID error:(NSError *)error extra:(NSDictionary *)extra {
    NSLog(@"ATRewardedVideoVideoViewController::rewardedVideoDidFailToPlayForPlacementID:%@ error:%@ extra:%@", placementID, error, extra);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnRewardedAdObserver" object:@{@"eventType":@"adVideoPlayFaild",@"adId":placementID,@"rewardedAdType":@"show",@"userInfo":error.userInfo,@"extra":extra,@"msg":@"广告播放失败！",@"code":@0}];
}

/**
 激励视频广告点击
 */
- (void)rewardedVideoDidClickForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {
    NSLog(@"ATRewardedVideoVideoViewController::rewardedVideoDidClickForPlacementID:%@ extra:%@", placementID, extra);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnRewardedAdObserver" object:@{@"eventType":@"adClicked",@"adId":placementID,@"rewardedAdType":@"show",@"msg":@"广告被点击了！",@"code":@1}];
}

/**
 激励视频广告播放结束
 */
- (void)rewardedVideoDidEndPlayingForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra {
    NSLog(@"ATRewardedVideoVideoViewController::rewardedVideoDidEndPlayingForPlacementID:%@ extra:%@", placementID, extra);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnRewardedAdObserver" object:@{@"eventType":@"adVideoPlayEnd",@"adId":placementID,@"rewardedAdType":@"show",@"msg":@"广告播放结束！",@"code":@1}];
}

/**
 激励视频广告关闭
 */
- (void)rewardedVideoDidCloseForPlacementID:(NSString *)placementID rewarded:(BOOL)rewarded extra:(NSDictionary *)extra {
    NSLog(@"ATRewardedVideoVideoViewController::rewardedVideoDidCloseForPlacementID:%@, rewarded:%@ extra:%@", placementID, rewarded ? @"yes" : @"no", extra);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnRewardedAdObserver" object:@{@"eventType":@"adClosed",@"adId":placementID,@"rewardedAdType":@"show",@"msg":@"广告关闭！",@"code":@1}];
    [self removeRewardedADNotification];
}

/**
 激励视频广告点击跳转是否为Deeplink形式，目前只针对TopOn Adx的广告返回
 */
- (void)rewardedVideoDidDeepLinkOrJumpForPlacementID:(NSString *)placementID extra:(NSDictionary *)extra result:(BOOL)success {
    NSLog(@"ATRewardedVideoVideoViewController: rewardedVideoDidDeepLinkOrJumpForPlacementID placementId %@ extra:%@  result%@",placementID,extra,success ? @"yes" : @"no");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnRewardedAdObserver" object:@{@"eventType":@"deepLinkJump",@"adId":placementID,@"rewardedAdType":@"show",@"msg":@"广告deepLink 跳转！",@"extra":extra,@"success":@(success),@"code":@1}];
}


/**
 激励视频广告奖励下发
 */
- (void)rewardedVideoDidRewardSuccessForPlacemenID:(NSString *)placementID extra:(NSDictionary *)extra {
    NSLog(@"ATRewardedVideoVideoViewController::rewardedVideoDidRewardSuccessForPlacemenID:%@ extra:%@",placementID,extra);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadTopOnRewardedAdObserver" object:@{@"eventType":@"rewardSuccess",@"adId":placementID,@"rewardedAdType":@"show",@"msg":@"奖励下发！",@"extra":extra,@"code":@1}];
}

@end
