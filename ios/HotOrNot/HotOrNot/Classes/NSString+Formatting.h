//
//  NSString+Formatting.h
//  HotOrNot
//
//  Created by BIM  on 10/30/14.
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

@interface NSString (Formatting)
- (BOOL)isValidEmailAddress;
- (NSString *)stringByTrimmingFinalSubstring:(NSString *)substring;
- (void)trimFinalSubstring:(NSString *)substring;
- (NSString *)normalizedPhoneNumber;
- (NSDictionary *)parseAsQueryString;
- (BOOL)isDelimitedByString:(NSString *)delimiter;
- (NSString *)stringFromAPNSToken:(NSData *)remoteToken;
@end
