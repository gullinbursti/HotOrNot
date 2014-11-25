//
//  NSDictionary+Replacements.h
//  HotOrNot
//
//  Created by BIM  on 10/30/14.
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

@interface NSMutableDictionary (Replacements)
- (void)defineObject:(id)object forUnknownKey:(NSString *)key;
- (BOOL)hasObjectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (void)replaceObject:(id)object forKey:(NSString *)key;
//- (void)swapObjectsForKeys:(const id [])keys;
- (void)swapObjectForKey:(NSString *)keyA withKey:(NSString *)keyB;
@end
