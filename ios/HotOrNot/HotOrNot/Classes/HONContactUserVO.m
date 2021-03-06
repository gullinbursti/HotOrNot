//
//  HONContactUserVO.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 04.26.13.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import "NSDate+Operations.h"
#import "NSString+Formatting.h"
#import "NSString+Validate.h"

#import "HONContactUserVO.h"

@implementation HONContactUserVO
@synthesize dictionary;
@synthesize contactType, firstName, lastName, fullName, rawNumber, mobileNumber, email, avatarData, avatarImage, isSMSAvailable, userID, username, avatarPrefix;

+ (HONContactUserVO *)contactWithDictionary:(NSDictionary *)dictionary {
//	NSLog(@"contactWithDictionary:[%@]", dictionary);
	
	HONContactUserVO *vo = [[HONContactUserVO alloc] init];
	vo.dictionary = dictionary;
	
	vo.firstName = ([dictionary objectForKey:@"f_name"] != nil) ? [dictionary objectForKey:@"f_name"] : @"";
	vo.lastName = ([dictionary objectForKey:@"l_name"] != nil) ? ([[dictionary objectForKey:@"l_name"] length] > 0) ? [dictionary objectForKey:@"l_name"] : @"" : @"";
	vo.fullName = [NSString stringWithFormat:([vo.lastName length] > 0) ? @"%@ %@" : @"%@%@", vo.firstName, vo.lastName];
	vo.fullName = ([dictionary objectForKey:@"extern_name"] != nil && [[dictionary objectForKey:@"extern_name"] length] > 0) ? [dictionary objectForKey:@"extern_name"] : vo.fullName;
	vo.avatarData = ([dictionary objectForKey:@"image"] != nil) ? [dictionary objectForKey:@"image"] : nil;
	vo.avatarImage = (vo.avatarData != nil) ? [UIImage imageWithData:vo.avatarData] : nil;
	vo.email = ([dictionary objectForKey:@"email"] != nil) ? [dictionary objectForKey:@"email"] : @"";
	vo.rawNumber = ([dictionary objectForKey:@"phone"] != nil) ? [dictionary objectForKey:@"phone"] : @"";
	
	if ([vo.rawNumber length] > 0) {
		vo.email = @"";
		vo.mobileNumber = [vo.rawNumber normalizedPhoneNumber];
		
	} else
		vo.mobileNumber = @"";
	
	vo.isSMSAvailable = ([vo.mobileNumber length] > 0);
	
	vo.userID = ([dictionary objectForKey:@"id"] == nil) ? 0 : [[dictionary objectForKey:@"id"] intValue];
	vo.username = ([dictionary objectForKey:@"username"] == nil) ? vo.fullName : [dictionary objectForKey:@"username"];
	vo.avatarPrefix = ([dictionary objectForKey:@"avatar_url"] == nil || [[dictionary objectForKey:@"avatar_url"] length] == 0) ? @"" : [dictionary objectForKey:@"avatar_url"];
	vo.contactType = HONContactTypeUnmatched;
	
	vo.invitedDate = [NSDate dateFromOrthodoxFormattedString:[dictionary objectForKey:@"invited"]];
	
	return (vo);
}


+ (HONContactUserVO *)contactFromTrivialUserVO:(HONTrivialUserVO *)trivialUserVO {
	NSString *fName = [[trivialUserVO.username componentsSeparatedByString:@" "] firstObject];
	NSString *lName = ([[[trivialUserVO.username componentsSeparatedByString:@" "] firstObject] isEqualToString:[[trivialUserVO.username componentsSeparatedByString:@" "] lastObject]]) ? @"" : [[trivialUserVO.username componentsSeparatedByString:@" "] lastObject];

	NSDictionary *dict = @{@"id"			: @(trivialUserVO.userID),
						   @"f_name"		: fName,
						   @"l_name"		: lName,
						   @"username"		: trivialUserVO.username,
						   @"avatar_url"	: trivialUserVO.avatarPrefix,
						   @"extern_name"	: ([trivialUserVO.username length] > 0) ? trivialUserVO.username : ([lName length] == 0) ? fName : [NSString stringWithFormat:@"%@ %@", fName, lName],
						   @"email"			: ([trivialUserVO.altID isValidEmailAddress]) ? trivialUserVO.altID : @"",
						   @"phone"			: (![trivialUserVO.altID isValidEmailAddress]) ? trivialUserVO.altID : @"",
						   @"image"			: UIImageJPEGRepresentation([[HONImageBroker sharedInstance] defaultAvatarImageAtSize:kSnapLargeSize], [HONAppDelegate compressJPEGPercentage]),
						   @"invited"		: [trivialUserVO.invitedDate formattedISO8601StringUTC]};
	
	return ([HONContactUserVO contactWithDictionary:dict]);
}


- (void)dealloc {
	self.dictionary = nil;
	self.firstName = nil;
	self.lastName = nil;
	self.fullName = nil;
	self.mobileNumber = nil;
	self.email = nil;
	self.avatarData = nil;
	self.avatarImage = nil;
	
	self.username = nil;
	self.avatarPrefix = nil;
}

@end
