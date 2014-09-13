//
//  HONClubViewCell.h
//  HotOrNot
//
//  Created by BIM  on 8/30/14.
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "HONTableViewCell.h"
#import "HONUserClubVO.h"

typedef NS_ENUM(NSInteger, HONClubViewCellType) {
	HONClubViewCellTypeCreate = 0,
	HONClubViewCellTypeUserSignup,
	HONClubViewCellTypeOwner,
	HONClubViewCellTypeMember,
	HONClubViewCellTypeInvite
};

@class HONClubViewCell;
@protocol HONClubViewCellDelegate <NSObject>
- (void)clubViewCell:(HONClubViewCell *)viewCell selectedClub:(HONUserClubVO *)clubVO;
@end

@interface HONClubViewCell : HONTableViewCell
+ (NSString *)cellReuseIdentifier;
- (id)initAsCellType:(HONClubViewCellType)cellType;
- (void)toggleImageLoading:(BOOL)isLoading;

@property (nonatomic, retain) HONContactUserVO *contactUserVO;
@property (nonatomic, retain) HONTrivialUserVO *trivialUserVO;
@property (nonatomic, retain) HONClubPhotoVO *statusUpdateVO;
@property (nonatomic, retain) HONUserClubVO *clubVO;
@property (nonatomic, assign) HONClubViewCellType cellType;
@property (nonatomic, assign) id <HONClubViewCellDelegate> delegate;
@end
