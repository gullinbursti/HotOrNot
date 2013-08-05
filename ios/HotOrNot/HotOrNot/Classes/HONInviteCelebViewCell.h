//
//  HONInviteCelebViewCell.h
//  HotOrNot
//
//  Created by Matthew Holcombe on 05.27.13.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HONInviteCelebViewCell : UITableViewCell
+ (NSString *)cellReuseIdentifier;

- (void)setContents:(NSDictionary *)dict;
@end