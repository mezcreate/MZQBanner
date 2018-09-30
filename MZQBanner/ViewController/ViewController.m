//
//  ViewController.m
//  MZQBanner
//
//  Created by Sino-Kerry on 2018/9/30.
//  Copyright © 2018 Mac. All rights reserved.
//

#import "ViewController.h"
#import <Masonry.h>
#import "MZQScrollBannerView.h"

@interface ViewController ()

@property (nonatomic, strong) MZQScrollBannerView *bannerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadBannerView];
}

- (void)loadBannerView {
    
    self.bannerView = [[MZQScrollBannerView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_bannerView];
    [self.bannerView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
            
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(0);
        } else {
            
            make.top.equalTo(self.view.mas_top).offset(0);
        }
        make.left.equalTo(self.view.mas_left).offset(0);
        make.right.equalTo(self.view.mas_right).offset(0);
        make.height.mas_equalTo(300);
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self.bannerView setBannerImage:[NSArray arrayWithObjects:[UIImage imageNamed:@"timg1.jpeg"], [UIImage imageNamed:@"timg2.jpeg"], [UIImage imageNamed:@"timg3.png"], [UIImage imageNamed:@"timg4.gif"], nil] andImageHeight:300];
}

@end
