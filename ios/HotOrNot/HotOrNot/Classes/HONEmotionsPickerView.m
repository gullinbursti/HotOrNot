//
//  HONEmotionsPickerView.h
//  HotOrNot
//
//  Created by Matt Holcombe on 8/27/13.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import "HONEmotionsPickerView.h"
#import "HONEmoticonPickerItemView.h"
#import "HONEmotionPaginationView.h"

const CGSize kImageSpacingSize = {75.0f, 73.0f};

@interface HONEmotionsPickerView () <HONEmotionItemViewDelegate>
@property (nonatomic, strong) __block NSMutableArray *availableEmotions;
@property (nonatomic, strong) NSMutableArray *selectedEmotions;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *bgImageView;
//@property (nonatomic, strong) UIImageView *deleteButtonImageView;
@property (nonatomic, strong) NSMutableArray *pageViews;
@property (nonatomic, strong) NSMutableArray *itemViews;
@property (nonatomic, strong) HONEmotionPaginationView *paginationView;
@property (nonatomic) int prevPage;
@property (nonatomic) int totalPages;
@end

@implementation HONEmotionsPickerView
@synthesize delegate = _delegate;


- (void)_delayed {
	NSLog(@"STICKERS:[%@]", _availableEmotions);
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		_availableEmotions = [NSMutableArray array];
		_selectedEmotions = [NSMutableArray array];
		
		_prevPage = 0;
		_totalPages = 0;
		_pageViews = [NSMutableArray array];
		_itemViews = [NSMutableArray array];
		
		int free_tot = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"pico_candy"] objectForKey:kFreeStickerPak] count];
		int invite_tot = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"pico_candy"] objectForKey:kInviteStickerPak] count];
		
		_bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"emojiPanelBG"]];
		[self addSubview:_bgImageView];
		
		_scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 272.0)];
		_scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, _scrollView.frame.size.height);
		_scrollView.showsHorizontalScrollIndicator = NO;
		_scrollView.showsVerticalScrollIndicator = NO;
		_scrollView.pagingEnabled = YES;
		_scrollView.delegate = self;
		[self addSubview:_scrollView];
		
		
		UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
		deleteButton.frame = CGRectMake(0.0, self.frame.size.height - 49.0, 320.0, 49.0);
		[deleteButton setBackgroundImage:[UIImage imageNamed:@"emojiDeleteButton_nonActive"] forState:UIControlStateNormal];
		[deleteButton setBackgroundImage:[UIImage imageNamed:@"emojiDeleteButton_Active"] forState:UIControlStateHighlighted];
		[deleteButton addTarget:self action:@selector(_goDelete) forControlEvents:UIControlEventTouchDown];
		[self addSubview:deleteButton];
		
		
		__block int cnt = 0;
		for (NSString *contentGroupID in [[[NSUserDefaults standardUserDefaults] objectForKey:@"pico_candy"] objectForKey:kFreeStickerPak]) {
			[[HONStickerAssistant sharedInstance] retrieveContentsForContentGroup:contentGroupID completion:^(NSArray *result) {
				[result enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
					PCContent *content = (PCContent *)obj;
					HONEmotionVO *vo = [HONEmotionVO emotionWithDictionary:@{@"id"		: content.content_id,
																			 @"cg_id"	: contentGroupID,
																			 @"name"	: content.name,
																			 @"price"	: [content.price stringValue],
																			 @"content"	: content,
																			 @"img"		: @""}];
					[_availableEmotions addObject:vo];
					
				}];
				
				if (++cnt >= free_tot) {
					
					cnt = 0;
					if ([[HONContactsAssistant sharedInstance] totalInvitedContacts] >= [HONAppDelegate clubInvitesThreshold]) {
						for (NSString *contentGroupID in [[[NSUserDefaults standardUserDefaults] objectForKey:@"pico_candy"] objectForKey:kInviteStickerPak]) {
							[[HONStickerAssistant sharedInstance] retrieveContentsForContentGroup:contentGroupID completion:^(NSArray *result) {
								[result enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
									PCContent *content = (PCContent *)obj;
									HONEmotionVO *vo = [HONEmotionVO emotionWithDictionary:@{@"id"		: content.content_id,
																							 @"cg_id"	: contentGroupID,
																							 @"name"	: content.name,
																							 @"price"	: [content.price stringValue],
																							 @"content"	: content,
																							 @"img"		: @""}];
									[_availableEmotions addObject:vo];
									
								}];
								
								if (++cnt >= invite_tot) {
									_totalPages = ((int)([_availableEmotions count] / (COLS_PER_ROW * ROWS_PER_PAGE))) + 1;
									_scrollView.contentSize = CGSizeMake(_totalPages * _scrollView.frame.size.width, _scrollView.frame.size.height);
									
									_paginationView = [[HONEmotionPaginationView alloc] initAtPosition:CGPointMake(160.0, 242.0) withTotalPages:_totalPages];
									[_paginationView updateToPage:0];
									[self addSubview:_paginationView];
									
									[self _buildGrid];
								}
							}];
						}
					
					} else {
						_totalPages = ((int)([_availableEmotions count] / (COLS_PER_ROW * ROWS_PER_PAGE))) + 1;
						_scrollView.contentSize = CGSizeMake(_totalPages * _scrollView.frame.size.width, _scrollView.frame.size.height);
						
						_paginationView = [[HONEmotionPaginationView alloc] initAtPosition:CGPointMake(160.0, 242.0) withTotalPages:_totalPages];
						[_paginationView updateToPage:0];
						[self addSubview:_paginationView];
						
						[self _buildGrid];
					}
				}
			}];
		}
			
//
			
//		for (NSDictionary *dict in [[HONStickerAssistant sharedInstance] fetchStickersForPakType:HONStickerPakTypeFree])
//			[_availableEmotions addObject:[HONEmotionVO emotionWithDictionary:dict]];
//		
		if ([[HONContactsAssistant sharedInstance] totalInvitedContacts] >= [HONAppDelegate clubInvitesThreshold]) {
			for (NSString *contentGroupID in [[[NSUserDefaults standardUserDefaults] objectForKey:@"pico_candy"] objectForKey:kInviteStickerPak]) {
				[[HONStickerAssistant sharedInstance] retrieveContentsForContentGroup:contentGroupID completion:^(NSArray *result) {
					[result enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
						PCContent *content = (PCContent *)obj;
						HONEmotionVO *vo = [HONEmotionVO emotionWithDictionary:@{@"id"		: content.content_id,
																				 @"cg_id"	: contentGroupID,
																				 @"name"	: content.name,
																				 @"price"	: [content.price stringValue],
																				 @"content"	: content,
																				 @"img"		: @""}];
						[_availableEmotions addObject:vo];
						
					}];
					
					if (++cnt == [[[[NSUserDefaults standardUserDefaults] objectForKey:@"pico_candy"] objectForKey:kFreeStickerPak] count]) {
						_totalPages = ((int)([_availableEmotions count] / (COLS_PER_ROW * ROWS_PER_PAGE))) + 1;
						_scrollView.contentSize = CGSizeMake(_totalPages * _scrollView.frame.size.width, _scrollView.frame.size.height);
						
						_paginationView = [[HONEmotionPaginationView alloc] initAtPosition:CGPointMake(160.0, 242.0) withTotalPages:_totalPages];
						[_paginationView updateToPage:0];
						[self addSubview:_paginationView];
						
						[self _buildGrid];
					}
				}];
			}
			
			
//			for (NSDictionary *dict in [[HONStickerAssistant sharedInstance] fetchStickersForPakType:HONStickerPakTypeInviteBonus])
//				[_availableEmotions addObject:[HONEmotionVO emotionWithDictionary:dict]];
		}
		
/*
		_totalPages = ((int)([_availableEmotions count] / (COLS_PER_ROW * ROWS_PER_PAGE))) + 1;
		
		_bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"emojiPanelBG"]];
		[self addSubview:_bgImageView];
		
		_scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 272.0)];
		_scrollView.contentSize = CGSizeMake(_totalPages * _scrollView.frame.size.width, _scrollView.frame.size.height);
		_scrollView.showsHorizontalScrollIndicator = NO;
		_scrollView.showsVerticalScrollIndicator = NO;
		_scrollView.pagingEnabled = YES;
		_scrollView.delegate = self;
		[self addSubview:_scrollView];
		
		_paginationView = [[HONEmotionPaginationView alloc] initAtPosition:CGPointMake(160.0, 242.0) withTotalPages:_totalPages];
		[_paginationView updateToPage:0];
		[self addSubview:_paginationView];
		
//		_deleteButtonImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"emojiDeleteButton_nonActive"]];
//		_deleteButtonImageView.frame = CGRectOffset(_deleteButtonImageView.frame, 0.0, self.frame.size.height - 49.0);
//		_deleteButtonImageView.userInteractionEnabled = YES;
//		[self addSubview:_deleteButtonImageView];
		
		UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
		deleteButton.frame = CGRectMake(0.0, self.frame.size.height - 49.0, 320.0, 49.0);
		[deleteButton setBackgroundImage:[UIImage imageNamed:@"emojiDeleteButton_nonActive"] forState:UIControlStateNormal];
		[deleteButton setBackgroundImage:[UIImage imageNamed:@"emojiDeleteButton_Active"] forState:UIControlStateHighlighted];
		[deleteButton addTarget:self action:@selector(_goDelete) forControlEvents:UIControlEventTouchDown];
		[self addSubview:deleteButton];
		
		[self _buildGrid];
*/
	}
	
	return (self);
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//	CGPoint touchLocation = [[touches anyObject] locationInView:self];
//	
//	if (CGRectContainsPoint(_deleteButtonImageView.frame, touchLocation))
//		_deleteButtonImageView.image = [UIImage imageNamed:@"emojiDeleteButton_Active"];
//}
//
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//	CGPoint touchLocation = [[touches anyObject] locationInView:self];
//	
//	if (CGRectContainsPoint(_deleteButtonImageView.frame, touchLocation)) {
//		_deleteButtonImageView.image = [UIImage imageNamed:@"emojiDeleteButton_nonActive"];
//		[self _goDelete];
//	}
//}


#pragma mark - Navigation
- (void)_goDelete {
	if ([self.delegate respondsToSelector:@selector(emotionsPickerView:deselectedEmotion:)])
		[self.delegate emotionsPickerView:self deselectedEmotion:(HONEmotionVO *)[_selectedEmotions lastObject]];
	
	[_selectedEmotions removeLastObject];
}


#pragma mark - UI Presentation
- (void)_buildGrid {
	//NSLog(@"\t—//]> [%@ _buildGrid] (%d)", self.class, _totalPages);
	
	int cnt = 0;
	int row = 0;
	int col = 0;
	int page = 0;
	
	for (int i=0; i<_totalPages; i++) {
		UIView *holderView = [[UIView alloc] initWithFrame:CGRectMake(10.0 + (i * _scrollView.frame.size.width), 11.0, COLS_PER_ROW * kImageSpacingSize.width, ROWS_PER_PAGE * kImageSpacingSize.height)];
		[holderView setTag:i];
		[_pageViews addObject:holderView];
		[_scrollView addSubview:holderView];
	}
	
	for (HONEmotionVO *vo in _availableEmotions) {
		col = cnt % COLS_PER_ROW;
		row = (int)floor(cnt / COLS_PER_ROW) % ROWS_PER_PAGE;
		page = (int)floor(cnt / (COLS_PER_ROW * ROWS_PER_PAGE));
		
		HONEmoticonPickerItemView *emotionItemView = [[HONEmoticonPickerItemView alloc] initAtPosition:CGPointMake(col * kImageSpacingSize.width, row * kImageSpacingSize.height) withEmotion:vo withDelay:cnt * 0.125];
		emotionItemView.delegate = self;
		[_itemViews addObject:emotionItemView];
		[(UIView *)[_pageViews objectAtIndex:page] addSubview:emotionItemView];
		
		cnt++;
	}
}


#pragma mark - EmotionItemView Delegates
- (void)emotionItemView:(HONEmoticonPickerItemView *)emotionItemView selectedEmotion:(HONEmotionVO *)emotionVO {
	if ([_selectedEmotions count] < 100) {
		[_selectedEmotions addObject:emotionVO];
		
		if ([self.delegate respondsToSelector:@selector(emotionsPickerView:selectedEmotion:)])
			[self.delegate emotionsPickerView:self selectedEmotion:emotionVO];
	}
}

- (void)emotionItemView:(HONEmoticonPickerItemView *)emotionItemView deselectedEmotion:(HONEmotionVO *)emotionVO {
	[_selectedEmotions removeObject:emotionVO];
	if ([self.delegate respondsToSelector:@selector(emotionsPickerView:deselectedEmotion:)])
		[self.delegate emotionsPickerView:self deselectedEmotion:emotionVO];
}


#pragma mark - ScrollView Delegates
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	int offsetPage = MIN(MAX(round(scrollView.contentOffset.x / scrollView.frame.size.width), 0), _totalPages);
	
	if (offsetPage != _prevPage) {
		[_paginationView updateToPage:offsetPage];
		
		if ([self.delegate respondsToSelector:@selector(emotionsPickerView:didChangeToPage:withDirection:)])
			[self.delegate emotionsPickerView:self didChangeToPage:offsetPage withDirection:(_prevPage < offsetPage) ? 1 : -1];
		
		_prevPage = offsetPage;
	}
}


@end
