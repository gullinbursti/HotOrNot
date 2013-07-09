//
//  HONCelebVO.m
//  HotOrNot
//
//  Created by Matt Holcombe on 7/8/13 @ 4:05 PM.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import "HONCelebVO.h"

@implementation HONCelebVO
@synthesize dictionary;
@synthesize fullName, username, avatarURL;

+ (HONCelebVO *)celebWithDictionary:(NSDictionary *)dictionary {
	HONCelebVO *vo = [[HONCelebVO alloc] init];
	vo.dictionary = dictionary;
	
	vo.fullName = [dictionary objectForKey:@"full_name"];
	vo.username = [dictionary objectForKey:@"username"];
	vo.avatarURL = [dictionary objectForKey:@"avatar_url"];
	
	return (vo);
}

- (void)dealloc {
	self.dictionary = nil;
	self.fullName = nil;
	self.username = nil;
	self.avatarURL = nil;
}

@end
