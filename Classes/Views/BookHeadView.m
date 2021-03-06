//
//  BookHeadView.m
//  bookcamp
//
//  Created by lin waiwai on 12/28/10.
//  Copyright 2010 __iwaiwai__. All rights reserved.
//

#import "BookHeadView.h"
// UI
#import "Three20UI/TTImageView.h"
#import "Three20UI/TTTableMessageItem.h"
#import "Three20UI/UIViewAdditions.h"
#import "Three20Style/UIFontAdditions.h"

// Style
#import "Three20Style/TTGlobalStyle.h"
#import "Three20Style/TTDefaultStyleSheet.h"

// Core
#import "Three20Core/TTCorePreprocessorMacros.h"
#import "Three20Core/NSDateAdditions.h"

static const int  DefaultAuthorThumbHeight  = BKAuthorThumbHeight;
static const int DefaultBookThumbWidth = 105;
static const int DefaultBookThumbHeight = 142;  

static const int DefaultLinkButtonWidth = BKDefaultLinkButtonWidth;
static const int DefaultLinkButtonHeight = BKDefaultLinkButtonHeight;

@implementation BookHeadView

@synthesize bookThumb =  _bookThumb;
@synthesize info = _info;
@synthesize ratingLabel = _ratingLabel;
@synthesize ratingView = _ratingView;

@synthesize engine = _engine;
@synthesize weiboClient  = _weiboClient;


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
	TT_RELEASE_SAFELY(_item);
	TT_RELEASE_SAFELY(_bookThumb);
	TT_RELEASE_SAFELY(_info);
	TT_RELEASE_SAFELY(_ratingView);
	TT_RELEASE_SAFELY(_engine);
	TT_RELEASE_SAFELY(_weiboClient);
	TT_RELEASE_SAFELY (_HUD);
    [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
-(id)object{
	return _item;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setObject:(id)object {	
	if (self.object != object) {
		[_item release];
		_item = [object retain];
		
		BookObject* item = object;
		if (item.thumbURL) {
			self.bookThumb.thumbURL = item.thumbURL;
		}
		
		NSString *format = @"<div class=\"booknameStyle\">%@</div><div class=\"bookItemStyle\">%@</div><div class=\"bookItemStyle\">%@</div><div class=\"bookItemStyle\">%@</div><div class=\"bookItemStyle\">%@</div>";
		
		NSString *author = @"";
		if ([item.authors count] > 0) {
			author = [item.authors objectAtIndex:0];
		}
		
		
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setLocale:[NSLocale currentLocale]];
		[dateFormatter setDateFormat:@"yyyy-MM-dd"];
		
		NSString *infoStr = [NSString stringWithFormat:format,
							 item.bookName? item.bookName:@"",author?author:@"",
							 [dateFormatter stringFromDate:item.pubdate]?[dateFormatter stringFromDate:item.pubdate]:@"",item.publisher?item.publisher:@"", 
							 item.pages?[NSString stringWithFormat:BCLocalizedString(@"page format", @"page format") , item.pages]:@"" ];
		
		TTStyledText *styleText = [TTStyledText textFromXHTML:infoStr lineBreaks:YES URLs:NO];
		if (item.thumbURL) {
			styleText.width = self.width - (BKContentMargin*3 + DefaultBookThumbWidth );
		} else {
			styleText.width = self.width - BKContentMargin * 2;
		}
		self.info.text = styleText;
		
		if (item.averageRate) {
			
			[self.ratingView setRating:item.averageRate];
			self.ratingLabel.text = [NSString stringWithFormat:BCLocalizedString(@"rating format", @"rating format"),item.averageRate];
		}
		//		if (item.bookCommentURL) {
		//			self.bookCommentLink.URL = item.bookCommentURL; 
		//		}
		//		if (item.parityURL){
		//			self.parityLink.URL =  item.parityURL;
		//		}
		//		if (item.evaluationNum) {
		//			self.evaluationNumLabel.text =[NSString stringWithFormat:BCLocalizedString(@"(%@)HaveGiveAEvaluation",
		//																					   @"the number of person who have give the book a evaluation"),
		//										   item.evaluationNum];
		//
		//		}
	}
}




///////////////////////////////////////////////////////////////////////////////////////////////////
-(UILabel*)ratingLabel{
	if (!_ratingLabel) {
		_ratingLabel = [[UILabel alloc] init];
		_ratingLabel.backgroundColor  = [UIColor clearColor];
		_ratingLabel.font = [UIFont systemFontOfSize:14];
		_ratingLabel.textColor = RGBCOLOR(116,116,116);
		[self addSubview:_ratingLabel];
	}
	return _ratingLabel;
}



///////////////////////////////////////////////////////////////////////////////////////////////////
-(TTThumbView*)bookThumb{
	if (!_bookThumb) {
		_bookThumb = [[TTThumbView alloc] init];
		[_bookThumb setStylesWithSelector:@"bookViewThumbStyle:"];
		[self addSubview:_bookThumb];
		[_bookThumb addTarget:self action:@selector(postNewStatus) forControlEvents:UIControlEventTouchUpInside];
	}
	return _bookThumb;
}

- (void)postStatusDidSucceed:(WeiboClient*)sender obj:(NSObject*)obj;
{
	Draft *sentDraft = nil;
	if (sender.context && [sender.context isKindOfClass:[Draft class]]) {
		sentDraft = (Draft *)sender.context;
		[sentDraft autorelease];
	}
	
    if (sender.hasError) {
        [sender alert];	
        return;
    }
    
    NSDictionary *dic = nil;
    if (obj && [obj isKindOfClass:[NSDictionary class]]) {
        dic = (NSDictionary*)obj;    
    }
	
    if (dic) {
        Status* sts = [Status statusWithJsonDictionary:dic];
		if (sts) {
			//delete draft!
			if (sentDraft) {
				
			}
		}
    }
	
}

- (void)postNewStatus {
	BookViewController *bookViewController = [TTNavigator navigator].visibleViewController ;

	UIViewController *controller = [OAuthController controllerToEnterCredentialsWithEngine: self.engine delegate: self];
	if (![bookViewController isKindOfClass:[BookViewController class]]){
		return;
	}
	if (controller) {
		 
		[bookViewController presentModalViewController: controller animated: YES];
		return;
		
	}
	
	UIView *navView = [TTNavigator navigator].visibleViewController.navigationController.view;
	
	UIView *customView =  [[[UIView alloc] initWithFrame:navView.frame] autorelease];
	customView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.5];

	[customView addSubview: [self makeComposeView:customView.frame]];

	self.HUD.customView =customView;
	self.HUD.mode = MBProgressHUDModeCustomView;
	[self.HUD show:YES];

	
	
}

-(MBProgressHUD*)HUD{
	if (!_HUD) {
		UIView *navView = [TTNavigator navigator].visibleViewController.navigationController.view;
		_HUD = [[MBProgressHUD alloc] initWithView:[TTNavigator navigator].visibleViewController.navigationController.view];
		
		//HUD.style = TTSTYLE(progressHUDStyle);
		
		// Add HUD to screen
		[[TTNavigator navigator].visibleViewController.navigationController.view addSubview:_HUD];
		
		// Regisete for HUD callbacks so we can remove it from the window at the right time
		_HUD.delegate = self;
		
	}
	return _HUD;
}

-(void)closeWindow:(TTButton*)btn{
	[self.HUD hide:YES];
}


#define cancelBtnHeight 24.f
#define cancelBtnWidth 24.f
#define StatuseTextViewTag 1
#define ContainerViewTag 2


-(UIView*)makeComposeView :(CGRect)frame{
	CGFloat leftOffset = 20;
	CGFloat inset = 6;
	UIView *container = [[[UIView alloc] initWithFrame:CGRectMake(leftOffset,  
																  CGRectGetHeight(frame) / 4 - cancelBtnHeight / 2,
																  CGRectGetWidth(frame) - 2 * leftOffset + cancelBtnWidth / 2 ,
																  CGRectGetHeight(frame) / 2 - cancelBtnWidth / 2)] autorelease];
	container.backgroundColor = [UIColor clearColor];
	container.tag = ContainerViewTag;
	TTView *compose = [[[TTView alloc] initWithFrame:CGRectMake(0,  cancelBtnHeight / 2, 
															   CGRectGetWidth(container.frame) - cancelBtnWidth / 2  , 
															   CGRectGetHeight(container.frame) - cancelBtnHeight / 2)] autorelease];
	compose.backgroundColor = [UIColor clearColor];
	compose.style = TTSTYLE(composeViewStyle);
	TTButton *cancelBtn = [[[TTButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(container.frame) - cancelBtnWidth, 0,
																	 cancelBtnWidth, cancelBtnHeight)] autorelease];
	
	cancelBtn.backgroundColor = [UIColor clearColor];
	[cancelBtn setStylesWithSelector:@"closeButtonStyle:"];
	[cancelBtn setTitle:BCLocalizedString(@"cancel", @"cancel") forState:UIControlStateNormal];
	[cancelBtn addTarget:self action:@selector(closeWindow:) forControlEvents:UIControlEventTouchUpInside];
	[container addSubview:cancelBtn];
	[container addSubview:compose];
	
	TTLabel *titleLable = [[[TTLabel alloc] initWithFrame:CGRectMake(leftOffset, 10, 
																	 CGRectGetWidth(container.frame) - leftOffset *2, 0)] autorelease];
	titleLable.text = BCLocalizedString(@"share book title", @"share book title");
	titleLable.style =  TTSTYLE(sharebookTitleStyle);
	titleLable.backgroundColor = [UIColor clearColor];
	[titleLable sizeToFit];

	UITextView *textInput =  [[[UITextView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(titleLable.frame) + 12,  CGRectGetWidth(compose.frame) - 10 *2, 130)] autorelease];
	textInput.delegate = self;
	textInput.backgroundColor = [UIColor clearColor];
	NSString *format =  BCLocalizedString(@"I am reading %@. Recommend it to friends", @"I am reading %@. Recommend it to friends")	;
	textInput.tag = StatuseTextViewTag;
	BookObject* item = self.object;
	if (item) {
		textInput.text = [NSString stringWithFormat:format, item.bookName ];
	}

	[compose addSubview:textInput];
	[compose addSubview:titleLable];
	
	
	TTButton *submitBtn = [[[TTButton alloc] init] autorelease];
	
	submitBtn.backgroundColor = [UIColor clearColor];
	[submitBtn setStylesWithSelector:@"submitButtonStyle:"];
	[submitBtn setTitle:BCLocalizedString(@"share", @"share") forState:UIControlStateNormal];
	[submitBtn addTarget:self action:@selector(closeWindow:) forControlEvents:UIControlEventTouchUpInside];
	[submitBtn sizeToFit];
	submitBtn.frame = CGRectMake(compose.width - submitBtn.width - inset*2, compose.height - submitBtn.height - inset+2,
								 submitBtn.width, submitBtn.height);
	
	[compose addSubview:submitBtn];
	
	
	return container;
}	

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	[self animateTextView: YES];
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // Any new character added is passed in as the "text" parameter
    if ([text isEqualToString:@"\n"]) {
        // Be sure to test for equality using the "isEqualToString" message
        [textView resignFirstResponder];
		
        // Return FALSE so that the final '\n' character doesn't get added
        return FALSE;
    }
    // For any other character return TRUE so that the text gets added to the view
    return TRUE;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	[self animateTextView: NO];
}



- (void) animateTextView: (BOOL) up
{
	int movementDistance ;
	UIView *componseView = [self.HUD viewWithTag:ContainerViewTag];
		movementDistance = 85; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
	
    int movement = (up ? -movementDistance : movementDistance);
	
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    componseView.frame = CGRectOffset(componseView.frame, 0, movement);
    [UIView commitAnimations];
}



-(void)submitStatus{
	
		BookViewController *bookViewController = [TTNavigator navigator].visibleViewController ;
	Draft *draft = [[Draft alloc]initWithType:DraftTypeNewTweet];
	
	WeiboClient *client = [[WeiboClient alloc] initWithTarget:self 
													   engine:[OAuthEngine currentOAuthEngine]
													   action:@selector(postStatusDidSucceed:obj:)];
	
	UITextView *statusView =  [self.HUD viewWithTag:StatuseTextViewTag];
	draft.text = statusView.text;
	client.context = [draft retain];
	draft.draftStatus = DraftStatusSending;
	
	if([bookViewController isKindOfClass:[BookViewController class]]){
		draft.attachmentImage = [bookViewController imageFromCurrentBook];
	} 
	[client upload:draft.attachmentData status:draft.text];
}



-(OAuthEngine*)engine{
	if (!_engine){
		_engine = [[OAuthEngine alloc] initOAuthWithDelegate: self];
		_engine.consumerKey = kOAuthConsumerKey;
		_engine.consumerSecret = kOAuthConsumerSecret;
		[OAuthEngine setCurrentOAuthEngine:_engine];
	}
	return _engine;
}


//=============================================================================================================================
#pragma mark OAuthEngineDelegate
#pragma mark save the user info 

- (void) storeCachedOAuthData: (NSString *) data forUsername: (NSString *) username {
	NSUserDefaults			*defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject: data forKey: @"authData"];
	[defaults synchronize];
}

- (NSString *) cachedOAuthDataForUsername: (NSString *) username {
	return [[NSUserDefaults standardUserDefaults] objectForKey: @"authData"];
}

- (void)removeCachedOAuthDataForUsername:(NSString *) username{
	NSUserDefaults			*defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults removeObjectForKey: @"authData"];
	[defaults synchronize];
}

//=============================================================================================================================
#pragma mark OAuthSinaWeiboControllerDelegate
- (void) OAuthController: (OAuthController *) controller authenticatedWithUsername: (NSString *) username {
	NSLog(@"Authenicated for %@", username);
}

- (void) OAuthControllerFailed: (OAuthController *) controller {
	NSLog(@"Authentication Failed!");
	//UIViewController *controller = [OAuthController controllerToEnterCredentialsWithEngine: _engine delegate: self];
  	[[Factory sharedInstance] triggerWarning:BCLocalizedString("Authentication Failed", "Authentication Failed!")];
	
	BookViewController *bookViewController = [TTNavigator navigator].visibleViewController ;
	if (controller) 
		[bookViewController presentModalViewController: controller animated: YES];
	
	
}

- (void) OAuthControllerCanceled: (OAuthController *) controller {
	NSLog(@"Authentication Canceled.");
	//UIViewController *controller = [OAuthController controllerToEnterCredentialsWithEngine: _engine delegate: self];
//	BookViewController *bookViewController = [TTNavigator navigator].visibleViewController ;
//	if (controller) 
//		[self presentModalViewController: controller animated: YES];
	
}




///////////////////////////////////////////////////////////////////////////////////////////////////
-(TTStyledTextLabel*)info{
	if (!_info) {
		_info =  [[TTStyledTextLabel alloc] init];
		_info.backgroundColor = [UIColor clearColor];
		[self addSubview:_info];
	}
	
	return _info;
	
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (RatingView*)ratingView {
	if (!_ratingView) {
		_ratingView = [[RatingView alloc] initWithFrame:CGRectMake(0, 0, 105, 20)];
		[self addSubview:_ratingView];
	}
	return _ratingView;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
-(void)layoutSubviews{
	[super layoutSubviews];
	
	CGFloat left = 0;
	if (_bookThumb) {
		_bookThumb.frame = CGRectMake(BKContentMargin, BKContentMargin,
								   DefaultBookThumbWidth, DefaultBookThumbHeight);
		left += BKContentMargin + DefaultBookThumbWidth + BKContentMargin;
	} else {
		left = BKContentMargin;
	}
	

	
	CGFloat width = self.width - left;
	CGFloat top = BKContentMargin;
	
	if (_info) {
		_info.frame = CGRectMake(left, top, width, 0);
		[_info sizeToFit];
		_info.frame = CGRectMake(left, top, _info.width, _info.height);
		top += _info.height;
	}

	if ((int)[_ratingView rating]!=RatingHidden) {
		[_ratingView setFrame:CGRectMake( left, top, RatingViewWidth, RatingViewHeight)];
		
	}else {
		[_ratingView setFrame:CGRectZero];
	}
	
	if (_ratingLabel.text.length) {
		_ratingLabel.frame = CGRectMake(left+RatingViewWidth +  BKContentMargin, top, _ratingLabel.font.ttLineHeight*2, _ratingLabel.font.ttLineHeight);
	}else {
		_ratingLabel.frame = CGRectZero;
	}
//	if (_evaluationNumLabel.text.length) {
//		if (_ratingLabel.text.length) {
//			_evaluationNumLabel.frame =  CGRectMake(CGRectGetMaxX(_ratingLabel.frame), top, 120, _evaluationNumLabel.font.ttLineHeight);
//		}
//		else {
//			_evaluationNumLabel.frame =  CGRectMake(left+RatingViewWidth, top, width - RatingViewWidth, _evaluationNumLabel.font.ttLineHeight);
//		}
//	}else {
//		_evaluationNumLabel.frame = CGRectZero;
//	}
//	if ((int)[_ratingView rating]!=RatingHidden)
//	top += RatingViewHeight + BKContentSmallMargin;
//
//	
//	if ([_bookCommentLink.URL length]) {
//		_bookCommentLink.frame = CGRectMake(left, top, DefaultLinkButtonWidth, DefaultLinkButtonHeight);
//		[_bookCommentLink setTitle:BCLocalizedString(@"BookCommentLink",@"the link button text of BookComment") forState:UIControlStateNormal];
//		
//
//		top += DefaultLinkButtonHeight;
//	} else {
//		_bookCommentLink.frame = CGRectZero;
//	}
//	
//	if ([_parityLink.URL length]) {
//		_parityLink.frame = CGRectMake(left, top, DefaultLinkButtonWidth, DefaultLinkButtonHeight);
//		[_parityLink setTitle:BCLocalizedString(@"ParityLink",@"the link button text of ParityLink") forState:UIControlStateNormal];
//		top += DefaultLinkButtonHeight;
//	} else {
//		_parityLink.frame = CGRectZero;
//	}

}



///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {

    if ([super initWithFrame:frame]) {
		self.backgroundColor = [UIColor whiteColor];
        // Initialization code.
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/



@end
