//
//  HONChallengeViewCell.h
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.07.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HONGenericRowViewCell.h"
#import "HONChallengeVO.h"

@interface HONChallengeViewCell : HONGenericRowViewCell
+ (NSString *)cellReuseIdentifier;

- (id)initAsLoadMoreCell:(BOOL)isMoreLoadable;
- (void)toggleLoadMore:(BOOL)isEnabled;
- (void)updateHasSeen;

@property (nonatomic, strong) HONChallengeVO *challengeVO;
@end
