//
//  HONGenericAvatarViewCell.m
//  HotOrNot
//
//  Created by Matt Holcombe on 11/5/13 @ 9:56 PM.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import "UIImageView+AFNetworking.h"

#import "HONBaseAvatarViewCell.h"
#import "HONAPICaller.h"
#import "HONFontAllocator.h"
#import "HONColorAuthority.h"
#import "HONImagingDepictor.h"

@interface HONBaseAvatarViewCell ()
@end

@implementation HONBaseAvatarViewCell
@synthesize delegate = _delegate;
@synthesize userVO = _userVO;

+ (NSString *)cellReuseIdentifier {
	return (NSStringFromClass(self));
}


- (id)init {
	if ((self = [super init])) {
		self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rowBackground"]];
		
	}
	
	return (self);
}


#pragma mark - Public APIs
- (void)setUserVO:(HONTrivialUserVO *)userVO {
	_userVO = userVO;
	
	_avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12.0, 13.0, 38.0, 38.0)];
	_avatarImageView.alpha = 0.0;
	[self.contentView addSubview:_avatarImageView];
	
	void (^imageSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) = ^void(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
		_avatarImageView.image = image;
		
		[HONImagingDepictor maskImageView:_avatarImageView withMask:[UIImage imageNamed:@"maskAvatarBlack.png"]];
		
		[UIView animateWithDuration:0.25 animations:^(void) {
			_avatarImageView.alpha = 1.0;
		} completion:nil];
	};
	
	void (^imageFailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) = ^void((NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)) {
		[[HONAPICaller sharedInstance] notifyToCreateImageSizesForPrefix:_userVO.avatarPrefix forBucketType:HONS3BucketTypeAvatars completion:nil];
		
		_avatarImageView.image = [HONImagingDepictor defaultAvatarImageAtSize:kSnapTabSize];
		[UIView animateWithDuration:0.25 animations:^(void) {
			_avatarImageView.alpha = 1.0;
		} completion:nil];
	};
	
	[_avatarImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[_userVO.avatarPrefix stringByAppendingString:kSnapThumbSuffix]] cachePolicy:(kIsImageCacheEnabled) ? NSURLRequestUseProtocolCachePolicy : NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:[HONAppDelegate timeoutInterval]]
						   placeholderImage:nil
									success:imageSuccessBlock
									failure:imageFailureBlock];
	
	_nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(63.0, 20.0, 130.0, 22.0)];
	_nameLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:15];
	_nameLabel.textColor = [[HONColorAuthority sharedInstance] honBlueTextColor];
	_nameLabel.backgroundColor = [UIColor clearColor];
	_nameLabel.text = [NSString stringWithFormat:@"@%@", _userVO.username];
	[self.contentView addSubview:_nameLabel];
}


#pragma mark - Navigation
- (void)_goProfile {
	[self.delegate avatarViewCell:self showProfileForUser:_userVO];
}


@end