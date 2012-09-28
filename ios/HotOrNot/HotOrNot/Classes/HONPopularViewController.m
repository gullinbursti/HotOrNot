//
//  HONPopularViewController.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.06.12.
//  Copyright (c) 2012 Built in Menlo. All rights reserved.
//

#import "HONPopularViewController.h"
#import "HONCreateChallengeViewController.h"
#import "HONVoteViewController.h"

#import "HONPopularUserViewCell.h"
#import "HONPopularSubjectViewCell.h"
#import "HONAppDelegate.h"
#import "ASIFormDataRequest.h"

#import "HONPopularSubjectVO.h"
#import "HONPopularUserVO.h"

@interface HONPopularViewController() <ASIHTTPRequestDelegate>
- (void)_retrievePopular;

@property(nonatomic) BOOL isUsersList;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIImageView *toggleImgView;
@property(nonatomic, strong) NSMutableArray *users;
@property(nonatomic, strong) NSMutableArray *subjects;
@property(nonatomic, strong) ASIFormDataRequest *subjectsRequest;
@property(nonatomic, strong) ASIFormDataRequest *usersRequest;
@end

@implementation HONPopularViewController

@synthesize tableView = _tableView;
@synthesize toggleImgView = _toggleImgView;
@synthesize users = _users;
@synthesize subjects = _subjects;
@synthesize isUsersList = _isUsersList;

- (id)init {
	if ((self = [super init])) {
		self.tabBarItem.image = [UIImage imageNamed:@"tab04_nonActive"];
		self.view.backgroundColor = [UIColor whiteColor];
		
		self.users = [NSMutableArray new];
		self.subjects = [NSMutableArray new];
		
		self.isUsersList = YES;
	}
	
	return (self);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
- (void)loadView {
	[super loadView];
	
	UIImageView *headerImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 45.0)];
	headerImgView.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
	[headerImgView setImage:[UIImage imageNamed:@"basicHeader.png"]];
	headerImgView.userInteractionEnabled = YES;
	[self.view addSubview:headerImgView];
	
	_toggleImgView = [[UIImageView alloc] initWithFrame:CGRectMake(76.0, 5.0, 167.0, 34.0)];
	_toggleImgView.image = [UIImage imageNamed:@"Ltoggle.png"];
	[headerImgView addSubview:_toggleImgView];
	
	UIButton *leadersButton = [UIButton buttonWithType:UIButtonTypeCustom];
	leadersButton.frame = CGRectMake(76.0, 5.0, 84.0, 34.0);
	[leadersButton addTarget:self action:@selector(_goLeaders) forControlEvents:UIControlEventTouchUpInside];
	//leadersButton = [[SNAppDelegate snHelveticaNeueFontMedium] fontWithSize:11.0];
	[leadersButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[leadersButton setTitle:@"Leaders" forState:UIControlStateNormal];
	[headerImgView addSubview:leadersButton];
	
	UIButton *tagsButton = [UIButton buttonWithType:UIButtonTypeCustom];
	tagsButton.frame = CGRectMake(161.0, 5.0, 84.0, 34.0);
	[tagsButton addTarget:self action:@selector(_goTags) forControlEvents:UIControlEventTouchUpInside];
	//tagsButton = [[SNAppDelegate snHelveticaNeueFontMedium] fontWithSize:11.0];
	[tagsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[tagsButton setTitle:@"Tags" forState:UIControlStateNormal];
	[headerImgView addSubview:tagsButton];
	
	self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 45.0, self.view.frame.size.width, self.view.frame.size.height - 95.0) style:UITableViewStylePlain];
	[self.tableView setBackgroundColor:[UIColor clearColor]];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.rowHeight = 70.0;
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.userInteractionEnabled = YES;
	self.tableView.scrollsToTop = NO;
	self.tableView.showsVerticalScrollIndicator = YES;
	[self.view addSubview:self.tableView];
	
	[self _retrievePopular];
}

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self _retrievePopular];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (NO);//interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)_retrievePopular {
	self.usersRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", kServerPath, kPopularAPI]]];
	[self.usersRequest setDelegate:self];
	[self.usersRequest setPostValue:[NSString stringWithFormat:@"%d", 1] forKey:@"action"];
	[self.usersRequest setPostValue:[[HONAppDelegate infoForUser] objectForKey:@"id"] forKey:@"userID"];
	[self.usersRequest startAsynchronous];
}


#pragma mark - Navigation
- (void)_goLeaders {
	self.isUsersList = YES;
	_toggleImgView.image = [UIImage imageNamed:@"Ltoggle.png"];
	
	self.usersRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", kServerPath, kPopularAPI]]];
	[self.usersRequest setDelegate:self];
	[self.usersRequest setPostValue:[NSString stringWithFormat:@"%d", 1] forKey:@"action"];
	[self.usersRequest setPostValue:[[HONAppDelegate infoForUser] objectForKey:@"id"] forKey:@"userID"];
	[self.usersRequest startAsynchronous];
}

- (void)_goTags {
	self.isUsersList = NO;
	_toggleImgView.image = [UIImage imageNamed:@"Rtoggle.png"];
	
	self.usersRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", kServerPath, kPopularAPI]]];
	[self.usersRequest setDelegate:self];
	[self.usersRequest setPostValue:[NSString stringWithFormat:@"%d", 2] forKey:@"action"];
	[self.usersRequest setPostValue:[[HONAppDelegate infoForUser] objectForKey:@"id"] forKey:@"userID"];
	[self.usersRequest startAsynchronous];
}


#pragma mark - TableView DataSource Delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if (self.isUsersList)
		return ([_users count] + 2);
	
	else
		return ([_subjects count] + 2);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (self.isUsersList) {
		HONPopularUserViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
		
		if (cell == nil) {
			if (indexPath.row == 0)
				cell = [[HONPopularUserViewCell alloc] initAsTopCell:[[[HONAppDelegate infoForUser] objectForKey:@"points"] intValue] withSubject:@"funnyface"];
			
			else if (indexPath.row == [_users count] + 1)
				cell = [[HONPopularUserViewCell alloc] initAsBottomCell];
			
			else
				cell = [[HONPopularUserViewCell alloc] initAsMidCell:indexPath.row];
		}
		
		if (indexPath.row > 0 && indexPath.row < [_users count] + 1)
			cell.userVO = [_users objectAtIndex:indexPath.row - 1];
		
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		return (cell);
	
	} else {
		HONPopularSubjectViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
		
		if (cell == nil) {
			if (indexPath.row == 0)
				cell = [[HONPopularSubjectViewCell alloc] initAsTopCell:[[[HONAppDelegate infoForUser] objectForKey:@"points"] intValue] withSubject:@"funnyface"];
			
			else if (indexPath.row == [_subjects count] + 1)
				cell = [[HONPopularSubjectViewCell alloc] initAsBottomCell];
			
			else
				cell = [[HONPopularSubjectViewCell alloc] initAsMidCell:indexPath.row];
		}
		
		if (indexPath.row > 0 && indexPath.row < [_subjects count] + 1)
			cell.subjectVO = [_subjects objectAtIndex:indexPath.row - 1];
		
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		return (cell);
	}
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == 0)
		return (55.0);
	
	else
		return (70.0);
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return (indexPath);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
	
	if (self.isUsersList) {
		HONPopularUserVO *vo = (HONPopularUserVO *)[_users objectAtIndex:indexPath.row - 1];
		NSLog(@"CHALLENGE USER");
		[self.navigationController pushViewController:[[HONCreateChallengeViewController alloc] initWithUser:vo.userID] animated:YES];
	
	} else {
		HONPopularSubjectVO *vo = (HONPopularSubjectVO *)[_subjects objectAtIndex:indexPath.row - 1];
		
		NSLog(@"VOTE SUBJECT :[%@]", vo.subjectName);
		[self.navigationController pushViewController:[[HONVoteViewController alloc] initWithSubject:vo.subjectID] animated:YES];
	}
	
	//	[UIView animateWithDuration:0.25 animations:^(void) {
	//		((HONChallengeViewCell *)[tableView cellForRowAtIndexPath:indexPath]).overlayView.alpha = 1.0;
	//
	//	} completion:^(BOOL finished) {
	//		((HONChallengeViewCell *)[tableView cellForRowAtIndexPath:indexPath]).overlayView.alpha = 0.0;
	//	}];
	
	//[self.navigationController pushViewController:[[SNFriendProfileViewController alloc] initWithTwitterUser:(SNTwitterUserVO *)[_friends objectAtIndex:indexPath.row]] animated:YES];
}


#pragma mark - ASI Delegates
-(void)requestFinished:(ASIHTTPRequest *)request {
	NSLog(@"HONPopularViewController [_asiFormRequest responseString]=\n%@\n\n", [request responseString]);
	
	
		@autoreleasepool {
			NSError *error = nil;
			if (error != nil)
				NSLog(@"Failed to parse user JSON: %@", [error localizedDescription]);
			
			else {
				NSArray *parsedLists = [NSJSONSerialization JSONObjectWithData:[request responseData] options:0 error:&error];
				
				if (_isUsersList) {
					_users = [NSMutableArray new];
					
					NSMutableArray *list = [NSMutableArray array];
					for (NSDictionary *serverList in parsedLists) {
						HONPopularUserVO *vo = [HONPopularUserVO userWithDictionary:serverList];
						//NSLog(@"VO:[%d]", vo.userID);
						
						if (vo != nil)
							[list addObject:vo];
					}
					
					_users = [list copy];
				
				} else {
					_subjects = [NSMutableArray new];
					
					NSMutableArray *list = [NSMutableArray array];
					for (NSDictionary *serverList in parsedLists) {
						HONPopularSubjectVO *vo = [HONPopularSubjectVO subjectWithDictionary:serverList];
						//NSLog(@"VO:[%@]", vo.subjectName);
						
						if (vo != nil)
							[list addObject:vo];
					}
					
					_subjects = [list copy];
				}
				
				[_tableView reloadData];
			}
		}
}

-(void)requestFailed:(ASIHTTPRequest *)request {
	NSLog(@"requestFailed:\n[%@]", request.error);
}

@end
