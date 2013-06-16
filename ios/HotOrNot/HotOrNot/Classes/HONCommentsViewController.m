//
//  HONCommentsViewController.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 02.20.13.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "MBProgressHUD.h"

#import "HONCommentsViewController.h"
#import "HONAppDelegate.h"
#import "HONHeaderView.h"
#import "HONGenericRowViewCell.h"
#import "HONCommentViewCell.h"
#import "HONCommentVO.h"
#import "HONImagePickerViewController.h"

@interface HONCommentsViewController () <UIAlertViewDelegate, UITextFieldDelegate>
@property (nonatomic, strong) HONChallengeVO *challengeVO;
@property (nonatomic, strong) HONCommentVO *commentVO;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, strong) HONHeaderView *headerView;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, strong) UIImageView *bgTextImageView;
@property (nonatomic, strong) UITextField *commentTextField;
@property (nonatomic, strong) NSIndexPath *idxPath;
@property (nonatomic) BOOL isGoingBack;
@end

@implementation HONCommentsViewController

- (id)initWithChallenge:(HONChallengeVO *)vo {
	if ((self = [super init])) {
		_challengeVO = vo;
		_isGoingBack = NO;
		
		self.view.backgroundColor = [UIColor whiteColor];
		self.comments = [NSMutableArray new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_userChallenge:) name:@"USER_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tabsDropped:) name:@"TABS_DROPPED" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tabsRaised:) name:@"TABS_RAISED" object:nil];
	}
	
	return (self);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)dealloc {
	
}

- (BOOL)shouldAutorotate {
	return (NO);
}


#pragma mark - Data Calls
- (void)_retrieveComments {
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:@"%d", 1], @"action",
									[NSString stringWithFormat:@"%d", _challengeVO.challengeID], @"challengeID",
									nil];
	
	[httpClient postPath:kAPIComments parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		if (error != nil) {
			NSLog(@"HONCommentsViewController AFNetworking - Failed to parse job list JSON: %@", [error localizedFailureReason]);
			
		} else {
			NSArray *parsedLists = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
			
			//NSLog(@"HONCommentsViewController AFNetworking: %@", parsedLists);
			_comments = [NSMutableArray new];
			for (NSDictionary *serverList in parsedLists) {
				HONCommentVO *vo = [HONCommentVO commentWithDictionary:serverList];
				
				if (vo != nil)
					[_comments addObject:vo];
			}
			
			if ([_comments count] > 0) {
				[_tableView reloadData];
				[_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[_comments count] - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
			}
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"HONCommentsViewController AFNetworking %@", [error localizedDescription]);
	}];
}

- (void)_submitComment {
	[[Mixpanel sharedInstance] track:@"Timeline Comments - Submit"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
												 [NSString stringWithFormat:@"%d - %@", _challengeVO.challengeID, _challengeVO.subjectName], @"challenge",
												 _commentTextField.text, @"comment", nil]];
	
	_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
	_progressHUD.labelText = NSLocalizedString(@"hud_submitComment", nil);
	_progressHUD.mode = MBProgressHUDModeIndeterminate;
	_progressHUD.minShowTime = kHUDTime;
	_progressHUD.taskInProgress = YES;
	
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:@"%d", 2], @"action",
									[NSString stringWithFormat:@"%d", _challengeVO.challengeID], @"challengeID",
									[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
									_commentTextField.text, @"text",
									nil];
	
	[httpClient postPath:kAPIComments parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		if (error != nil) {
			NSLog(@"HONCommentsViewController AFNetworking - Failed to parse job list JSON: %@", [error localizedFailureReason]);
			_progressHUD.minShowTime = kHUDTime;
			_progressHUD.mode = MBProgressHUDModeCustomView;
			_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
			_progressHUD.labelText = NSLocalizedString(@"hud_dlFailed", nil);
			[_progressHUD show:NO];
			[_progressHUD hide:YES afterDelay:1.5];
			_progressHUD = nil;
			
		} else {
			//NSDictionary *commentResult = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
			
			[_progressHUD hide:YES];
			_progressHUD = nil;
			
			[self _retrieveComments];
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"HONCommentsViewController AFNetworking %@", [error localizedDescription]);
		
		if (_progressHUD == nil)
			_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
		_progressHUD.minShowTime = kHUDTime;
		_progressHUD.mode = MBProgressHUDModeCustomView;
		_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		_progressHUD.labelText = NSLocalizedString(@"hud_connectionError", nil);
		[_progressHUD show:NO];
		[_progressHUD hide:YES afterDelay:1.5];
		_progressHUD = nil;
	}];
}


#pragma mark - View Lifecycle
- (void)loadView {
	[super loadView];
	
	UIImageView *bgImgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
	bgImgView.image = [UIImage imageNamed:([HONAppDelegate isRetina5]) ? @"mainBG-568h@2x" : @"mainBG"];
	[self.view addSubview:bgImgView];
	
	_headerView = [[HONHeaderView alloc] initWithTitle:_challengeVO.subjectName];
	[self.view addSubview:_headerView];
	
	UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
	backButton.frame = CGRectMake(3.0, 0.0, 64.0, 44.0);
	[backButton setBackgroundImage:[UIImage imageNamed:@"backButton_nonActive"] forState:UIControlStateNormal];
	[backButton setBackgroundImage:[UIImage imageNamed:@"backButton_Active"] forState:UIControlStateHighlighted];
	[backButton addTarget:self action:@selector(_goBack) forControlEvents:UIControlEventTouchUpInside];
	[_headerView addSubview:backButton];
	
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, kNavBarHeaderHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - (kNavBarHeaderHeight + 81.0)) style:UITableViewStylePlain];
	[_tableView setBackgroundColor:[UIColor clearColor]];
	_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	_tableView.rowHeight = 70.0;
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.userInteractionEnabled = YES;
	_tableView.scrollsToTop = NO;
	_tableView.showsVerticalScrollIndicator = YES;
	[self.view addSubview:_tableView];
	
	_bgTextImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, [UIScreen mainScreen].bounds.size.height - 42.0, 320.0, 42.0)];
	_bgTextImageView.backgroundColor = [UIColor redColor];
	_bgTextImageView.image = [UIImage imageNamed:@"commentsInputField_nonActive.jpg"];
	_bgTextImageView.userInteractionEnabled = YES;
	[self.view addSubview:_bgTextImageView];
	
	_commentTextField = [[UITextField alloc] initWithFrame:CGRectMake(10.0, 13.0, 300.0, 26.0)];
	//[_commentTextField setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[_commentTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
	[_commentTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
	_commentTextField.keyboardAppearance = UIKeyboardAppearanceDefault;
	[_commentTextField setReturnKeyType:UIReturnKeySend];
	[_commentTextField setTextColor:[HONAppDelegate honGrey518Color]];
	[_commentTextField addTarget:self action:@selector(_onTxtDoneEditing:) forControlEvents:UIControlEventEditingDidEndOnExit];
	_commentTextField.font = [[HONAppDelegate helveticaNeueFontMedium] fontWithSize:12];
	_commentTextField.keyboardType = UIKeyboardTypeDefault;
	_commentTextField.text = @"";
	_commentTextField.delegate = self;
	[_commentTextField setTag:0];
	[_bgTextImageView addSubview:_commentTextField];
	
	UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
	sendButton.frame = CGRectMake(256.0, -1.0, 64.0, 44.0);
	[sendButton setBackgroundImage:[UIImage imageNamed:@"sendButton_nonActive"] forState:UIControlStateNormal];
	[sendButton setBackgroundImage:[UIImage imageNamed:@"shareButton_Active"] forState:UIControlStateHighlighted];
	[sendButton addTarget:self action:@selector(_goSend) forControlEvents:UIControlEventTouchUpInside];
	[_bgTextImageView addSubview:sendButton];
	
	[self _retrieveComments];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	//[_commentTextField becomeFirstResponder];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.0];
	[UIView setAnimationDelay:0.0];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[_commentTextField becomeFirstResponder];  // <---- Only edit this line
	[UIView commitAnimations];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"USER_CHALLENGE" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}


#pragma mark - Navigation
- (void)_goBack {
	[[Mixpanel sharedInstance] track:@"Timeline Comments - Back"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
												 [NSString stringWithFormat:@"%d - %@", _challengeVO.challengeID, _challengeVO.subjectName], @"challenge", nil]];
	
	_isGoingBack = YES;
	//[_commentTextField resignFirstResponder];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.0];
	[UIView setAnimationDelay:0.0];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[_commentTextField resignFirstResponder];  // <---- Only edit this line
	[UIView commitAnimations];
	
	//[UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^(void){
	//	_bgTextImageView.frame = CGRectMake(_bgTextImageView.frame.origin.x, [UIScreen mainScreen].bounds.size.height - _bgTextImageView.frame.size.height, _bgTextImageView.frame.size.width, _bgTextImageView.frame.size.height);
	//
	//} completion:^(BOOL finished) {
		_commentTextField.text = @"";
		[self.navigationController popViewControllerAnimated:YES];
	//}];
}

- (void)_goSend {
	if ([_commentTextField.text length] > 0) {
		[self _submitComment];
		_commentTextField.text = @"";
	}
}


#pragma mark - Notifications
- (void)_userChallenge:(NSNotification *)notification {
	NSLog(@"USER_CHALLENGE");
	_commentVO = (HONCommentVO *)[notification object];
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Challenge User"
																		 message:[NSString stringWithFormat:@"Want to %@ challenge %@?", _challengeVO.subjectName, _commentVO.username]
																		delegate:self
															cancelButtonTitle:@"Yes"
															otherButtonTitles:@"No", nil];
	[alertView show];
}

- (void)_tabsDropped:(NSNotification *)notification {
	_tableView.frame = CGRectMake(0.0, kNavBarHeaderHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - (kNavBarHeaderHeight + 29.0));
}

- (void)_tabsRaised:(NSNotification *)notification {
	_tableView.frame = CGRectMake(0.0, kNavBarHeaderHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - (kNavBarHeaderHeight + 81.0));
}


#pragma mark - TableView DataSource Delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ([_comments count]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	HONCommentViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
	
	if (cell == nil)
		cell = [[HONCommentViewCell alloc] init];
	
	cell.commentVO = [_comments objectAtIndex:indexPath.row];
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	
	return (cell);
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return (kOrthodoxTableCellHeight);
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	_commentVO = (HONCommentVO *)[_comments objectAtIndex:indexPath.row];
	
	if (_commentVO.userID == [[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue])
		return (nil);
	
	else
		return (indexPath);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//[(HONVoterViewCell *)[tableView cellForRowAtIndexPath:indexPath] didSelect];
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
	
	
	_commentVO = (HONCommentVO *)[_comments objectAtIndex:indexPath.row];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Challenge User"
																		 message:[NSString stringWithFormat:@"Want to %@ challenge %@?", _challengeVO.subjectName, _commentVO.username]
																		delegate:self
															cancelButtonTitle:@"Yes"
															otherButtonTitles:@"No", nil];
	[alertView setTag:1];
	[alertView show];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	_commentVO = (HONCommentVO *)[_comments objectAtIndex:indexPath.row];
	return (_commentVO.userID == [[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue]);
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		_idxPath = indexPath;
		
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete Comment"
																			 message:@"Do you want to remove this comment?"
																			delegate:self
																cancelButtonTitle:@"Yes"
																otherButtonTitles:@"No", nil];
		[alertView setTag:0];
		[alertView show];
	}
}


#pragma mark - TextField Delegates
-(void)textFieldDidBeginEditing:(UITextField *)textField {
	//[UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^(void) {
		_bgTextImageView.frame = CGRectMake(_bgTextImageView.frame.origin.x, [UIScreen mainScreen].bounds.size.height - 278.0, _bgTextImageView.frame.size.width, _bgTextImageView.frame.size.height);
	//} completion:^(BOOL finished) {
	//}];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if ([textField.text length] > 35 && ![string isEqualToString:@""]) {
		textField.text = [textField.text substringToIndex:35];
		
		return (NO);
	}
	
	return (YES);
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	return (YES);
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
	
	if (!_isGoingBack) {
		//[textField becomeFirstResponder];
		
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.0];
		[UIView setAnimationDelay:0.0];
		[UIView setAnimationCurve:UIViewAnimationCurveLinear];
		[textField becomeFirstResponder];  // <---- Only edit this line
		[UIView commitAnimations];
	}
}

- (void)_onTxtDoneEditing:(id)sender {
	//[_commentTextField becomeFirstResponder];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.0];
	[UIView setAnimationDelay:0.0];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[_commentTextField becomeFirstResponder];  // <---- Only edit this line
	[UIView commitAnimations];
	
	[self _goSend];
}

#pragma mark - AlerView Delegates
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	UINavigationController *navigationController;
	
	if (alertView.tag == 0) {
		switch(buttonIndex) {
			case 0: {
				[[Mixpanel sharedInstance] track:@"Challenge Wall - Delete"
											 properties:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
															 [NSString stringWithFormat:@"%d - %@", _commentVO.commentID, _commentVO.content], @"comment", nil]];
				
				[_comments removeObjectAtIndex:_idxPath.row];
				[_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:_idxPath] withRowAnimation:UITableViewRowAnimationFade];
				
				AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
				NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
												[NSString stringWithFormat:@"%d", 8], @"action",
												[NSString stringWithFormat:@"%d", _commentVO.commentID], @"commentID",
												nil];
				
				[httpClient postPath:kAPIComments parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
					NSError *error = nil;
					if (error != nil) {
						NSLog(@"HONCommentsViewController AFNetworking - Failed to parse job list JSON: %@", [error localizedFailureReason]);
						
					} else {
						[self _retrieveComments];
					}
					
				} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
					NSLog(@"HONCommentsViewController AFNetworking %@", [error localizedDescription]);
					
					_progressHUD.minShowTime = kHUDTime;
					_progressHUD.mode = MBProgressHUDModeCustomView;
					_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
					_progressHUD.labelText = NSLocalizedString(@"hud_connectionError", nil);
					[_progressHUD show:NO];
					[_progressHUD hide:YES afterDelay:1.5];
					_progressHUD = nil;
				}];
				break;}
				
			case 1:
				break;
		}
	
	} else if (alertView.tag == 1) {
		switch(buttonIndex) {
			case 0: {
				[[Mixpanel sharedInstance] track:@"Challenge Comments - Create Challenge"
											 properties:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
				
				HONUserVO *userVO = [HONUserVO userWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
																					[NSString stringWithFormat:@"%d", _commentVO.userID], @"id",
																					[NSString stringWithFormat:@"%d", 0], @"points",
																					[NSString stringWithFormat:@"%d", 0], @"votes",
																					[NSString stringWithFormat:@"%d", 0], @"pokes",
																					[NSString stringWithFormat:@"%d", 0], @"pics",
																					_commentVO.username, @"username",
																					_commentVO.fbID, @"fb_id",
																					_commentVO.avatarURL, @"avatar_url", nil]];
				
				navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONImagePickerViewController alloc] initWithUser:userVO withSubject:_challengeVO.subjectName]];
				[navigationController setNavigationBarHidden:YES];
				[self presentViewController:navigationController animated:YES completion:nil];
				break;}
				
			case 1:
				break;
		}
	}
}


@end
