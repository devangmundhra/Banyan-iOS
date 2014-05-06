//
//  BNIntroViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 4/15/14.
//
//

#import "BNIntroViewController.h"
#import "UIImage+ImageEffects.h"
#import "UIImage+Create.h"
#import "IFTTTJazzHands.h"
#import "BButton.h"

#define NUMBER_OF_INTRO_PAGES 5
#define timeForPage(page) (NSInteger)(self.view.frame.size.width * (page - 1))

@interface BNIntroViewController ()
@property (strong, nonatomic) UIPageControl *pageControl;

@property (strong, nonatomic) UILabel *firstPageLabel;
@property (strong, nonatomic) UILabel *secondPageLabel;
@property (strong, nonatomic) UILabel *thirdPageLabel;
@property (strong, nonatomic) UILabel *fourthPageLabel;
@property (strong, nonatomic) UILabel *fifthPageLabel;

@property (strong, nonatomic) UIImageView *logoImageView;
@property (strong, nonatomic) UIImageView *screenshotImageView;
@property (strong, nonatomic) UIImageView *screenshotBWImageView;
@property (strong, nonatomic) UIImageView *bottomScreenshotImageView;
@property (strong, nonatomic) UIImageView *ppImageView;
@property (strong, nonatomic) UIImageView *plusexplainImageView;
@property (strong, nonatomic) UIImageView *sampleStoryImageView;
@property (strong, nonatomic) UIImageView *sampleStory1ImageView;
@property (strong, nonatomic) UIImageView *sampleStory2ImageView;
@property (strong, nonatomic) UIImageView *shareImageView;

@property (strong, nonatomic) UIImageView *firstPageBackground;
@property (strong, nonatomic) UIImageView *secondPageBackground;
@property (strong, nonatomic) UIImageView *thirdPageBackground;
@property (strong, nonatomic) UIImageView *fourthPageBackground;
@property (strong, nonatomic) UIImageView *fifthPageBackground;

@property (strong, nonatomic) BButton *getStartedButton;
@end

@implementation BNIntroViewController
@synthesize firstPageLabel, secondPageLabel, thirdPageLabel, fourthPageLabel, fifthPageLabel;
@synthesize logoImageView, screenshotImageView, screenshotBWImageView, ppImageView, bottomScreenshotImageView, plusexplainImageView, shareImageView;
@synthesize sampleStoryImageView, sampleStory1ImageView, sampleStory2ImageView;
@synthesize firstPageBackground, secondPageBackground, thirdPageBackground, fourthPageBackground, fifthPageBackground;
@synthesize getStartedButton;

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Intro view"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.view.backgroundColor = BANYAN_WHITE_COLOR;
    self.scrollView.contentSize = CGSizeMake(NUMBER_OF_INTRO_PAGES * CGRectGetWidth(self.view.frame),
                                             CGRectGetHeight(self.view.frame));
    
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.bounces = NO;
    
    [self placeViews];
    [self configureAnimation];
}

- (void)placeViews
{
#define TEXT_EDGE_INSTES 10
#define TEXT_FONT_SIZE 16
#define BIG_SCREEN (CGRectGetHeight(viewBounds) > 500)
    CGPoint center;
    const CGRect viewBounds = self.view.bounds;
    
    // Set the page controls
    const CGFloat pageControlHeight = 20;
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(viewBounds), pageControlHeight)];
    self.pageControl.numberOfPages = NUMBER_OF_INTRO_PAGES;
    self.pageControl.currentPage = 0;
    center = self.view.center;
    center.y = CGRectGetHeight(viewBounds) - pageControlHeight/2;
    self.pageControl.center = center;
    [self.view insertSubview:self.pageControl aboveSubview:self.scrollView];
    
    // Images
    UIImage *logoImage = [UIImage imageNamed:@"BanyanLogoColor"];
    UIImage *introGreenBkg = [UIImage imageNamed:@"IntroBkg2"];
    UIImage *introYellowBkg = [UIImage imageNamed:@"IntroBkg3"];
    UIImage *introPinkBkg = [UIImage imageNamed:@"IntroBkg1"];
    UIImage *screenshotImage = [UIImage imageNamed:@"top_screenshot_color_nologo"];
    UIImage *screenshotImageBW = [UIImage imageNamed:@"top_screenshot_bw_nologo"];
    UIImage *ppImage = [UIImage imageNamed:@"plusplus"];
    UIImage *plusExplainImage = [UIImage imageNamed:@"plus_explain"];
    UIImage *bottomScreenshotImage = [UIImage imageNamed:@"bottom_screenshot_bw"];
    UIImage *sampleStoryImage = [UIImage imageNamed:@"samplestory"];
    UIImage *sampleStory1Image = [UIImage imageNamed:@"sample_story1"];
    UIImage *sampleStory2Image = [UIImage imageNamed:@"sample_story2"];
    UIImage *shareImage = [UIImage imageNamed:@"share_intro"];
    
    // FIRST set the different backgrounds
    self.firstPageBackground = [[UIImageView alloc] initWithFrame:viewBounds];
    self.firstPageBackground.contentMode = UIViewContentModeScaleAspectFill;
    self.firstPageBackground.clipsToBounds = YES;
    self.firstPageBackground.image = [introGreenBkg applyLightEffect];
    [self.scrollView addSubview:self.firstPageBackground];
    
    self.secondPageBackground = [[UIImageView alloc] initWithFrame:viewBounds];
    self.secondPageBackground.contentMode = UIViewContentModeScaleAspectFill;
    self.secondPageBackground.clipsToBounds = YES;
    self.secondPageBackground.image = [introPinkBkg applyLightEffect];
    self.secondPageBackground.frame = CGRectOffset(self.secondPageBackground.frame, timeForPage(2), 0);
    [self.scrollView addSubview:self.secondPageBackground];
    
    self.thirdPageBackground = [[UIImageView alloc] initWithFrame:viewBounds];
    self.thirdPageBackground.contentMode = UIViewContentModeScaleAspectFill;
    self.thirdPageBackground.clipsToBounds = YES;
    self.thirdPageBackground.image = [introYellowBkg applyLightEffect];
    self.thirdPageBackground.frame = CGRectOffset(self.thirdPageBackground.frame, timeForPage(3), 0);
    [self.scrollView addSubview:self.thirdPageBackground];
    
    self.fourthPageBackground = [[UIImageView alloc] initWithFrame:viewBounds];
    self.fourthPageBackground.contentMode = UIViewContentModeScaleAspectFill;
    self.fourthPageBackground.clipsToBounds = YES;
    self.fourthPageBackground.image = [introGreenBkg applyLightEffect];
    self.fourthPageBackground.frame = CGRectOffset(self.fourthPageBackground.frame, timeForPage(4), 0);
    [self.scrollView addSubview:self.fourthPageBackground];
    
    self.fifthPageBackground = [[UIImageView alloc] initWithFrame:viewBounds];
    self.fifthPageBackground.contentMode = UIViewContentModeScaleAspectFill;
    self.fifthPageBackground.clipsToBounds = YES;
    self.fifthPageBackground.image = [introPinkBkg applyLightEffect];
    self.fifthPageBackground.frame = CGRectOffset(self.fifthPageBackground.frame, timeForPage(5), 0);
    [self.scrollView addSubview:self.fifthPageBackground];
    
    // Set the different images
    self.logoImageView = [[UIImageView alloc] initWithImage:logoImage];
    self.logoImageView.center = self.view.center;
    self.logoImageView.frame = CGRectOffset(self.logoImageView.frame, 0, -100);
    [self.scrollView addSubview:self.logoImageView];
    
    self.screenshotImageView = [[UIImageView alloc] initWithImage:screenshotImage];
    self.screenshotImageView.center = self.view.center;
    self.screenshotImageView.frame = CGRectOffset(self.screenshotImageView.frame, timeForPage(2), -100);
    [self.scrollView addSubview:self.screenshotImageView];
    self.screenshotBWImageView = [[UIImageView alloc] initWithImage:screenshotImageBW];
    self.screenshotBWImageView.center = self.view.center;
    self.screenshotBWImageView.frame = CGRectOffset(self.screenshotBWImageView.frame, timeForPage(2), -100);
    self.screenshotImageView.alpha = 0.0;
    [self.scrollView addSubview:self.screenshotBWImageView];
    
    self.bottomScreenshotImageView = [[UIImageView alloc] initWithImage:bottomScreenshotImage];
    self.bottomScreenshotImageView.center = self.view.center;
    self.bottomScreenshotImageView.frame = CGRectOffset(self.bottomScreenshotImageView.frame, 0, 0);
    self.bottomScreenshotImageView.frame = CGRectOffset(self.bottomScreenshotImageView.frame, timeForPage(2), -100);
    self.bottomScreenshotImageView.alpha = 0.0;
    [self.scrollView addSubview:self.bottomScreenshotImageView];
    self.ppImageView = [[UIImageView alloc] initWithImage:ppImage];
    self.ppImageView.center = self.view.center;
    self.ppImageView.frame = CGRectOffset(self.ppImageView.frame, 0, 0);
    self.ppImageView.frame = CGRectOffset(self.ppImageView.frame, timeForPage(2)+115, 6);
    self.ppImageView.alpha = 0.0;
    [self.scrollView addSubview:self.ppImageView];
    
    self.plusexplainImageView = [[UIImageView alloc] initWithImage:plusExplainImage];
    self.plusexplainImageView.center = self.view.center;
    self.plusexplainImageView.frame = CGRectOffset(self.plusexplainImageView.frame, 0, 0);
    self.plusexplainImageView.frame = CGRectOffset(self.plusexplainImageView.frame, timeForPage(3), 50);
    self.plusexplainImageView.alpha = 0.0;
    [self.scrollView addSubview:self.plusexplainImageView];
    
    self.sampleStoryImageView = [[UIImageView alloc] initWithImage:sampleStoryImage];
    self.sampleStoryImageView.center = self.view.center;
    self.sampleStoryImageView.frame = CGRectOffset(self.sampleStoryImageView.frame, 0, 0);
    self.sampleStoryImageView.frame = CGRectOffset(self.sampleStoryImageView.frame, timeForPage(3), -100);
    self.sampleStoryImageView.alpha = 0.0;
    [self.scrollView addSubview:self.sampleStoryImageView];
    self.sampleStory1ImageView = [[UIImageView alloc] initWithImage:sampleStory1Image];
    self.sampleStory1ImageView.center = self.view.center;
    self.sampleStory1ImageView.frame = CGRectOffset(self.sampleStory1ImageView.frame, 0, 0);
    self.sampleStory1ImageView.frame = CGRectOffset(self.sampleStory1ImageView.frame, timeForPage(4), -30);
    [self.scrollView addSubview:self.sampleStory1ImageView];
    self.sampleStory2ImageView = [[UIImageView alloc] initWithImage:sampleStory2Image];
    self.sampleStory2ImageView.center = self.view.center;
    self.sampleStory2ImageView.frame = CGRectOffset(self.sampleStory2ImageView.frame, 0, 0);
    self.sampleStory2ImageView.frame = CGRectOffset(self.sampleStory2ImageView.frame, timeForPage(4), 70);
    [self.scrollView addSubview:self.sampleStory2ImageView];
    
    self.shareImageView = [[UIImageView alloc] initWithImage:shareImage];
    self.shareImageView.center = self.view.center;
    self.shareImageView.frame = CGRectOffset(self.shareImageView.frame, 0, 0);
    self.shareImageView.frame = CGRectOffset(self.shareImageView.frame, timeForPage(5), -50);
    [self.scrollView addSubview:self.shareImageView];
    
    // Set the texts for different pages
    self.firstPageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(viewBounds)-2*TEXT_EDGE_INSTES, CGRectGetHeight(viewBounds))];
    self.firstPageLabel.textAlignment = NSTextAlignmentCenter;
    self.firstPageLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:TEXT_FONT_SIZE];
    self.firstPageLabel.textColor = BANYAN_WHITE_COLOR;
    self.firstPageLabel.text = @"Banyan helps you to create stories with people you love, and share it with anyone you choose";
    self.firstPageLabel.numberOfLines = 0;
    [self.firstPageLabel sizeToFit];
    self.firstPageLabel.center = self.view.center;
    self.firstPageLabel.frame = CGRectOffset(self.firstPageLabel.frame, 0, 100);
    [self.scrollView addSubview:self.firstPageLabel];
    
    self.secondPageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(viewBounds)-2*TEXT_EDGE_INSTES, CGRectGetHeight(viewBounds))];
    self.secondPageLabel.textAlignment = NSTextAlignmentCenter;
    self.secondPageLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:TEXT_FONT_SIZE];
    self.secondPageLabel.textColor = BANYAN_WHITE_COLOR;
    self.secondPageLabel.text = @"Create stories with friends, family or openly with everyone";
    self.secondPageLabel.numberOfLines = 0;
    [self.secondPageLabel sizeToFit];
    self.secondPageLabel.center = self.view.center;
    self.secondPageLabel.frame = CGRectOffset(self.secondPageLabel.frame, timeForPage(2), 80);
    [self.scrollView addSubview:self.secondPageLabel];
    
    self.thirdPageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(viewBounds)-2*TEXT_EDGE_INSTES, CGRectGetHeight(viewBounds))];
    self.thirdPageLabel.textAlignment = NSTextAlignmentCenter;
    self.thirdPageLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:TEXT_FONT_SIZE];
    self.thirdPageLabel.textColor = BANYAN_WHITE_COLOR;
    self.thirdPageLabel.text = @"Add text, pictures, audio and more to each piece of the story";
    self.thirdPageLabel.numberOfLines = 0;
    [self.thirdPageLabel sizeToFit];
    self.thirdPageLabel.center = self.view.center;
    self.thirdPageLabel.frame = CGRectOffset(self.thirdPageLabel.frame, timeForPage(3), 120);
    [self.scrollView addSubview:self.thirdPageLabel];
    
    self.fourthPageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(viewBounds)-2*TEXT_EDGE_INSTES, CGRectGetHeight(viewBounds))];
    self.fourthPageLabel.textAlignment = NSTextAlignmentCenter;
    self.fourthPageLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:TEXT_FONT_SIZE];
    self.fourthPageLabel.textColor = BANYAN_WHITE_COLOR;
    self.fourthPageLabel.text = @"Browse public stories or stories you have been invited to!";
    self.fourthPageLabel.numberOfLines = 0;
    [self.fourthPageLabel sizeToFit];
    self.fourthPageLabel.center = self.view.center;
    self.fourthPageLabel.frame = CGRectOffset(self.fourthPageLabel.frame, timeForPage(4), 150);
    [self.scrollView addSubview:self.fourthPageLabel];
    
    self.fifthPageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(viewBounds)-2*TEXT_EDGE_INSTES, CGRectGetHeight(viewBounds))];
    self.fifthPageLabel.textAlignment = NSTextAlignmentCenter;
    self.fifthPageLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:TEXT_FONT_SIZE];
    self.fifthPageLabel.textColor = BANYAN_WHITE_COLOR;
    self.fifthPageLabel.text = @"Keep the story to yourself, share it with a special few or let the world know about it.\rStories can be shared as photo albums on facebook or viewed on banyan.io";

    self.fifthPageLabel.numberOfLines = 0;
    [self.fifthPageLabel sizeToFit];
    self.fifthPageLabel.center = self.view.center;
    self.fifthPageLabel.frame = CGRectOffset(self.fifthPageLabel.frame, timeForPage(5), BIG_SCREEN ? 150 : 140);
    [self.scrollView addSubview:self.fifthPageLabel];
    
    self.getStartedButton = [[BButton alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(viewBounds) - 100, BIG_SCREEN ? 40 : 30)
                                                     type:BButtonTypeSuccess
                                                     style:BButtonStyleBootstrapV3];
    self.getStartedButton.layer.cornerRadius = 2.0f;
    self.getStartedButton.layer.masksToBounds = YES;
    
    [self.getStartedButton.titleLabel setFont:[UIFont fontWithName:@"Roboto-Bold" size:TEXT_FONT_SIZE]];
    [self.getStartedButton.titleLabel setTextAlignment:NSTextAlignmentRight];
    [self.getStartedButton setTitle:@"Get Started" forState:UIControlStateNormal];
//    [self.getStartedButton addAwesomeIcon:FAIconArrowRight beforeTitle:NO];
    self.getStartedButton.center = self.view.center;
    self.getStartedButton.frame = CGRectOffset(self.getStartedButton.frame, timeForPage(5), BIG_SCREEN ? 230 : 205);
    [self.getStartedButton addTarget:self action:@selector(dismissIntroView:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.getStartedButton];
    
#undef TEXT_EDGE_INSETS
#undef TEXT_FONT_SIZE
#undef BIG_SCREEN
}

- (void)configureAnimation
{
    // Move logo from page 1 to 2 and resize
    [self.scrollView insertSubview:self.logoImageView aboveSubview:self.screenshotBWImageView];
    IFTTTFrameAnimation *logoAnimation = [IFTTTFrameAnimation animationWithView:self.logoImageView];
    [self.animator addAnimation:logoAnimation];
    [logoAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andFrame:self.logoImageView.frame]];
    [logoAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:CGRectOffset(CGRectMake(self.logoImageView.frame.origin.x,
                                                                                                                        self.logoImageView.frame.origin.y,
                                                                                                                        self.logoImageView.frame.size.width*0.13,
                                                                                                                        self.logoImageView.frame.size.height*0.13),
                                                                                                             timeForPage(2)+220,
                                                                                                             -6)]];
    // Move logo from 2 to 3
    [logoAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(CGRectMake(self.logoImageView.frame.origin.x,
                                                                                                                        self.logoImageView.frame.origin.y,
                                                                                                                        self.logoImageView.frame.size.width*0.13,
                                                                                                                        self.logoImageView.frame.size.height*0.13),
                                                                                                             timeForPage(3)+220,
                                                                                                             -6)]];

    IFTTTAlphaAnimation *logoAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.logoImageView];
    [self.animator addAnimation:logoAlphaAnimation];
    [logoAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:1.0]];
    [logoAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:1.0]];
    [logoAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:0.0]];

    
    // Also change alpha of the screenshotImageView and screenshotBWImageView
    // Reduce alpha of topscreenshot color
    IFTTTAlphaAnimation *topscreenshotalphaAnimation = [IFTTTAlphaAnimation animationWithView:self.screenshotImageView];
    [self.animator addAnimation:topscreenshotalphaAnimation];
    [topscreenshotalphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:1.0]];
    [topscreenshotalphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1.85) andAlpha:0.8]];
    [topscreenshotalphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:0.0]];
    
    // Increase alpha of top screenshot bw
    IFTTTAlphaAnimation *topscreenshot_bw_alphaAnimation = [IFTTTAlphaAnimation animationWithView:self.screenshotBWImageView];
    [self.animator addAnimation:topscreenshot_bw_alphaAnimation];
    [topscreenshot_bw_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1) andAlpha:0.0]];
    [topscreenshot_bw_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(1.85) andAlpha:0.2]];
    [topscreenshot_bw_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:0.7]];
    [topscreenshot_bw_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:0.0]];
    
    // Move topscreenshot_bw from 2 to 3
    IFTTTFrameAnimation *topscreenshot_bw_frameAnimation = [IFTTTFrameAnimation animationWithView:self.screenshotBWImageView];
    [self.animator addAnimation:topscreenshot_bw_frameAnimation];
    [topscreenshot_bw_frameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:self.screenshotBWImageView.frame]];
    [topscreenshot_bw_frameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(self.screenshotBWImageView.frame,
                                                                                                                               timeForPage(2), 0)]];
    

    // Move bottomscreenshot_bw from 2 to 3 to 4
    IFTTTFrameAnimation *bottomscreenshot_bw_frameAnimation = [IFTTTFrameAnimation animationWithView:self.bottomScreenshotImageView];
    [self.animator addAnimation:bottomscreenshot_bw_frameAnimation];
    [bottomscreenshot_bw_frameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:self.bottomScreenshotImageView.frame]];
    [bottomscreenshot_bw_frameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(self.bottomScreenshotImageView.frame,
                                                                                                                               timeForPage(2), 0)]];
    [bottomscreenshot_bw_frameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3.5) andFrame:CGRectOffset(self.bottomScreenshotImageView.frame,
                                                                                                                                  timeForPage(2.5), 0)]];
    [bottomscreenshot_bw_frameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andFrame:CGRectOffset(CGRectMake(self.bottomScreenshotImageView.frame.origin.x,
                                                                                                                                             self.bottomScreenshotImageView.frame.origin.y,
                                                                                                                                             self.bottomScreenshotImageView.frame.size.width*0.5,
                                                                                                                                             self.bottomScreenshotImageView.frame.size.height*0.5),
                                                                                                                                  timeForPage(3)+76, 0)]];
    
    // Move plusplus from 2 to 3 to 4
    IFTTTFrameAnimation *plusplus_frameAnimation = [IFTTTFrameAnimation animationWithView:self.ppImageView];
    [self.animator addAnimation:plusplus_frameAnimation];
    [plusplus_frameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andFrame:self.ppImageView.frame]];
    [plusplus_frameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2.2) andFrame:CGRectOffset(CGRectMake(self.ppImageView.frame.origin.x,
                                                                                                                                    self.ppImageView.frame.origin.y,
                                                                                                                                    self.ppImageView.frame.size.width*2.2,
                                                                                                                                    self.ppImageView.frame.size.height*2.2),
                                                                                                                         timeForPage(1.2), 0)]];
    [plusplus_frameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2.7) andFrame:CGRectOffset(CGRectMake(self.ppImageView.frame.origin.x,
                                                                                                                                    self.ppImageView.frame.origin.y,
                                                                                                                                    self.ppImageView.frame.size.width*2.7,
                                                                                                                                    self.ppImageView.frame.size.height*2.7),
                                                                                                                   timeForPage(1.7), 0)]];
    [plusplus_frameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:CGRectOffset(self.ppImageView.frame,
                                                                                                                       timeForPage(2), 0)]];
    [plusplus_frameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andFrame:CGRectOffset(self.ppImageView.frame,
                                                                                                                       timeForPage(3), 0)]];
    
    // Increase alpha of bottomscreenshot_bw between 2 and 3 and decrease between 3 and 4
    IFTTTAlphaAnimation *bottomscreen_alphaAnimation = [IFTTTAlphaAnimation animationWithView:self.bottomScreenshotImageView];
    [self.animator addAnimation:bottomscreen_alphaAnimation];
    [bottomscreen_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:0.0]];
    [bottomscreen_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:0.8]];
    [bottomscreen_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:0.0]];
    
    // Increase alpha of plusplus between 2 and 3
    IFTTTAlphaAnimation *plusplus_alphaAnimation = [IFTTTAlphaAnimation animationWithView:self.ppImageView];
    [self.animator addAnimation:plusplus_alphaAnimation];
    [plusplus_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:0.0]];
    [plusplus_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2.3) andAlpha:1.0]];
    [plusplus_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2.7) andAlpha:1.0]];
    [plusplus_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:1.0]];
    [plusplus_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3.5) andAlpha:0.0]];
    
    // Increase alpha of plusexplain between 2 and 3
    IFTTTAlphaAnimation *plusexplain_alphaAnimation = [IFTTTAlphaAnimation animationWithView:self.plusexplainImageView];
    [self.animator addAnimation:plusexplain_alphaAnimation];
    [plusexplain_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(2) andAlpha:0.0]];
    [plusexplain_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:1.0]];
    [plusexplain_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3.5) andAlpha:0.0]];
    
    // Move sample story 0 from page 3 to 4 to 5 and resize
    IFTTTFrameAnimation *sample_story_frame_animation = [IFTTTFrameAnimation animationWithView:self.sampleStoryImageView];
    [self.animator addAnimation:sample_story_frame_animation];
    [sample_story_frame_animation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andFrame:self.sampleStoryImageView.frame]];
    [sample_story_frame_animation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3.5) andFrame:CGRectOffset(self.sampleStoryImageView.frame,
                                                                                                                              timeForPage(1.5), 0)]];
    [sample_story_frame_animation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andFrame:CGRectOffset(CGRectMake(self.sampleStoryImageView.frame.origin.x,
                                                                                                                              self.sampleStoryImageView.frame.origin.y,
                                                                                                                              self.sampleStoryImageView.frame.size.width*0.5,
                                                                                                                              self.sampleStoryImageView.frame.size.height*0.5),
                                                                                                                   timeForPage(2)+76, 0)]];
    [sample_story_frame_animation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(5) andFrame:CGRectOffset(CGRectMake(self.sampleStoryImageView.frame.origin.x,
                                                                                                                                       self.sampleStoryImageView.frame.origin.y,
                                                                                                                                       self.sampleStoryImageView.frame.size.width*0.5,
                                                                                                                                       self.sampleStoryImageView.frame.size.height*0.5),
                                                                                                                            timeForPage(3)+76, 0)]];
    
    // Increase alpha of sample story 0 between 3 and 4
    IFTTTAlphaAnimation *samplestory_alphaAnimation = [IFTTTAlphaAnimation animationWithView:self.sampleStoryImageView];
    [self.animator addAnimation:samplestory_alphaAnimation];
    [samplestory_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(3) andAlpha:0.0]];
    [samplestory_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:1.0]];
    [samplestory_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(5) andAlpha:0.0]];
    
    // Move sample story 1 from 4 to 5
    IFTTTFrameAnimation *sample_story_1_frame_animation = [IFTTTFrameAnimation animationWithView:self.sampleStory1ImageView];
    [self.animator addAnimation:sample_story_1_frame_animation];
    [sample_story_1_frame_animation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andFrame:self.sampleStory1ImageView.frame]];
    [sample_story_1_frame_animation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(5) andFrame:CGRectOffset(self.sampleStory1ImageView.frame,
                                                                                                                              timeForPage(2), 0)]];

    // Decrease alpha of sample story 1 from 4 to 5
    IFTTTAlphaAnimation *samplestory_1_alphaAnimation = [IFTTTAlphaAnimation animationWithView:self.sampleStory1ImageView];
    [self.animator addAnimation:samplestory_1_alphaAnimation];
    [samplestory_1_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:1.0]];
    [samplestory_1_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(5) andAlpha:0.0]];
    
    // Move sample story 1 from 4 to 5
    IFTTTFrameAnimation *sample_story_2_frame_animation = [IFTTTFrameAnimation animationWithView:self.sampleStory2ImageView];
    [self.animator addAnimation:sample_story_2_frame_animation];
    [sample_story_2_frame_animation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andFrame:self.sampleStory2ImageView.frame]];
    [sample_story_2_frame_animation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(5) andFrame:CGRectOffset(self.sampleStory2ImageView.frame,
                                                                                                                              timeForPage(2), 0)]];
    
    // Decrease alpha of sample story 1 from 4 to 5
    IFTTTAlphaAnimation *samplestory_2_alphaAnimation = [IFTTTAlphaAnimation animationWithView:self.sampleStory2ImageView];
    [self.animator addAnimation:samplestory_2_alphaAnimation];
    [samplestory_2_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(4) andAlpha:1.0]];
    [samplestory_2_alphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:timeForPage(5) andAlpha:0.0]];
}

- (IBAction)dismissIntroView:(id)sender
{
    [BNMisc setFirstTimeUserActionDone:BNUserDefaultsFirstTimeAppOpen];
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc
{
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([super respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [super scrollViewDidScroll:scrollView];
    }
    CGFloat pageWidth = self.scrollView.frame.size.width;
    float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    self.pageControl.currentPage = page;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
