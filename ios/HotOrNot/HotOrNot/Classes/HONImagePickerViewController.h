//
//  HONImagePickerViewController.h
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.09.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HONChallengeVO.h"
#import "HONUserVO.h"

const CGFloat kFocusInterval;

@interface HONImagePickerViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
- (id)initWithUser:(HONUserVO *)userVO;
- (id)initWithSubject:(NSString *)subject;
- (id)initWithUser:(HONUserVO *)userVO withSubject:(NSString *)subject;
- (id)initWithChallenge:(HONChallengeVO *)vo;
@end
