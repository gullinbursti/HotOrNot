//
//  PubNub+BuiltInMenlo.h
//  HotOrNot
//
//  Created by BIM  on 3/18/15.
//  Copyright (c) 2015 Built in Menlo, LLC. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "PNImports.h"


typedef NS_ENUM(NSUInteger, HONChatMessageType) {
	HONChatMessageTypeUndetermined = 0,
	HONChatMessageTypeUndefined,
	HONChatMessageTypeSYN,
	HONChatMessageTypeACK,
	HONChatMessageTypeAUT,
	HONChatMessageTypeBOT,
	HONChatMessageTypeTXT,
	HONChatMessageTypeIMG,
	HONChatMessageTypeBYE,
	HONChatMessageTypeFIN,
	HONChatMessageTypeERR,
	HONChatMessageTypeNAE,
	HONChatMessageTypeYAH,
	HONChatMessageTypeQRY,
	HONChatMessageTypeANS,
	HONChatMessageTypeNIX,
	HONChatMessageTypeUnknown
};


extern NSString * const kHONChatMessageTypeKey;
extern NSString * const kHONChatMessageTypeUndeterminedKey;
extern NSString * const kHONChatMessageTypeUndefinedKey;
extern NSString * const kHONHONChatMessageTypeSyncronizeKey;
extern NSString * const kHONChatMessageTypeAcknowledgeKey;
extern NSString * const kHONChatMessageTypeAutomatedKey;
extern NSString * const kHONChatMessageTypeBotKey;
extern NSString * const kHONHONChatMessageTypeTXTKey;
extern NSString * const kHONHONChatMessageTypeIMGKey;
extern NSString * const kHONChatMessageTypeLeaveKey;
extern NSString * const kHONChatMessageTypeCompleteKey;
extern NSString * const kHONChatMessageTypeErrorKey;
extern NSString * const kHONChatMessageTypeNegativeKey;
extern NSString * const kHONChatMessageTypeAffirmativeKey;
extern NSString * const kHONChatMessageTypeQueryKey;
extern NSString * const kHONChatMessageTypeAnswerKey;
extern NSString * const kHONChatMessageTypeDeleteKey;
extern NSString * const kHONChatMessageTypeUnknownKey;

extern NSString * const kHONChatMessageCoordsRoot;
extern NSString * const kHONChatMessageImageRoot;


@interface PubNub (BuiltInMenlo)
@end


@interface PNChannel (BuiltInMenlo)
@end


@interface PNMessage (BuiltInMenlo)
//+ (NSString *)messageFromOriginID:(int)originID atLocation:(CLLocation *)location ofType:(HONChatMessageType)msgType withContents:(NSString *)contents;
//+ (instancetype)messageAtLocation:(CLLocation *)location ofType:(HONChatMessageType)msgType withContents:(NSString *)contents;
//+ (instancetype)messageOfType:(HONChatMessageType)msgType withContents:(NSString *)contents;
//

+ (NSString *)formattedCoordsForDeviceLocation;
+ (NSString *)formattedCoordsForLocation:(CLLocation *)location;
+ (NSString *)keyForMessageType:(HONChatMessageType)messageType;
+ (PNMessage *)publishSynchronizeMessageOnChannel:(PNChannel *)channel withCompletion:(PNClientMessageProcessingBlock)success;

- (NSString *)coordsURI;
- (NSString *)imageURLPrefix;
- (CLLocation *)location;
- (HONChatMessageType)messageType;
- (int)originUserID;
- (NSString *)originUsername;
- (NSString *)contents;
@end
