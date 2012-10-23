//
//  HONAppDelegate.h
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.06.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@class SMClient;

@interface HONAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) SMClient *client;


+ (NSString *)apiServerPath;
+ (NSNumber *)challengeDuration;
+ (NSString *)dailySubjectName;
+ (NSDictionary *)s3Credentials;
+ (NSString *)facebookCanvasURL;

+ (void)openSession;
+ (void)writeDeviceToken:(NSString *)token;
+ (NSString *)deviceToken;

+ (void)writeUserInfo:(NSDictionary *)userInfo;
+ (NSDictionary *)infoForUser;

+ (void)writeFBProfile:(NSDictionary *)userInfo;
+ (NSDictionary *)fbProfileForUser;

+ (void)setAllowsFBPosting:(BOOL)canPost;
+ (BOOL)allowsFBPosting;

+ (UIViewController *)appTabBarController;

+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size;
+ (UIImage *)scaleImage:(UIImage *)image byFactor:(float)factor;
+ (UIImage *)cropImage:(UIImage *)image toRect:(CGRect)rect;

+ (NSArray *)fbPermissions;

+ (BOOL)isRetina5;
+ (BOOL)hasNetwork;
+ (BOOL)canPingServers;
+ (BOOL)canPingAPIServer;
+ (BOOL)canPingParseServer;

+ (UIFont *)honHelveticaNeueFontBold;
+ (UIFont *)honHelveticaNeueFontMedium;

+ (UIColor *)honBlueTxtColor;
+ (UIColor *)honGreyTxtColor;

+ (int)secondsBeforeDate:(NSDate *)date;
+ (int)minutesBeforeDate:(NSDate *)date;
+ (int)hoursBeforeDate:(NSDate *)date;


#define kServerPath @"http://discover.getassembly.com/hotornot/api"
#define kUsersAPI @"Users.php"
#define kChallengesAPI @"Challenges.php"
#define kPopularAPI @"Popular.php"

#define kThumb1W 50.0
#define kThumb1H 67.0

#define kMediumW 182.0
#define kMediumH 244.0

#define kLargeW 620.0
#define kLargeH 830.0

#define kPhotoRatio 1.33884297520661

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;

@end
