//
//  HONActivityItemVO.h
//  HotOrNot
//
//  Created by Matt Holcombe on 12/02/2013 @ 20:41 .
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

// Push types
typedef NS_ENUM(NSInteger, HONActivityItemType) {
	HONActivityItemTypeVerify = 0,
	HONActivityItemTypeInviteRequest,
	HONActivityItemTypeInviteAccepted,
	HONActivityItemTypeLike,
	HONActivityItemTypeShoutout,
	HONActivityItemTypeClubSubmission
};

@interface HONActivityItemVO : NSObject
+ (HONActivityItemVO *)activityWithDictionary:(NSDictionary *)dictionary;
@property (nonatomic, retain) NSDictionary *dictionary;

@property (nonatomic, retain) NSString *activityID;
@property (nonatomic, assign) HONActivityItemType activityType;

@property (nonatomic) int userID;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *avatarPrefix;

@property (nonatomic) int clubID;
@property (nonatomic) int challengeID;
@property (nonatomic, retain) NSString *clubName;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) NSDate *sentDate;

@end
