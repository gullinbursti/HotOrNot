//
//  HONImagePickerViewController.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.09.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import <AWSiOSSDK/S3/AmazonS3Client.h>

#import "ASIFormDataRequest.h"
#import "MBProgressHUD.h"

#import "HONImagePickerViewController.h"
#import "HONAppDelegate.h"
#import "HONImageTypeViewCell.h"

@interface HONImagePickerViewController () <ASIHTTPRequestDelegate>
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSMutableArray *imageSources;
@property(nonatomic, strong) NSString *subjectName;
@property(nonatomic, strong) HONChallengeVO *challengeVO;
@property(nonatomic, strong) MBProgressHUD *progressHUD;
@property(nonatomic, strong) NSString *fbID;
@property(nonatomic) int submitAction;
@property(nonatomic) int challengerID;
@end

@implementation HONImagePickerViewController

@synthesize tableView = _tableView;
@synthesize imageSources = _imageSources;
@synthesize subjectName = _subjectName;
@synthesize submitAction = _submitAction;
@synthesize challengeVO = _challengeVO;
@synthesize progressHUD = _progressHUD;
@synthesize fbID = _fbID;
@synthesize challengerID = _challengerID;

- (id)initWithSubject:(NSString *)subject {
	if ((self = [super init])) {
		self.title = NSLocalizedString(@"Select Image", @"Select Image");
		self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
		
		self.subjectName = subject;
		
		self.imageSources = [NSMutableArray new];
		[self.imageSources addObject:@"Camera"];
		[self.imageSources addObject:@"Camera Roll"];
		[self.imageSources addObject:@"Photo Stream"];
		[self.imageSources addObject:@"Facebook"];
		
		self.submitAction = 1;
	}
	
	return (self);
}

- (id)initWithSubject:(NSString *)subject withFriendID:(NSString *)fbID {
	if ((self = [super init])) {
		self.title = NSLocalizedString(@"Select Image", @"Select Image");
		self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
		
		self.subjectName = subject;
		self.fbID = fbID;
		
		self.imageSources = [NSMutableArray new];
		[self.imageSources addObject:@"Camera"];
		[self.imageSources addObject:@"Camera Roll"];
		[self.imageSources addObject:@"Photo Stream"];
		[self.imageSources addObject:@"Facebook"];
		
		self.submitAction = 8;
		
	}
	
	return (self);
}

- (id)initWithChallenge:(HONChallengeVO *)vo {
	if ((self = [super init])) {
		self.title = NSLocalizedString(@"Select Image", @"Select Image");
		self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
		
		self.challengeVO = vo;
		self.subjectName = vo.subjectName;
		
		self.imageSources = [NSMutableArray new];
		[self.imageSources addObject:@"Camera"];
		[self.imageSources addObject:@"Camera Roll"];
		[self.imageSources addObject:@"Photo Stream"];
		[self.imageSources addObject:@"Facebook"];
		
		self.submitAction = 4;
	}
	
	return (self);
}

- (id)initWithSubject:(NSString *)subject withUser:(int)userID {
	if ((self = [super init])) {
		self.title = NSLocalizedString(@"Select Image", @"Select Image");
		self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
		
		self.subjectName = subject;
		_challengerID = userID;
		
		self.imageSources = [NSMutableArray new];
		[self.imageSources addObject:@"Camera"];
		[self.imageSources addObject:@"Camera Roll"];
		[self.imageSources addObject:@"Photo Stream"];
		[self.imageSources addObject:@"Facebook"];
		
		self.submitAction = 9;
	}
	
	return (self);
}

#pragma mark - View lifecycle
- (void)loadView {
	[super loadView];
	
	self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
	[self.tableView setBackgroundColor:[UIColor clearColor]];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.rowHeight = 56.0;
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.userInteractionEnabled = YES;
	self.tableView.scrollsToTop = NO;
	self.tableView.showsVerticalScrollIndicator = YES;
	[self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate {
	return (NO);
}

#pragma mark - TableView DataSource Delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ([self.imageSources count]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	HONImageTypeViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
	
	if (cell == nil) {
		cell = [[HONImageTypeViewCell alloc] init];
	}
	
	[cell setCaption:[self.imageSources objectAtIndex:indexPath.row]];
	[cell setTotal:arc4random() % 100];
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	
	return (cell);
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return (56.0);
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return (indexPath);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
	ASIFormDataRequest *submitChallengeRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", kServerPath, kChallengesAPI]]];
	
	switch (indexPath.row) {
		case 0:
			if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"COMPOSE_SOURCE_CAMERA" object:nil];
				
				UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
				imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
				imagePicker.delegate = self;
				imagePicker.allowsEditing = YES;
				
				[self.navigationController presentViewController:imagePicker animated:YES completion:nil];
				
			} else {
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Camera not aviable." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
				[alertView show];
			}
			break;
			
		case 1:
			if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"COMPOSE_SOURCE_CAMERAROLL" object:nil];
				
				UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
				imagePicker.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
				imagePicker.delegate = self;
				imagePicker.allowsEditing = YES;
				//imagePicker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
				
				[self.navigationController presentViewController:imagePicker animated:YES completion:nil];
				
			} else {
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Photo roll not available." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
				[alertView show];
			}
			break;
			
		case 2:
			break;
			
		case 3:
			[submitChallengeRequest setDelegate:self];
			[submitChallengeRequest setPostValue:[NSString stringWithFormat:@"%d", self.submitAction] forKey:@"action"];
			[submitChallengeRequest setPostValue:[[HONAppDelegate infoForUser] objectForKey:@"id"] forKey:@"userID"];
			[submitChallengeRequest setPostValue:@"" forKey:@"imgURL"];
			
			if (self.submitAction == 1)
				[submitChallengeRequest setPostValue:self.subjectName forKey:@"subject"];
			
			else if (self.submitAction == 4)
				[submitChallengeRequest setPostValue:[NSString stringWithFormat:@"%d", self.challengeVO.challengeID] forKey:@"challengeID"];
			
			else if (self.submitAction == 8) {
				[submitChallengeRequest setPostValue:self.subjectName forKey:@"subject"];
				[submitChallengeRequest setPostValue:self.fbID forKey:@"fbID"];
			
			} else if (self.submitAction == 9) {
				[submitChallengeRequest setPostValue:self.subjectName forKey:@"subject"];
				[submitChallengeRequest setPostValue:[NSString stringWithFormat:@"%d", self.challengerID] forKey:@"challengerID"];
			}
			
			[submitChallengeRequest startAsynchronous];
			break;
	}
}

#pragma mark - ImagePicker Delegates
-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	UIImage *image = [HONAppDelegate scaleImage:[info objectForKey:UIImagePickerControllerOriginalImage] toSize:CGSizeMake(480.0, 360.0)];
	[self dismissViewControllerAnimated:YES completion:nil];
	
	NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
	AmazonS3Client *s3 = [[AmazonS3Client alloc] initWithAccessKey:@"AKIAJVS6Y36AQCMRWLQQ" withSecretKey:@"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"];
	
	NSString *filename = [NSString stringWithFormat:@"%@.jpg", [[NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970]] stringValue]];
	NSLog(@"https://hotornot-challenges.s3.amazonaws.com/%@", filename);
	
	@try {
		_progressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
		_progressHUD.labelText = @"Submitting Challenge…";
		_progressHUD.mode = MBProgressHUDModeIndeterminate;
		_progressHUD.graceTime = 2.0;
		_progressHUD.taskInProgress = YES;
		
		[s3 createBucket:[[S3CreateBucketRequest alloc] initWithName:@"hotornot-challenges"]];
		S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:filename inBucket:@"hotornot-challenges"];
		por.contentType = @"image/jpeg";
		por.data = imageData;
		[s3 putObject:por];
		
		ASIFormDataRequest *submitChallengeRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", kServerPath, kChallengesAPI]]];
		[submitChallengeRequest setDelegate:self];
		[submitChallengeRequest setPostValue:[NSString stringWithFormat:@"%d", self.submitAction] forKey:@"action"];
		[submitChallengeRequest setPostValue:[[HONAppDelegate infoForUser] objectForKey:@"id"] forKey:@"userID"];
		[submitChallengeRequest setPostValue:[NSString stringWithFormat:@"https://hotornot-challenges.s3.amazonaws.com/%@", filename] forKey:@"imgURL"];
		
		if (self.submitAction == 1)
			[submitChallengeRequest setPostValue:self.subjectName forKey:@"subject"];
		
		else if (self.submitAction == 4)
			[submitChallengeRequest setPostValue:[NSString stringWithFormat:@"%d", self.challengeVO.challengeID] forKey:@"challengeID"];
		
		else if (self.submitAction == 8) {
			[submitChallengeRequest setPostValue:self.subjectName forKey:@"subject"];
			[submitChallengeRequest setPostValue:self.fbID forKey:@"fbID"];
		
		} else if (self.submitAction == 9) {
			[submitChallengeRequest setPostValue:self.subjectName forKey:@"subject"];
			[submitChallengeRequest setPostValue:[NSString stringWithFormat:@"%d", self.challengerID] forKey:@"challengerID"];
		}
		
		[submitChallengeRequest startAsynchronous];
		
	} @catch (AmazonClientException *exception) {
		[[[UIAlertView alloc] initWithTitle:@"Upload Error" message:exception.message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
	}
}

#pragma mark - ASI Delegates
-(void)requestFinished:(ASIHTTPRequest *)request {
	NSLog(@"HONImagePickerViewController [_asiFormRequest responseString]=\n%@\n\n", [request responseString]);
	
	@autoreleasepool {
		_progressHUD.taskInProgress = NO;
		
		NSError *error = nil;
		//NSDictionary *challengeResult = [NSJSONSerialization JSONObjectWithData:[request responseData] options:0 error:&error];
		
		if (error != nil) {
			NSLog(@"Failed to parse job list JSON: %@", [error localizedFailureReason]);
			_progressHUD.graceTime = 0.0;
			_progressHUD.mode = MBProgressHUDModeCustomView;
			_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error.png"]];
			_progressHUD.labelText = NSLocalizedString(@"Download Failed", @"Status message when downloading fails");
			[_progressHUD show:NO];
			[_progressHUD hide:YES afterDelay:1.5];
			_progressHUD = nil;
		}
		
		else {
			[_progressHUD hide:YES];
			_progressHUD = nil;
			
			[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:YES completion:nil];
			[self.navigationController dismissViewControllerAnimated:YES completion:nil];
		}
	}
}

-(void)requestFailed:(ASIHTTPRequest *)request {
	NSLog(@"requestFailed:\n[%@]", request.error);
}


@end
