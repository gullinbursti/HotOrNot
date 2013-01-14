//
//  HONVoteItemViewCell.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.07.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "Mixpanel.h"
#import "UIImageView+WebCache.h"

#import "HONVoteItemViewCell.h"
#import "HONAppDelegate.h"
#import "HONVoterVO.h"


@interface HONVoteItemViewCell() <AVAudioPlayerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) UIView *lHolderView;
@property (nonatomic, strong) UIView *rHolderView;
@property (nonatomic, strong) UIView *tappedOverlayView;
@property (nonatomic, strong) UILabel *lScoreLabel;
@property (nonatomic, strong) UILabel *rScoreLabel;
@property (nonatomic, strong) UIButton *votesButton;
@property (nonatomic, strong) UIImageView *loserOverlayImageView;
@property (nonatomic, strong) UIImageView *resultsImageView;
@property (nonatomic, strong) NSMutableArray *voters;
@property (nonatomic) BOOL hasChallenger;
@property (nonatomic, strong) AVAudioPlayer *sfxPlayer;
@end

@implementation HONVoteItemViewCell

+ (NSString *)cellReuseIdentifier {
	return (NSStringFromClass(self));
}

- (id)initAsWaitingCell {
	if ((self = [super init])) {
		_hasChallenger = NO;
		
		UIImageView *bgImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 346.0)];
		bgImgView.image = [UIImage imageNamed:@"challengeWall_notInProgress"];
		[self addSubview:bgImgView];
	}
	
	return (self);
}

- (id)initAsStartedCell {
	if ((self = [super init])) {
		_hasChallenger = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_upvoteCreator:) name:@"UPVOTE_CREATOR" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_upvoteChallenger:) name:@"UPVOTE_CHALLENGER" object:nil];
		
		UIImageView *bgImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 244.0)];
		bgImgView.image = [UIImage imageNamed:@"challengeWall_inProgress"];
		[self addSubview:bgImgView];
	}
	
	return (self);
}

- (void)setChallengeVO:(HONChallengeVO *)challengeVO {
	_challengeVO = challengeVO;
	
	UILabel *ctaLabel = [[UILabel alloc] initWithFrame:CGRectMake(14.0, 5.0, 260.0, 16.0)];
	ctaLabel.font = [[HONAppDelegate honHelveticaNeueFontBold] fontWithSize:12];
	ctaLabel.textColor = [HONAppDelegate honGreyTxtColor];
	ctaLabel.backgroundColor = [UIColor clearColor];
	ctaLabel.text = [HONAppDelegate ctaForChallenge:_challengeVO];
	[self addSubview:ctaLabel];
	
	UILabel *subjectLabel = [[UILabel alloc] initWithFrame:CGRectMake(14.0, 24.0, 200.0, 16.0)];
	subjectLabel.font = [[HONAppDelegate freightSansBlack] fontWithSize:13];
	subjectLabel.textColor = [UIColor blackColor];
	subjectLabel.backgroundColor = [UIColor clearColor];
	subjectLabel.text = _challengeVO.subjectName;
	[self addSubview:subjectLabel];
	
	UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
	moreButton.frame = CGRectMake(271.0, 6.0, 34.0, 34.0);
	[moreButton setBackgroundImage:[UIImage imageNamed:@"moreIcon_nonActive"] forState:UIControlStateNormal];
	[moreButton setBackgroundImage:[UIImage imageNamed:@"moreIcon_nonActive"] forState:UIControlStateHighlighted];
	[moreButton addTarget:self action:@selector(_goMore) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:moreButton];
	
	if (_hasChallenger) {
		_lHolderView = [[UIView alloc] initWithFrame:CGRectMake(7.0, 46.0, 153.0, 153.0)];
		_lHolderView.clipsToBounds = YES;
		[self addSubview:_lHolderView];
		
		UIImageView *lImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, -25.0, kMediumW, kMediumH)];
		lImgView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
		[lImgView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@_m.jpg", challengeVO.creatorImgPrefix]] placeholderImage:nil options:SDWebImageLowPriority];
		lImgView.userInteractionEnabled = YES;
		[_lHolderView addSubview:lImgView];
		
		UIImageView *lScoreImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 123.0, 153.0, 30.0)];
		lScoreImageView.image = [UIImage imageNamed:@"challengeWallScore_Overlay"];
		[_lHolderView addSubview:lScoreImageView];
		
		_lScoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 7.0, 144.0, 18.0)];
		_lScoreLabel.font = [[HONAppDelegate honHelveticaNeueFontBold] fontWithSize:16];
		_lScoreLabel.backgroundColor = [UIColor clearColor];
		_lScoreLabel.textColor = [UIColor whiteColor];
		_lScoreLabel.textAlignment = NSTextAlignmentRight;
		_lScoreLabel.text = [NSString stringWithFormat:@"%d", _challengeVO.creatorScore];
		[lScoreImageView addSubview:_lScoreLabel];
		
		_rHolderView = [[UIView alloc] initWithFrame:CGRectMake(160.0, 46.0, 153.0, 153.0)];
		_rHolderView.clipsToBounds = YES;
		[self addSubview:_rHolderView];
		
		UIImageView *rImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, -25.0, kMediumW, kMediumH)];
		rImgView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
		[rImgView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@_m.jpg", challengeVO.challengerImgPrefix]] placeholderImage:nil options:SDWebImageLowPriority];
		rImgView.userInteractionEnabled = YES;
		[_rHolderView addSubview:rImgView];
		
		UIImageView *rScoreImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 123.0, 153.0, 30.0)];
		rScoreImageView.image = [UIImage imageNamed:@"challengeWallScore_Overlay"];
		[_rHolderView addSubview:rScoreImageView];
		
		_rScoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 7.0, 140.0, 18.0)];
		_rScoreLabel.font = [[HONAppDelegate honHelveticaNeueFontBold] fontWithSize:16];
		_rScoreLabel.backgroundColor = [UIColor clearColor];
		_rScoreLabel.textColor = [UIColor whiteColor];
		_rScoreLabel.textAlignment = NSTextAlignmentRight;
		_rScoreLabel.text = [NSString stringWithFormat:@"%d", _challengeVO.challengerScore];
		[rScoreImageView addSubview:_rScoreLabel];
		
		UIImageView *vsImageView = [[UIImageView alloc] initWithFrame:CGRectMake(138.0, 97.0, 44.0, 44.0)];
		vsImageView.image = [UIImage imageNamed:@"orIcon"];
		[self addSubview:vsImageView];
		
		_votesButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_votesButton.frame = CGRectMake(12.0, 204.0, 84.0, 34.0);
		[_votesButton setBackgroundImage:[UIImage imageNamed:@"voteButton_nonActive"] forState:UIControlStateNormal];
		[_votesButton setBackgroundImage:[UIImage imageNamed:@"voteButton_Active"] forState:UIControlStateHighlighted];
		_votesButton.titleLabel.font = [[HONAppDelegate qualcommBold] fontWithSize:14];
		[_votesButton setTitleColor:[HONAppDelegate honGreyTxtColor] forState:UIControlStateNormal];
		[_votesButton setTitle:[NSString stringWithFormat:((_challengeVO.creatorScore + _challengeVO.challengerScore) == 1) ? @"%d VOTE" : @"%d VOTES", (_challengeVO.creatorScore + _challengeVO.challengerScore)] forState:UIControlStateNormal];
		[_votesButton addTarget:self action:@selector(_goScore) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:_votesButton];
	
	} else {
		_lHolderView = [[UIView alloc] initWithFrame:CGRectMake(7.0, 46.0, 306.0, 306.0)];
		_lHolderView.clipsToBounds = YES;
		[self addSubview:_lHolderView];
		
		UIImageView *lImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, kLargeW * 0.5, kLargeW * 0.5)]; //x408
		[lImgView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@_l.jpg", challengeVO.creatorImgPrefix]] placeholderImage:nil options:SDWebImageLowPriority];
		lImgView.userInteractionEnabled = YES;
		[_lHolderView addSubview:lImgView];
		
		UIImageView *overlayWaitingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 236.0, 306.0, 70.0)];
		overlayWaitingImageView.image = [UIImage imageNamed:@"waitingImageOverlay"];
		overlayWaitingImageView.userInteractionEnabled = YES;
		[lImgView addSubview:overlayWaitingImageView];
		
		UILabel *creatorNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(92.0, 253.0, 144.0, 16.0)];
		creatorNameLabel.font = [[HONAppDelegate honHelveticaNeueFontBold] fontWithSize:14];
		creatorNameLabel.backgroundColor = [UIColor clearColor];
		creatorNameLabel.textColor = [HONAppDelegate honGreyTxtColor];
		creatorNameLabel.shadowColor = [UIColor blackColor];
		creatorNameLabel.shadowOffset = CGSizeMake(1.0, 1.0);
		creatorNameLabel.text = [NSString stringWithFormat:@"%@ is…", _challengeVO.creatorName];
		[lImgView addSubview:creatorNameLabel];
	}
}


#pragma mark - Touch Interactions
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	UITouch *touch = [touches anyObject];
	
	// this will cancel the single tap action
	if (touch.tapCount == 2) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	UITouch *touch = [touches anyObject];
	
	// this is the single tap action
	if (touch.tapCount == 1) {
		if (CGRectContainsPoint(_lHolderView.frame, [touch locationInView:self])) {
			[self performSelector:@selector(_goSingleTapLeft) withObject:nil afterDelay:0.2];
		
		} else if (CGRectContainsPoint(_rHolderView.frame, [touch locationInView:self])) {
			[self performSelector:@selector(_goSingleTapRight) withObject:nil afterDelay:0.2];
			
		} else {
		}
		
	// this is the double tap action
	} else if (touch.tapCount == 2) {
		if (CGRectContainsPoint(_lHolderView.frame, [touch locationInView:self])) {
			[self _goDoubleTapLeft];
		
		} else if (CGRectContainsPoint(_rHolderView.frame, [touch locationInView:self])) {
			[self _goDoubleTapRight];
			
		} else {
		}
	}
}


#pragma mark - Navigation
- (void)_goSingleTapLeft {
	[self _showTapOverlayOnView:_lHolderView];
	
	if (_hasChallenger) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_IN_SESSION_CREATOR_DETAILS" object:_challengeVO];
	
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_NOT_IN_SESSION_DETAILS" object:_challengeVO];
	}
}

- (void)_goSingleTapRight {
	[self _showTapOverlayOnView:_rHolderView];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_IN_SESSION_CHALLENGER_DETAILS" object:_challengeVO];
}

- (void)_goDoubleTapLeft {
	[self _showTapOverlayOnView:_lHolderView];
	
	if (_hasChallenger) {
		if ([[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] != _challengeVO.creatorID)
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_CREATOR_CHALLENGE" object:_challengeVO];
		
		else
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_SUBJECT_CHALLENGE" object:_challengeVO];
		
	} else {
		if ([[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] != _challengeVO.creatorID) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_CREATOR_CHALLENGE" object:_challengeVO];
			
		} else
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_SUBJECT_CHALLENGE" object:_challengeVO];
	}
}

- (void)_goDoubleTapRight {
	[self _showTapOverlayOnView:_rHolderView];
	
	if ([[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] != _challengeVO.challengerID)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_CHALLENGER_CHALLENGE" object:_challengeVO];
	
	else
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_SUBJECT_CHALLENGE" object:_challengeVO];
}


//- (void)_goDoubleTap:(UITapGestureRecognizer *)recogizer {
//	_tappedOverlayView = [[UIView alloc] initWithFrame:recogizer.view.frame];
//	_tappedOverlayView.backgroundColor = [UIColor colorWithWhite:0.33 alpha:0.33];
//	[recogizer.view addSubview:_tappedOverlayView];
//	[self performSelector:@selector(_removeTapOverlay) withObject:self afterDelay:0.25];
//
//	if (_hasChallenger) {
//			if ([recogizer isEqual:_lDoubleTapRecognizer]) {
//				if ([[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] != _challengeVO.creatorID)
//					[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_CREATOR_CHALLENGE" object:_challengeVO];
//				
//				else
//					[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_SUBJECT_CHALLENGE" object:_challengeVO];
//			
//			} else {
//				if ([[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] != _challengeVO.challengerID)
//					[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_CHALLENGER_CHALLENGE" object:_challengeVO];
//				
//				else
//					[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_SUBJECT_CHALLENGE" object:_challengeVO];
//			}
//	
//	} else {
//		if ([[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] != _challengeVO.creatorID) {
//			[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_CREATOR_CHALLENGE" object:_challengeVO];
//		
//		} else
//			[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_SUBJECT_CHALLENGE" object:_challengeVO];//[self _goNewChallengeAlert];
//	}
//}

//- (void)_goSingleTap:(UITapGestureRecognizer *)recogizer {
//	_tappedOverlayView = [[UIView alloc] initWithFrame:recogizer.view.frame];
//	_tappedOverlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
//	[recogizer.view addSubview:_tappedOverlayView];
//	[self performSelector:@selector(_removeTapOverlay) withObject:self afterDelay:0.25];
//	
//	if (_hasChallenger) {
//		//[self _playVoteSFX];
//		
//		if ([recogizer isEqual:_lSingleTapRecognizer]) {
//			[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_IN_SESSION_CREATOR_DETAILS" object:_challengeVO];
//						
//			//if ([HONAppDelegate hasVoted:_challengeVO.challengeID])
//			//	[self _goUpvoteOverlay];
//			//
//			//else {
//			//	[self _upvoteLeft];
//			//}
//		
//		} else {
//			[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_IN_SESSION_CHALLENGER_DETAILS" object:_challengeVO];
//			
//			//if ([HONAppDelegate hasVoted:_challengeVO.challengeID])
//			//	[self _goUpvoteOverlay];
//			//
//			//else {
//			//	[self _upvoteRight];
//			//}
//		}
//	
//	} else {
//		[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_NOT_IN_SESSION_DETAILS" object:_challengeVO];
//		
//		//if ([[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] != _challengeVO.creatorID)
//		//	[self _goMore];
//		//
//		//else
//		//	[self _goNewChallengeAlert];
//	}
//}

- (void)_goScore {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_VOTERS" object:_challengeVO];
}

- (void)_goMore {
	[[Mixpanel sharedInstance] track:@"Vote - More"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
												 [NSString stringWithFormat:@"%d - %@", _challengeVO.challengeID, _challengeVO.subjectName], @"user", nil]];
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
																				delegate:self
																	cancelButtonTitle:@"Cancel"
															 destructiveButtonTitle:@"Report Abuse"
																	otherButtonTitles:[NSString stringWithFormat:@"%@ Challenge", _challengeVO.subjectName], @"Share", nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
	[actionSheet setTag:2];
	[actionSheet showInView:[HONAppDelegate appTabBarController].view];
}


#pragma mark - Notifications
- (void)_upvoteCreator:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	if ([vo isEqual:_challengeVO]) {
		[self _playVoteSFX];
		
		if ([HONAppDelegate hasVoted:_challengeVO.challengeID]) {
			//[self _goUpvoteOverlay];
			
			_challengeVO.creatorScore++;
			_lScoreLabel.text = [NSString stringWithFormat:@"%d", _challengeVO.creatorScore];
			
			[self _clearResults];
			_loserOverlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"challengeWallScore_loserOverlay"]];
			_loserOverlayImageView.frame = CGRectOffset(_loserOverlayImageView.frame, (_challengeVO.creatorScore > _challengeVO.challengerScore) ? 160.0 : 7.0, 46.0);
			_loserOverlayImageView.hidden = (_challengeVO.creatorScore == _challengeVO.challengerScore);
			[self addSubview:_loserOverlayImageView];
			
			_resultsImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:(_challengeVO.creatorScore > _challengeVO.challengerScore) ? @"WINNING_OverlayGraphic" : @"LOSING_OverlayGraphic"]];
			_resultsImageView.frame = CGRectOffset(_resultsImageView.frame, (_challengeVO.creatorScore > _challengeVO.challengerScore) ? 56.0 : 130.0, 88.0);
			_resultsImageView.hidden = (_challengeVO.creatorScore == _challengeVO.challengerScore);
			[self addSubview:_resultsImageView];
			
			[_votesButton setTitle:[NSString stringWithFormat:((_challengeVO.creatorScore + _challengeVO.challengerScore) == 1) ? @"%d VOTE" : @"%d VOTES", (_challengeVO.creatorScore + _challengeVO.challengerScore)] forState:UIControlStateNormal];
		
		} else {
			[[Mixpanel sharedInstance] track:@"Upvote Creator"
										 properties:[NSDictionary dictionaryWithObjectsAndKeys:
														 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
														 [NSString stringWithFormat:@"%d - %@", _challengeVO.challengeID, _challengeVO.subjectName], @"challenge", nil]];
			
			_lScoreLabel.text = [NSString stringWithFormat:@"%d", (_challengeVO.creatorScore + 1)];
			
			[self _clearResults];
			_loserOverlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"challengeWallScore_loserOverlay"]];
			_loserOverlayImageView.frame = CGRectOffset(_loserOverlayImageView.frame, (_challengeVO.creatorScore > (_challengeVO.challengerScore + 1)) ? 160.0 : 7.0, 46.0);
			_loserOverlayImageView.hidden = ((_challengeVO.creatorScore + 1) == _challengeVO.challengerScore);
			[self addSubview:_loserOverlayImageView];
			
			_resultsImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:((_challengeVO.creatorScore + 1) > _challengeVO.challengerScore) ? @"WINNING_OverlayGraphic" : @"LOSING_OverlayGraphic"]];
			_resultsImageView.frame = CGRectOffset(_resultsImageView.frame, ((_challengeVO.creatorScore + 1) > _challengeVO.challengerScore) ? 56.0 : 130.0, 88.0);
			_resultsImageView.hidden = ((_challengeVO.creatorScore + 1) == _challengeVO.challengerScore);
			[self addSubview:_resultsImageView];
			
			[HONAppDelegate setVote:_challengeVO.challengeID];
			[_votesButton setTitle:[NSString stringWithFormat:(1 + (_challengeVO.creatorScore + _challengeVO.challengerScore) == 1) ? @"%d VOTE" : @"%d VOTES", 1 + (_challengeVO.creatorScore + _challengeVO.challengerScore)] forState:UIControlStateNormal];
			
			AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
			NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
											[NSString stringWithFormat:@"%d", 6], @"action",
											[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
											[NSString stringWithFormat:@"%d", _challengeVO.challengeID], @"challengeID",
											@"Y", @"creator",
											nil];
			
			[httpClient postPath:kVotesAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
				NSError *error = nil;
				if (error != nil) {
					NSLog(@"Failed to parse job list JSON: %@", [error localizedFailureReason]);
					
				} else {
					NSDictionary *voteResult = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
					NSLog(@"HONVoteItemViewCell AFNetworking: %@", voteResult);
				}
				
			} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				NSLog(@"%@", [error localizedDescription]);
			}];
		}
	}
}

- (void)_upvoteChallenger:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	if ([vo isEqual:_challengeVO]) {
		[self _playVoteSFX];
		
		if ([HONAppDelegate hasVoted:_challengeVO.challengeID]) {
			//[self _goUpvoteOverlay];
			
			_challengeVO.challengerScore++;
			
			_rScoreLabel.text = [NSString stringWithFormat:@"%d", _challengeVO.challengerScore];
			
			[self _clearResults];
			_loserOverlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"challengeWallScore_loserOverlay"]];
			_loserOverlayImageView.frame = CGRectOffset(_loserOverlayImageView.frame, (_challengeVO.creatorScore > _challengeVO.challengerScore) ? 160.0 : 7.0, 46.0);
			_loserOverlayImageView.hidden = (_challengeVO.creatorScore == _challengeVO.challengerScore);
			[self addSubview:_loserOverlayImageView];
			
			_resultsImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:(_challengeVO.creatorScore > _challengeVO.challengerScore) ? @"WINNING_OverlayGraphic" : @"LOSING_OverlayGraphic"]];
			_resultsImageView.frame = CGRectOffset(_resultsImageView.frame, (_challengeVO.creatorScore > _challengeVO.challengerScore) ? 56.0 : 130.0, 88.0);
			_resultsImageView.hidden = (_challengeVO.creatorScore == _challengeVO.challengerScore);
			[self addSubview:_resultsImageView];

			[_votesButton setTitle:[NSString stringWithFormat:((_challengeVO.creatorScore + _challengeVO.challengerScore) == 1) ? @"%d VOTE" : @"%d VOTES", (_challengeVO.creatorScore + _challengeVO.challengerScore)] forState:UIControlStateNormal];
			
		} else {
			[[Mixpanel sharedInstance] track:@"Upvote Challenger"
										 properties:[NSDictionary dictionaryWithObjectsAndKeys:
														 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
														 [NSString stringWithFormat:@"%d - %@", _challengeVO.challengeID, _challengeVO.subjectName], @"challenge", nil]];
			
			_rScoreLabel.text = [NSString stringWithFormat:@"%d", (_challengeVO.challengerScore + 1)];
			
			[self _clearResults];
			_loserOverlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"challengeWallScore_loserOverlay"]];
			_loserOverlayImageView.frame = CGRectOffset(_loserOverlayImageView.frame, (_challengeVO.creatorScore > (_challengeVO.challengerScore + 1)) ? 160.0 : 7.0, 46.0);
			_loserOverlayImageView.hidden = (_challengeVO.creatorScore == (_challengeVO.challengerScore + 1));
			[self addSubview:_loserOverlayImageView];
			
			_resultsImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:((_challengeVO.creatorScore + 1) > _challengeVO.challengerScore) ? @"WINNING_OverlayGraphic" : @"LOSING_OverlayGraphic"]];
			_resultsImageView.frame = CGRectOffset(_resultsImageView.frame, ((_challengeVO.creatorScore + 1) > _challengeVO.challengerScore) ? 56.0 : 130.0, 88.0);
			_resultsImageView.hidden = (_challengeVO.creatorScore == (_challengeVO.challengerScore + 1));
			[self addSubview:_resultsImageView];
			
			[HONAppDelegate setVote:_challengeVO.challengeID];
			[_votesButton setTitle:[NSString stringWithFormat:(1 + (_challengeVO.creatorScore + _challengeVO.challengerScore) == 1) ? @"%d VOTE" : @"%d VOTES", 1 + (_challengeVO.creatorScore + _challengeVO.challengerScore)] forState:UIControlStateNormal];
			
			AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
			NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
											[NSString stringWithFormat:@"%d", 6], @"action",
											[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
											[NSString stringWithFormat:@"%d", _challengeVO.challengeID], @"challengeID",
											@"N", @"creator",
											nil];
			
			[httpClient postPath:kVotesAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
				NSError *error = nil;
				if (error != nil) {
					NSLog(@"Failed to parse job list JSON: %@", [error localizedFailureReason]);
					
				} else {
					NSDictionary *voteResult = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
					NSLog(@"HONVoteItemViewCell AFNetworking: %@", voteResult);
				}
				
			} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				NSLog(@"%@", [error localizedDescription]);
			}];
		}
	}
}


#pragma mark - Behaviors
- (void)_clearResults {
	if (_loserOverlayImageView != nil) {
		[_loserOverlayImageView removeFromSuperview];
		_loserOverlayImageView = nil;
	}
	
	if (_resultsImageView != nil) {
		[_resultsImageView removeFromSuperview];
		_resultsImageView = nil;
	}
}

//- (void)_goNewChallengeAlert {
//	UIAlertView *alertView = [[UIAlertView alloc]
//								 initWithTitle:@"New Challenge"
//								 message:@"Your challenge is waiting to be accepted, want to challenge someone else?"
//								 delegate:self
//								 cancelButtonTitle:@"Yes"
//								 otherButtonTitles:@"No", nil];
//	
//	[alertView setTag:0];
//	[alertView show];
//}

//- (void)_goVotedChallengeAlert {
//	UIAlertView *alertView = [[UIAlertView alloc]
//									  initWithTitle:@"New Challenge"
//									  message:@"You already liked this!!! Do you want to challenge another player?"
//									  delegate:self
//									  cancelButtonTitle:@"Yes"
//									  otherButtonTitles:@"No", nil];
//	
//	[alertView setTag:1];
//	[alertView show];
//}

- (void)_playVoteSFX {
	_sfxPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"fpo_upvote" withExtension:@"mp3"] error:NULL];
	_sfxPlayer.delegate = self;
	[_sfxPlayer play];
}

- (void)_goUpvoteOverlay {
	
	[self _clearResults];
	_loserOverlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"challengeWallScore_loserOverlay"]];
	_loserOverlayImageView.frame = CGRectOffset(_loserOverlayImageView.frame, (_challengeVO.creatorScore > _challengeVO.challengerScore) ? 160.0 : 7.0, 46.0);
	_loserOverlayImageView.hidden = (_challengeVO.creatorScore == _challengeVO.challengerScore);
	[self addSubview:_loserOverlayImageView];
	
	_resultsImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:(_challengeVO.creatorScore > _challengeVO.challengerScore) ? @"WINNING_OverlayGraphic" : @"LOSING_OverlayGraphic"]];
	_resultsImageView.frame = CGRectOffset(_resultsImageView.frame, (_challengeVO.creatorScore > _challengeVO.challengerScore) ? 56.0 : 130.0, 88.0);
	_resultsImageView.hidden = (_challengeVO.creatorScore == _challengeVO.challengerScore);
	[self addSubview:_resultsImageView];
}


- (void)_showTapOverlayOnView:(UIView *)view {
	_tappedOverlayView = [[UIView alloc] initWithFrame:view.frame];
	_tappedOverlayView.backgroundColor = [UIColor colorWithWhite:0.33 alpha:0.33];
	[self addSubview:_tappedOverlayView];
	
	[self performSelector:@selector(_removeTapOverlay) withObject:self afterDelay:0.25];
}

- (void)_removeTapOverlay {
	[_tappedOverlayView removeFromSuperview];
	_tappedOverlayView = nil;
}


#pragma mark - ActionSheet Delegates
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (actionSheet.tag == 0) {
//		switch (buttonIndex) {
//			case 0:
//				//[self _playVoteSFX];
//				//[self _upvoteLeft];
//				break;
//				
//			case 1:
//				[[Mixpanel sharedInstance] track:@"Vote Wall - Challenge Creator"
//											 properties:[NSDictionary dictionaryWithObjectsAndKeys:
//															 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
//															 [NSString stringWithFormat:@"%d - %@", _challengeVO.challengeID, _challengeVO.subjectName], @"challenge", nil]];
//				
//				[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_CREATOR_CHALLENGE" object:_challengeVO];
//				break;
//				
//			case 3: {
//				[[Mixpanel sharedInstance] track:@"Poke Creator"
//											 properties:[NSDictionary dictionaryWithObjectsAndKeys:
//															 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
//															 [NSString stringWithFormat:@"%d - %@", _challengeVO.challengeID, _challengeVO.subjectName], @"challenge", nil]];
//				
//				ASIFormDataRequest *voteRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [HONAppDelegate apiServerPath], kUsersAPI]]];
//				[voteRequest setPostValue:[NSString stringWithFormat:@"%d", 6] forKey:@"action"];
//				[voteRequest setPostValue:[[HONAppDelegate infoForUser] objectForKey:@"id"] forKey:@"pokerID"];
//				[voteRequest setPostValue:[NSString stringWithFormat:@"%d", _challengeVO.creatorID] forKey:@"pokeeID"];
//				[voteRequest startAsynchronous];
//				break;}
//		}
		
	} else if (actionSheet.tag == 1) {
//		switch (buttonIndex) {
//			case 0:
//				//[self _playVoteSFX];
//				//[self _upvoteRight];
//				break;
//				
//			case 1:
//				[[Mixpanel sharedInstance] track:@"Vote Wall - Challenge Challenger"
//											 properties:[NSDictionary dictionaryWithObjectsAndKeys:
//															 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
//															 [NSString stringWithFormat:@"%d - %@", _challengeVO.challengeID, _challengeVO.subjectName], @"challenge", nil]];
//				
//				[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_CHALLENGER_CHALLENGE" object:_challengeVO];
//				break;
//				
//			case 3: {
//				[[Mixpanel sharedInstance] track:@"Vote Wall - Poke Challenger"
//											 properties:[NSDictionary dictionaryWithObjectsAndKeys:
//															 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
//															 [NSString stringWithFormat:@"%d - %@", _challengeVO.challengeID, _challengeVO.subjectName], @"challenge", nil]];
//				
//				ASIFormDataRequest *voteRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [HONAppDelegate apiServerPath], kUsersAPI]]];
//				[voteRequest setPostValue:[NSString stringWithFormat:@"%d", 6] forKey:@"action"];
//				[voteRequest setPostValue:[[HONAppDelegate infoForUser] objectForKey:@"id"] forKey:@"pokerID"];
//				[voteRequest setPostValue:[NSString stringWithFormat:@"%d", _challengeVO.challengerID] forKey:@"pokeeID"];
//				[voteRequest startAsynchronous];
//				break;}
//		}
	
	// more button
	} else if (actionSheet.tag == 2) {
		switch (buttonIndex) {
			case 0: {
				[[Mixpanel sharedInstance] track:@"Vote Wall - Flag"
											 properties:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
															 [NSString stringWithFormat:@"%d - %@", _challengeVO.challengeID, _challengeVO.subjectName], @"user", nil]];
				
				AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
				NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
												[NSString stringWithFormat:@"%d", 11], @"action",
												[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
												[NSString stringWithFormat:@"%d", _challengeVO.challengeID], @"challengeID",
												nil];
				
				[httpClient postPath:kChallengesAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
					NSError *error = nil;
					if (error != nil) {
						NSLog(@"Failed to parse job list JSON: %@", [error localizedFailureReason]);
						
					} else {
						//NSDictionary *flagResult = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
						//NSLog(@"HONVoteItemViewCell AFNetworking: %@", flagResult);
					}
					
				} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
					NSLog(@"%@", [error localizedDescription]);
				}];
				
			break;}
				
			case 1:
				[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_SUBJECT_CHALLENGE" object:_challengeVO];
				break;
				
			case 2:
				[[NSNotificationCenter defaultCenter] postNotificationName:@"SHARE_CHALLENGE" object:_challengeVO];
				break;
		}
	}
}


#pragma mark - AlertView Delegates
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//	if (alertView.tag == 0) {
//		switch (buttonIndex) {
//			case 0:
//				[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_SUBJECT_CHALLENGE" object:_challengeVO];
//				break;
//		}
//	
//	} else if (alertView.tag == 1) {
//		switch (buttonIndex) {
//			case 0:
//				[[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_SUBJECT_CHALLENGE" object:_challengeVO];
//				break;
//		}
//	}
}


@end

