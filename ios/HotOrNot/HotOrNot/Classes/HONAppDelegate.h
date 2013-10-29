//
//  HONAppDelegate.h
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.06.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MBProgressHUD.h"
#import "HONChallengeVO.h"
#import "AFHTTPClient.h"


#define __DEV_BUILD___ 1
#define __ALWAYS_REGISTER__ 0
#define __IGNORE_SUSPENDED__ 0
#define __RESET_TOTALS__ 0


// api endpts
extern NSString * const kConfigURL;
extern NSString * const kConfigJSON;
extern NSString * const kAPIHost;
extern NSString * const kAPIChallenges;
extern NSString * const kAPIComments;
extern NSString * const kAPIDiscover;
extern NSString * const kAPIPopular;
extern NSString * const kAPISearch;
extern NSString * const kAPIUsers;
extern NSString * const kAPIVotes;
extern NSString * const kAPIGetFriends;
extern NSString * const kAPIGetSubscribees;
extern NSString * const kAPIAddFriend;
extern NSString * const kAPIRemoveFriend;
extern NSString * const kAPISMSInvites;
extern NSString * const kAPIEmailInvites;
extern NSString * const kAPITumblrLogin;
extern NSString * const kAPIEmailVerify;
extern NSString * const kAPIPhoneVerify;
extern NSString * const kAPIEmailContacts;
extern NSString * const kAPIChallengeObject;
extern NSString * const kAPIGetPublicMessages;
extern NSString * const kAPIGetPrivateMessages;
extern NSString * const kAPICheckNameAndEmail;
extern NSString * const kAPIUsersFirstRunComplete;
extern NSString * const kAPISetUserAgeGroup;
extern NSString * const kAPICreateChallenge;
extern NSString * const kAPIJoinChallenge;
extern NSString * const kAPIGetVerifyList;
extern NSString * const kAPIProcessChallengeImage;
extern NSString * const kAPIProcessUserImage;
extern NSString * const kAPISuspendedAccount;
extern NSString * const kAPIPurgeUser;
extern NSString * const kAPIPurgeContent;


// view heights
const CGFloat kNavBarHeaderHeight;
const CGFloat kSearchHeaderHeight;
const CGFloat kOrthodoxTableHeaderHeight;
const CGFloat kOrthodoxTableCellHeight;
const CGFloat kHeroVolleyTableCellHeight;

// snap params
const CGFloat kMinLuminosity;
const CGFloat kSnapRatio;
const CGFloat kSnapJPEGCompress;

// animation params
const CGFloat kHUDTime;
const CGFloat kHUDErrorTime;
const CGFloat kProfileTime;

// image sizes
const CGSize kSnapThumbSize;
const CGSize kSnapMediumSize;
const CGSize kSnapLargeSize;
const CGFloat kAvatarDim;


const BOOL kIsImageCacheEnabled;
extern NSString * const kTwilioSMS;

// network error descriptions
extern NSString * const kNetErrorNoConnection;


@interface HONAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, UIAlertViewDelegate, UIActionSheetDelegate, UIDocumentInteractionControllerDelegate>

+ (NSMutableString *)hmacToken;
+ (NSMutableString *)hmacForKey:(NSString *)key AndData:(NSString *)data;
+ (AFHTTPClient *)getHttpClientWithHMAC;
+ (NSString *)advertisingIdentifier;
+ (NSString *)identifierForVendor;
+ (NSString *)deviceModel;

+ (NSString *)apiServerPath;
+ (NSString *)customerServiceURL;
+ (NSDictionary *)s3Credentials;
+ (NSString *)twilioSMS;

+ (NSString *)s3BucketForType:(NSString *)bucketType;

+ (NSRange)ageRangeAsSeconds:(BOOL)isInSeconds;

+ (int)profileSubscribeThreshold;

+ (NSString *)bannerForSection:(int)section;

+ (BOOL)switchEnabledForKey:(NSString *)key;
+ (int)incTotalForCounter:(NSString *)key;
+ (int)totalForCounter:(NSString *)key;

+ (NSString *)smsInviteFormat;
+ (NSString *)emailInviteFormat;

+ (NSString *)twitterShareComment;
+ (NSString *)instagramShareComment;

+ (NSArray *)composeEmotions;
+ (NSArray *)replyEmotions;

+ (NSArray *)searchSubjects;
+ (NSArray *)searchUsers;
+ (NSArray *)inviteCelebs;
+ (NSArray *)popularPeople;

+ (void)writeDeviceToken:(NSString *)token;
+ (NSString *)deviceToken;

+ (void)writeUserInfo:(NSDictionary *)userInfo;
+ (NSDictionary *)infoForUser;
+ (UIImage *)avatarImage;
+ (int)ageForDate:(NSDate *)date;

+ (NSArray *)friendsList;
+ (void)addFriendToList:(NSDictionary *)friend;
+ (void)writeFriendsList:(NSArray *)friends;

+ (NSArray *)subscribeeList;
+ (void)addSubscribeeToList:(NSDictionary *)subscribee;
+ (void)writeSubscribeeList:(NSArray *)subscribees;

+ (int)hasVoted:(int)challengeID;
+ (void)setVote:(int)challengeID forCreator:(BOOL)isCreator;

+ (NSArray *)fillDiscoverChallenges:(NSArray *)challenges;
+ (NSArray *)refreshDiscoverChallenges;

+ (UIViewController *)appTabBarController;

+ (BOOL)isPhoneType5s;
+ (BOOL)isRetina4Inch;
+ (BOOL)hasTakenSelfie;
+ (BOOL)hasNetwork;
+ (BOOL)canPingAPIServer;
+ (BOOL)canPingConfigServer;
+ (NSString *)deviceLocale;
+ (void)offsetSubviewsForIOS7:(UIView *)view;

+ (NSString *)timeSinceDate:(NSDate *)date;
+ (NSString *)formattedExpireTime:(int)seconds;

+ (UIFont *)helveticaNeueFontRegular;
+ (UIFont *)helveticaNeueFontLight;
+ (UIFont *)helveticaNeueFontBold;
+ (UIFont *)helveticaNeueFontBoldItalic;
+ (UIFont *)helveticaNeueFontMedium;

+ (UIFont *)cartoGothicBold;
+ (UIFont *)cartoGothicBoldItalic;
+ (UIFont *)cartoGothicBook;
+ (UIFont *)cartoGothicItalic;

+ (UIColor *)honOrthodoxGreenColor;
+ (UIColor *)honDarkGreenColor;

+ (UIColor *)honPercentGreyscaleColor:(CGFloat)percent;

+ (UIColor *)honBlueTextColor;
+ (UIColor *)honGreenTextColor;
+ (UIColor *)honGreyTimeColor;
+ (UIColor *)honProfileStatsColor;

+ (UIColor *)honDebugColorByName:(NSString *)colorName atOpacity:(CGFloat)percent;


@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;

@end


