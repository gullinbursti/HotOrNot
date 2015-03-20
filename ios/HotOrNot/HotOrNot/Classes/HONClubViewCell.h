//
//  HONClubViewCell.h
//  HotOrNot
//
//  Created by BIM  on 8/30/14.
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "HONToggleLEDViewCell.h"
#import "HONUserClubVO.h"

typedef NS_ENUM(NSUInteger, HONClubViewCellType) {
	HONClubViewCellTypeBlank = 0,
	HONClubViewCellTypeDeviceContact,
	HONClubViewCellTypeInAppUser,
	HONClubViewCellTypeCreate,
	HONClubViewCellTypeUserSignup,
	HONClubViewCellTypeOwner,
	HONClubViewCellTypeMember,
	HONClubViewCellTypeInvite
};

@class HONClubViewCell;
@protocol HONClubViewCellDelegate <HONToggleLEDViewCellDelegate>
@optional
- (void)clubViewCell:(HONClubViewCell *)viewCell didSelectClub:(HONUserClubVO *)clubVO;
- (void)clubViewCell:(HONClubViewCell *)viewCell didSelectContactUser:(HONContactUserVO *)contactUserVO;
- (void)clubViewCell:(HONClubViewCell *)viewCell didSelectUser:(HONUserVO *)userVO;
@end

@interface HONClubViewCell : HONToggleLEDViewCell
+ (NSString *)cellReuseIdentifier;
- (id)initAsCellType:(HONClubViewCellType)cellType;
- (void)toggleImageLoading:(BOOL)isLoading;
- (void)hideTimeStat;
- (void)prependTitleCaption:(NSString *)captionPrefix;
- (void)appendTitleCaption:(NSString *)captionSuffix;
- (void)addSubtitleCaption:(NSString *)caption;

@property (nonatomic, retain) NSString *caption;
@property (nonatomic, retain) HONContactUserVO *contactUserVO;
@property (nonatomic, retain) HONUserVO *userVO;
@property (nonatomic, retain) HONUserClubVO *clubVO;
@property (nonatomic, retain) HONClubPhotoVO *statusUpdateVO;
@property (nonatomic, assign) HONClubViewCellType cellType;
@property (nonatomic, assign) id <HONClubViewCellDelegate> delegate;
@end
