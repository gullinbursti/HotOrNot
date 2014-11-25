//
//  HONClubSubmissionVO.m
//  HotOrNot
//
//  Created by Matt Holcombe on 06/11/2014 @ 09:21 .
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "NSDate+Operations.h"

#import "HONClubPhotoVO.h"

@implementation HONClubPhotoVO
@synthesize dictionary, userID, username, avatarPrefix, challengeID, parentID, clubID, clubOwnerID, submissionType, imagePrefix, comment, subjectNames, addedDate, score;

+ (HONClubPhotoVO *)clubPhotoWithDictionary:(NSDictionary *)dictionary {
	HONClubPhotoVO *vo = [[HONClubPhotoVO alloc] init];
	vo.dictionary = dictionary;
	
//	NSLog(@"ClubPhoto:[%@]", dictionary);
	
	vo.userID = [[dictionary objectForKey:@"user_id"] intValue];
	vo.username = [dictionary objectForKey:@"username"];
	vo.avatarPrefix = [[HONAPICaller sharedInstance] normalizePrefixForImageURL:([dictionary objectForKey:@"avatar"] != [NSNull null]) ? [dictionary objectForKey:@"avatar"] : vo.imagePrefix];
	
	vo.clubID = [[dictionary objectForKey:@"club_id"] intValue];
	vo.clubOwnerID = [[dictionary objectForKey:@"club_id"] intValue];
	vo.challengeID = [[dictionary objectForKey:@"challenge_id"] intValue];
	vo.parentID = [[dictionary objectForKey:@"parent_id"] intValue];
	vo.submissionType = (vo.parentID == 0) ? HONClubPhotoSubmissionTypePhoto : HONClubPhotoSubmissionTypeComment;
	
	vo.imagePrefix = [[HONAPICaller sharedInstance] normalizePrefixForImageURL:([dictionary objectForKey:@"img"] != [NSNull null]) ? [dictionary objectForKey:@"img"] : @""];
	vo.subjectNames = [dictionary objectForKey:@"subjects"];
	vo.comment = [dictionary objectForKey:@"text"];
	vo.score = [[dictionary objectForKey:@"score"] intValue];
	vo.addedDate = [NSDate dateFromOrthodoxFormattedString:[dictionary objectForKey:@"added"]];
	
	return (vo);
}

- (void)dealloc {
	self.dictionary = nil;
	self.username = nil;
	self.avatarPrefix = nil;
	self.imagePrefix = nil;
	self.subjectNames = nil;
	self.comment = nil;
	self.addedDate = nil;
}

@end
