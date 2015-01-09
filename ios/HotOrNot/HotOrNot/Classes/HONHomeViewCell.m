//
//  HONHomeViewCell.m
//  HotOrNot
//
//  Created by BIM  on 11/20/14.
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "NSCharacterSet+AdditionalSets.h"
#import "NSDate+Operations.h"
#import "UIImageView+AFNetworking.h"
#import "UILabel+BoundingRect.h"
#import "UILabel+FormattedText.h"

#import "HONHomeViewCell.h"
#import "HONRefreshingLabel.h"

@interface HONHomeViewCell()
@property (nonatomic, strong) UIImageView *loadingImageView;
@property (nonatomic, strong) UIImageView *subjectImageView;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *subjectLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *selectButton;
@property (nonatomic, strong) HONRefreshingLabel *scoreLabel;
@property (nonatomic) BOOL isLoading;
@end

@implementation HONHomeViewCell
@synthesize delegate = _delegate;
@synthesize statusUpdateVO = _statusUpdateVO;

+ (NSString *)cellReuseIdentifier {
	return (NSStringFromClass(self));
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		_isLoading = NO;
		
		_loadingImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"imageLoadingDots_home"]];
		_loadingImageView.frame = CGRectOffset(_loadingImageView.frame, 12.0, 12.0);
		[self.contentView addSubview:_loadingImageView];
		
		_subjectImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12.0, 12.0, 50.0, 50.0)];
		[self.contentView addSubview:_subjectImageView];
		
		_usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(71.0, 7.0, 220.0, 22.0)];
		_usernameLabel.backgroundColor = [UIColor clearColor];
		_usernameLabel.textColor = [[HONColorAuthority sharedInstance] percentGreyscaleColor:0.58];
		_usernameLabel.font = [[[HONFontAllocator sharedInstance] cartoGothicBold      ] fontWithSize:13];
		[self.contentView addSubview:_usernameLabel];
		
		_subjectLabel = [[UILabel alloc] initWithFrame:CGRectMake(71.0, 32.0, 220.0, 20.0)];
		_subjectLabel.backgroundColor = [UIColor clearColor];
		_subjectLabel.textColor = [UIColor blackColor];
		_subjectLabel.font = [[[HONFontAllocator sharedInstance] cartoGothicBook] fontWithSize:16];
		[self.contentView addSubview:_subjectLabel];
		
		UIImageView *timeIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]];
		timeIconImageView.frame = CGRectFromSize(CGSizeMake(12.0, 12.0));
		timeIconImageView.frame = CGRectOffset(timeIconImageView.frame, 72.0, 58.0);
		timeIconImageView.backgroundColor = [[HONColorAuthority sharedInstance] honDebugColor:HONDebugGreenColor];
		[self.contentView addSubview:timeIconImageView];
		
		_timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(88.0, 58.0, 48.0, 16.0)];
		_timeLabel.backgroundColor = [UIColor clearColor];
		_timeLabel.textColor = [[HONColorAuthority sharedInstance] percentGreyscaleColor:0.75];
		_timeLabel.font = [[[HONFontAllocator sharedInstance] cartoGothicBook] fontWithSize:12];
		[self.contentView addSubview:_timeLabel];
		
		UIImageView *likesIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@""]];
		likesIconImageView.frame = CGRectFromSize(CGSizeMake(12.0, 12.0));
		likesIconImageView.frame = CGRectOffset(timeIconImageView.frame, 32.0, 0.0);
		likesIconImageView.backgroundColor = [[HONColorAuthority sharedInstance] honDebugColor:HONDebugVioletColor];
		[self.contentView addSubview:likesIconImageView];
		
		_scoreLabel = [[HONRefreshingLabel alloc] initWithFrame:CGRectMake(120.0, 58.0, 48.0, 16.0)];
		_scoreLabel.backgroundColor = [UIColor clearColor];
		_scoreLabel.font = [[[HONFontAllocator sharedInstance] cartoGothicBook] fontWithSize:12];
//		_scoreLabel.textAlignment = NSTextAlignmentRight;
		_scoreLabel.textColor = [[HONColorAuthority sharedInstance]  percentGreyscaleColor:0.75];
		[_scoreLabel setText:NSStringFromInt(_statusUpdateVO.score)];
		[self.contentView addSubview:_scoreLabel];
		
		_selectButton = [UIButton buttonWithType:UIButtonTypeCustom];	
		_selectButton.frame = self.frame;
		[self.contentView addSubview:_selectButton];
	}
	
	return (self);
}

- (void)dealloc {
	if (_isLoading) {
		[_subjectImageView cancelImageRequestOperation];
	}
	
	_isLoading = NO;
}

- (void)destroy {
	if (_isLoading) {
		[_subjectImageView cancelImageRequestOperation];
	}
	
	_isLoading = NO;
}


#pragma mark - Public APIs
- (void)setStatusUpdateVO:(HONStatusUpdateVO *)statusUpdateVO {
	_statusUpdateVO = statusUpdateVO;
	_statusUpdateVO.topicVO.topicName = [_statusUpdateVO.topicVO.topicName stringByAppendingString:@"ing"];
	NSString *actionCaption = [NSString stringWithFormat:@"— is %@ %@", _statusUpdateVO.topicVO.topicName, _statusUpdateVO.subjectVO.subjectName];
	
	_usernameLabel.text = _statusUpdateVO.username;
	_subjectLabel.text = actionCaption;
	_timeLabel.text = [[HONDateTimeAlloter sharedInstance] intervalSinceDate:_statusUpdateVO.addedDate];
	
	if ([actionCaption rangeOfString:_statusUpdateVO.subjectVO.subjectName].location != NSNotFound)
		[_subjectLabel setFont:[[[HONFontAllocator sharedInstance] cartoGothicBold] fontWithSize:16] range:[actionCaption rangeOfString:_statusUpdateVO.subjectVO.subjectName]];
	
	
	[_scoreLabel toggleLoading:YES];
	[[HONAPICaller sharedInstance] retrieveVoteTotalForStatusUpdateByStatusUpdateID:_statusUpdateVO.statusUpdateID completion:^(NSNumber *result) {
		_statusUpdateVO.score = [result intValue];
//		[_scoreLabel setText:[@"" stringFromInt:_statusUpdateVO.score]];
		[_scoreLabel setText:NSStringFromInt(_statusUpdateVO.score)];
		[_scoreLabel setText:NSStringFromInt(_statusUpdateVO.score)];
		[_scoreLabel toggleLoading:NO];
		
//		NSLog(@"STATUS_UPDATE CELL{%@} -=- [%d / %d]-=-(%d)", NSStringFromNSIndexPath(self.indexPath), _clubPhotoVO.challengeID, _clubPhotoVO.clubID, _clubPhotoVO.score);
	}];
}

- (void)toggleImageLoading:(BOOL)isLoading {
	if (isLoading) {
		if (!_isLoading) {
			_isLoading = YES;
			
			void (^imageSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) = ^void(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
				_subjectImageView.image = image;
				_isLoading = NO;
				
				[_selectButton addTarget:self action:@selector(_goSelect) forControlEvents:UIControlEventTouchUpInside];
			};
			
			void (^imageFailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) = ^void((NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)) {
				NSLog(@"ERROR:[%@]", error.description);
				_subjectImageView.image = [UIImage imageNamed:@"placeholderClubPhoto_320x320"];
				_isLoading = NO;
				
				[[HONAPICaller sharedInstance] notifyToCreateImageSizesForPrefix:[[HONAPICaller sharedInstance] normalizePrefixForImageURL:request.URL.absoluteString] forBucketType:HONS3BucketTypeClubs completion:nil];
				[_selectButton addTarget:self action:@selector(_goSelect) forControlEvents:UIControlEventTouchUpInside];
			};
			
//			NSLog(@"URL:[%@]", [_clubPhotoVO.imagePrefix stringByAppendingString:kSnapMediumSuffix]);
			[_subjectImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_statusUpdateVO.imagePrefix]
																   cachePolicy:kOrthodoxURLCachePolicy
															   timeoutInterval:[HONAppDelegate timeoutInterval]]
							  placeholderImage:[UIImage imageNamed:@"loadingArrows"]
									   success:imageSuccessBlock
									   failure:imageFailureBlock];
		}
		
	} else {
		_isLoading = NO;
		[_subjectImageView cancelImageRequestOperation];
	}
}


#pragma mark - Navigation
- (void)_goSelect {
	if ([self.delegate respondsToSelector:@selector(homeViewCell:didSelectStatusUpdate:)])
		[self.delegate homeViewCell:self didSelectStatusUpdate:_statusUpdateVO];
}

@end
