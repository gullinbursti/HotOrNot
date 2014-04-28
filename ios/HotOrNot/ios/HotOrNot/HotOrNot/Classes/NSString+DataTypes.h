//
//  NSString+DataTypes.h
//  HotOrNot
//
//  Created by Matt Holcombe on 04/23/2014.
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DataTypes)
unsigned long long unistrlen(unichar *chars);


- (id)initWithInt:(int)intVal;

- (NSString *)stringFromBOOL:(BOOL)boolVal;
- (NSString *)stringFromCGFloat:(CGFloat)floatVal;
- (NSString *)stringFromDouble:(double)doubleVal;
- (NSString *)stringFromFloat:(float)floatVal;
- (NSString *)stringFromInt:(int)intVal;
- (NSString *)stringFromHex:(unichar *)hexVal;
@end