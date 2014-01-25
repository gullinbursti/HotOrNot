//
//  HONVerifyViewController.h
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.06.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	HONVerifyAlertTypeShare = 0,
	HONVerifyAlertTypeDisproveConfirm,
} HONVerifyAlertType;


@interface HONVerifyViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
@end
