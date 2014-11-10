//
//  HONContactsTabViewController.h
//  HotOrNot
//
//  Created by Matt Holcombe on 03/26/2014 @ 18:21 .
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
//#import <MapKit/MapKit.h>

#import "HONViewController.h"
#import "HONUserClubVO.h"

@interface HONContactsTabViewController : HONViewController <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@end
