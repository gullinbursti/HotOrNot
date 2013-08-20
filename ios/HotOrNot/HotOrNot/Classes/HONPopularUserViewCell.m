//
//  HONPopularUserViewCell.m
//  HotOrNot
//
//  Created by Matt Holcombe on 7/8/13 @ 5:03 PM.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import "UIImageView+AFNetworking.h"

#import "HONPopularUserViewCell.h"

@interface HONPopularUserViewCell()
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *checkButton;
@end

@implementation HONPopularUserViewCell
@synthesize delegate = _delegate;
@synthesize celebVO = _celebVO;

+ (NSString *)cellReuseIdentifier {
	return (NSStringFromClass(self));
}


- (id)init {
	if ((self = [super init])) {
		self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"genericRowBackground_nonActive"]];
		//self.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rowGray_nonActive"]];
		
		_checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_checkButton.frame = CGRectMake(266.0, 9.0, 44.0, 44.0);
		[_checkButton setBackgroundImage:[UIImage imageNamed:@"viewedSnapCheck_nonActive"] forState:UIControlStateNormal];
		[_checkButton setBackgroundImage:[UIImage imageNamed:@"viewedSnapCheck_Active"] forState:UIControlStateHighlighted];
		[_checkButton addTarget:self action:@selector(_goUnfollow) forControlEvents:UIControlEventTouchUpInside];
		_checkButton.hidden = YES;
		[self addSubview:_checkButton];
		
		_followButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_followButton.frame = CGRectMake(258.0, 9.0, 44.0, 44.0);
		[_followButton setBackgroundImage:[UIImage imageNamed:@"addFriendPlus_nonActive"] forState:UIControlStateNormal];
		[_followButton setBackgroundImage:[UIImage imageNamed:@"addFriendPlus_Active"] forState:UIControlStateHighlighted];
		[_followButton addTarget:self action:@selector(_goFollow) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:_followButton];
	}
	
	return (self);
}

- (void)setCelebVO:(HONCelebVO *)celebVO {
	_celebVO = celebVO;
	
	UIImageView *avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0, 13.0, 38.0, 38.0)];
	[avatarImageView setImageWithURL:[NSURL URLWithString:_celebVO.avatarURL] placeholderImage:nil];
	[self addSubview:avatarImageView];
	
	UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(59.0, 24.0, 200.0, 20.0)];
	nameLabel.font = [[HONAppDelegate cartoGothicBook] fontWithSize:16];
	nameLabel.textColor = [HONAppDelegate honBlueTextColor];
	nameLabel.backgroundColor = [UIColor clearColor];
	nameLabel.text = [NSString stringWithFormat:@"@%@", _celebVO.username];
	[self addSubview:nameLabel];
}

- (void)toggleSelected:(BOOL)isSelected {
	_followButton.hidden = isSelected;
	_checkButton.hidden = !isSelected;
}


#pragma mark - Navigation
- (void)_goFollow {
	_followButton.hidden = YES;
	_checkButton.hidden = NO;
	
	[self.delegate popularUserViewCell:self celeb:_celebVO toggleSelected:YES];
}

- (void)_goUnfollow {
	_followButton.hidden = NO;
	_checkButton.hidden = YES;
	
	[self.delegate popularUserViewCell:self celeb:_celebVO toggleSelected:NO];
}

@end
