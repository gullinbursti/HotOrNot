//
//  HONAlertsViewController.h
//  HotOrNot
//
//  Created by Matt Holcombe on 12/02/2013 @ 20:17 .
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
	HONAlertCellTypeVerify = 1,
	HONAlertCellTypeFollow,
	HONAlertCellTypeLike,
	HONAlertCellTypeShoutout,
	HONAlertCellTypeReply
} HONAlertCellType;





@interface HONAlertsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@end