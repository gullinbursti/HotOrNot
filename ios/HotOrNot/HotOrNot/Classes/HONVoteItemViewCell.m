//
//  HONVoteItemViewCell.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.07.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import "HONVoteItemViewCell.h"
#import "UIImageView+WebCache.h"


@interface HONVoteItemViewCell()
@property (nonatomic, strong) UIImageView *lHolderImgView;
@property (nonatomic, strong) UIImageView *rHolderImgView;
@property (nonatomic, strong) UILabel *lScoreLabel;
@property (nonatomic, strong) UILabel *rScoreLabel;
@end

@implementation HONVoteItemViewCell

@synthesize lHolderImgView = _lHolderImgView;
@synthesize rHolderImgView = _rHolderImgView;
@synthesize lScoreLabel = _lScoreLabel;
@synthesize rScoreLabel = _rScoreLabel;

+ (NSString *)cellReuseIdentifier {
	return (NSStringFromClass(self));
}

- (id)init {
	if ((self = [super init])) {
		self.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
		
		_lHolderImgView = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 5.0, 154.0, 249.0)];
		_lHolderImgView.image = [UIImage imageNamed:@"voteBackgroundLiked_nonActive.png"];
		_lHolderImgView.userInteractionEnabled = YES;
		[self addSubview:_lHolderImgView];
		
		_rHolderImgView = [[UIImageView alloc] initWithFrame:CGRectMake(_lHolderImgView.frame.origin.x + _lHolderImgView.frame.size.width, 5.0, 154.0, 249.0)];
		_rHolderImgView.image = [UIImage imageNamed:@"RvoteBackgroundLiked_nonActive.png"];
		_rHolderImgView.userInteractionEnabled = YES;
		[self addSubview:_rHolderImgView];
		
		UIButton *lVoteButton = [UIButton buttonWithType:UIButtonTypeCustom];
		lVoteButton.frame = CGRectMake(5.0, 208.0, 147.0, 35.0);
		[lVoteButton addTarget:self action:@selector(_goLeftVote:) forControlEvents:UIControlEventTouchUpInside];
		[_lHolderImgView addSubview:lVoteButton];
		
		UIButton *rVoteButton = [UIButton buttonWithType:UIButtonTypeCustom];
		rVoteButton.frame = CGRectMake(0.0, 208.0, 147.0, 35.0);
		[rVoteButton addTarget:self action:@selector(_goRightVote:) forControlEvents:UIControlEventTouchUpInside];
		[_rHolderImgView addSubview:rVoteButton];
	}
	
	return (self);
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
}

- (void)setChallengeVO:(HONChallengeVO *)challengeVO {
	_challengeVO = challengeVO;
	
	UIImageView *lImgView = [[UIImageView alloc] initWithFrame:CGRectMake(15.0, 10.0, 125.0, 180.0)];
	[lImgView setImageWithURL:[NSURL URLWithString:challengeVO.imageURL] placeholderImage:nil options:SDWebImageProgressiveDownload];
	[_lHolderImgView addSubview:lImgView];
	
	UIImageView *lScoreImgView = [[UIImageView alloc] initWithFrame:CGRectMake(35.0, 50.0, 84.0, 84.0)];
	lScoreImgView.image = [UIImage imageNamed:@"overlayBackgroundScore.png"];
	[_lHolderImgView addSubview:lScoreImgView];
	
	_lScoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 20.0, 84.0, 16.0)];
	//_lScoreLabel = [[SNAppDelegate snHelveticaNeueFontBold] fontWithSize:11];
	_lScoreLabel.backgroundColor = [UIColor clearColor];
	_lScoreLabel.textColor = [UIColor whiteColor];
	_lScoreLabel.textAlignment = NSTextAlignmentCenter;
	_lScoreLabel.text = [NSString stringWithFormat:@"%d", challengeVO.scoreCreator];
	[lScoreImgView addSubview:_lScoreLabel];
	
	UIImageView *rImgView = [[UIImageView alloc] initWithFrame:CGRectMake(15.0, 10.0, 125.0, 180.0)];
	[rImgView setImageWithURL:[NSURL URLWithString:challengeVO.image2URL] placeholderImage:nil options:SDWebImageProgressiveDownload];
	[_rHolderImgView addSubview:rImgView];
	
	UIImageView *rScoreImgView = [[UIImageView alloc] initWithFrame:CGRectMake(35.0, 50.0, 84.0, 84.0)];
	rScoreImgView.image = [UIImage imageNamed:@"overlayBackgroundScore.png"];
	[_rHolderImgView addSubview:rScoreImgView];
	
	_rScoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 20.0, 84.0, 16.0)];
	//_rScoreLabel = [[SNAppDelegate snHelveticaNeueFontBold] fontWithSize:11];
	_rScoreLabel.backgroundColor = [UIColor clearColor];
	_rScoreLabel.textColor = [UIColor whiteColor];
	_rScoreLabel.textAlignment = NSTextAlignmentCenter;
	_rScoreLabel.text = [NSString stringWithFormat:@"%d", challengeVO.scoreChallenger];
	[rScoreImgView addSubview:_rScoreLabel];
	
		
//	[self.mainImgButton setTitle:[NSString stringWithFormat:@"%d", challengeVO.scoreCreator] forState:UIControlStateNormal];
//	[self.subImgButton setTitle:[NSString stringWithFormat:@"%d", challengeVO.scoreChallenger] forState:UIControlStateNormal];
}


#pragma mark - Navigation
- (void)_goLeftVote:(id)sender {
	[(UIButton *)sender removeTarget:self action:@selector(_goLeftVote:) forControlEvents:UIControlEventTouchUpInside];
	_lHolderImgView.image = [UIImage imageNamed:@"voteBackgroundLiked_Active.png"];
	_lScoreLabel.text = [NSString stringWithFormat:@"%d", (_challengeVO.scoreCreator + 1)];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"VOTE_MAIN" object:self.challengeVO];
}

- (void)_goRightVote:(id)sender {
//	[self.subImgButton setTitle:[NSString stringWithFormat:@"%d", (self.challengeVO.scoreChallenger + 1)] forState:UIControlStateNormal];
	[(UIButton *)sender removeTarget:self action:@selector(_goRightVote:) forControlEvents:UIControlEventTouchUpInside];
	_rHolderImgView.image = [UIImage imageNamed:@"RvoteBackgroundLiked_Active.png"];
	_rScoreLabel.text = [NSString stringWithFormat:@"%d", (_challengeVO.scoreChallenger + 1)];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"VOTE_SUB" object:self.challengeVO];
}

@end
