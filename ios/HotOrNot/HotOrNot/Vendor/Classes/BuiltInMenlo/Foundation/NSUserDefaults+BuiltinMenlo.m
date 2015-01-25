//
//  NSUserDefaults+NullReplacement.h
//  HotOrNot
//
//  Created by BIM  on 10/30/14.
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "NSMutableDictionary+Replacements.h"

@interface NSUserDefaults (Replacements)
- (BOOL)hasObjectForKey:(NSString *)key;

- (void)addObject:(id)object forKey:(NSString *)key;
- (void)defineObject:(id)object forKey:(NSString *)key;
//- (BOOL)hasObjectForKey:(NSString *)key;
- (void)replaceObject:(id)object forKey:(NSString *)key;
- (void)swapObjectForKey:(NSString *)keyA withKey:(NSString *)keyB;
- (void)addObjects:(NSArray *)objects withKeys:(NSArray *)keys;
- (void)purgeObjectsWithKeys:(NSArray *)keys;
- (void)replaceObjects:(NSArray *)objects withKeys:(NSArray *)keys;

@end//
//  NSUserDefaults+NullReplacement.m
//  HotOrNot
//
//  Created by BIM  on 10/30/14.
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "NSUserDefaults+Replacements.h"

@implementation NSUserDefaults (Replacements)

- (void)addObject:(id)object forKey:(NSString *)key {
	if ([[NSUserDefaults standardUserDefaults] objectForKey:key] == nil)
		[[NSUserDefaults standardUserDefaults] setValue:object forKey:key];
		
	else
		[[NSUserDefaults standardUserDefaults] replaceObject:object forKey:key];
}

- (void)defineObject:(id)object forKey:(NSString *)key {
	if ([self objectForKey:key] == nil)
		[self setObject:object forKey:key];

	else
		[self replaceObject:object forKey:key];
}

- (BOOL)hasObjectForKey:(NSString *)key {
	return ([self objectForKey:key] != nil);
}

- (void)replaceObject:(id)object forKey:(NSString *)key {
	if ([self objectForKey:key] != nil)
		[self removeObjectForKey:key];
	
	[self setValue:object forKey:key];
}

- (void)swapObjectForKey:(NSString *)keyA withKey:(NSString *)keyB {
	id obj = [self objectForKey:keyA];
	[self replaceObject:[self objectForKey:keyB] forKey:keyA];
	[self replaceObject:[self objectForKey:obj] forKey:keyB];
	
	obj = nil;
}

- (void)addObjects:(NSArray *)objects withKeys:(NSArray *)keys {
	[keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[self defineObject:[objects objectAtIndex:idx] forKey:(NSString *)obj];
	}];
}

- (void)purgeObjectsWithKeys:(NSArray *)keys {
	[keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[self removeObjectForKey:(NSString *)obj];
	}];
}

- (void)replaceObjects:(NSArray *)objects withKeys:(NSArray *)keys {
	[keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[self replaceObject:[objects objectAtIndex:idx] forKey:(NSString *)obj];
	}];
}

@end
