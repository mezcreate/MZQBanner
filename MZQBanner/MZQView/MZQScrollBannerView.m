//
//  MZQScrollBannerView.m
//  MZQBanner
//
//  Created by Sino-Kerry on 2018/9/30.
//  Copyright © 2018 Mac. All rights reserved.
//

#import "MZQScrollBannerView.h"
#import <Masonry.h>

typedef enum ScrollDirection {
    
    ScrollLeft = 0,
    ScrollRight
} ScrollDirection;

@interface MZQScrollBannerView() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) NSMutableArray *pageArray;

@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, assign) NSInteger scrollDirect;

@property (nonatomic, strong) dispatch_source_t timer;

@property (nonatomic, assign) CGFloat imageHeight;

@property (nonatomic, assign) BOOL isTimerCancel; /*是否取消了计时*/

@property (nonatomic, assign) BOOL isClickPage; /*是否用户点击选择页码*/

@property (nonatomic, assign) ScrollDirection scrollDirection;

@end

@implementation MZQScrollBannerView

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        self.userInteractionEnabled = YES;
        
        _currentIndex = 1;
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.userInteractionEnabled = YES;
        [self addSubview:_scrollView];
        [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.top.equalTo(self.mas_top).offset(0);
            make.left.equalTo(self.mas_left).offset(0);
            make.right.equalTo(self.mas_right).offset(0);
            make.bottom.equalTo(self.mas_bottom).offset(0);
        }];
        
        _scrollView.userInteractionEnabled = YES;
        _scrollView.scrollsToTop = false;
        _scrollView.delegate = self;
        _scrollView.pagingEnabled = YES;
        _scrollView.bounces = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        
        UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureBanner:)];
        gesture.minimumPressDuration = 0.1;
        gesture.delegate = self;
        [_scrollView addGestureRecognizer:gesture];
        
        _pageControl = [[UIPageControl alloc] initWithFrame:CGRectZero];
        [self addSubview:_pageControl];
        [_pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.height.mas_equalTo(40);
            make.left.equalTo(self.mas_left).offset(0);
            make.right.equalTo(self.mas_right).offset(0);
            make.bottom.equalTo(self.mas_bottom).offset(0);
        }];
    }
    return self;
}

- (void)setBannerImage:(NSArray <UIImage *> *)imageArray andImageHeight:(CGFloat)imageHeight {
    
    if (imageArray == nil) {
        
        return;
    }
    
    self.imageHeight = imageHeight;
    _pageControl.numberOfPages = imageArray.count;
    _pageControl.currentPage = 0;
    [_pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
    [_pageControl addTarget:self action:@selector(clickControlPage:event:) forControlEvents:UIControlEventTouchUpInside];
    _pageControl.currentPageIndicatorTintColor = [UIColor redColor];
    _pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    _pageArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:imageArray];
    
    if (array.count > 1) {
        
        for (int i = 0; i < imageArray.count; i ++) {
            
            if (i == 0) {
                
                [array addObject:imageArray[0]];
            } else if (i == imageArray.count - 1) {
                
                [array insertObject:imageArray[i] atIndex:0];
            }
        }
    }
    
    for (int i = 0; i < array.count; i ++) {
        
        UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectZero];
        [imageview setImage: array[i]];
        imageview.userInteractionEnabled = YES;
        
        [self.scrollView addSubview:imageview];
        [imageview mas_makeConstraints:^(MASConstraintMaker *make) {
            
            make.top.equalTo(self.scrollView.mas_top).offset(0);
            make.bottom.equalTo(self.scrollView.mas_bottom).offset(0);
            make.left.equalTo(self.scrollView.mas_left).offset(i * [UIScreen mainScreen].bounds.size.width);
            make.height.mas_equalTo(imageHeight);
            make.width.mas_equalTo([UIScreen mainScreen].bounds.size.width);
            if (i == array.count - 1) {
                
                make.right.equalTo(self.scrollView.mas_right).offset(0);
            }
        }];
        [_pageArray addObject:imageview];
    }
    
    //如果是一张图片，不需要轮播
    if (array.count > 1) {
        
        [self.scrollView setContentOffset:CGPointMake([UIScreen mainScreen].bounds.size.width * 1, 0) animated:NO];
        [self statrtPaging];
    }
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    [self cancelTimer];
    NSInteger page = (_scrollView.contentOffset.x + self.bounds.size.width / 2) / self.bounds.size.width;
    self.currentIndex = page;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    
    [self cancelTimer];
    NSInteger page = (_scrollView.contentOffset.x + self.bounds.size.width / 2) / self.bounds.size.width;
    self.currentIndex = page;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (_pageArray.count == 1) {
        
        return;
    }
    
    
    NSInteger page = (self.scrollView.contentOffset.x + self.bounds.size.width / 2) / self.bounds.size.width;
    if (page == _pageArray.count - 2) {
        
        [self.pageControl setCurrentPage:0];
    } else if (page == 0) {
        
        [self.pageControl setCurrentPage:_pageArray.count - 2];
    } else {
        
        [self.pageControl setCurrentPage:page];
    }
    [self.pageControl setCurrentPage:page - 1];
    
    if (_isTimerCancel && !_isClickPage) {
        
        [self cancelTimer];
        if (_currentIndex == 1) {
            
            if (self.scrollView.contentOffset.x < self.bounds.size.width / 2) {
                
                [self cancelTimer];
                self.scrollDirection = ScrollLeft;
                self.currentIndex = _pageArray.count - 2;
                [self.pageControl setCurrentPage:_currentIndex - 1];
                
                CGPoint position = CGPointMake(self.bounds.size.width * self.currentIndex, 0);
                [self.scrollView setContentOffset:position animated:NO];
                [self restartTimer];
            } else if (scrollView.contentOffset.x > self.bounds.size.width + self.bounds.size.width / 2) {
                
                self.currentIndex ++;
                [self.pageControl setCurrentPage:_currentIndex - 1];
                [self restartTimer];
            }
        } else if (_currentIndex == _pageArray.count - 2) {
            
            if (self.scrollView.contentOffset.x > self.bounds.size.width * _currentIndex + self.bounds.size.width / 2) {
                
                [self cancelTimer];
                self.scrollDirection = ScrollRight;
                self.currentIndex = 1;
                [self.pageControl setCurrentPage:0];
                
                CGPoint position = CGPointMake(self.bounds.size.width * self.currentIndex, 0);
                [self.scrollView setContentOffset:position animated:NO];
                [self restartTimer];
            } else if (scrollView.contentOffset.x < self.bounds.size.width * (_currentIndex - 1) + (self.bounds.size.width / 2)) {
                
                self.currentIndex --;
                [self.pageControl setCurrentPage:_currentIndex - 1];
                [self restartTimer];
            }
            
        } else {
            
            if (scrollView.contentOffset.x > self.bounds.size.width * _currentIndex + (self.bounds.size.width / 2)) {
                
                [self cancelTimer];
                self.currentIndex ++;
                [self.pageControl setCurrentPage:_currentIndex - 1];
                [self restartTimer];
            } else if (scrollView.contentOffset.x < self.bounds.size.width * _currentIndex - (self.bounds.size.width / 2)) {
                
                self.currentIndex --;
                [self.pageControl setCurrentPage:_currentIndex - 1];
                [self restartTimer];
            }
        }
    }
}

//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//
//    BOOL scrollToScrollStop = !scrollView.tracking && !scrollView.dragging && !scrollView.decelerating;
//    if (scrollToScrollStop) {
//
//        if (_isTimerCancel && !_isClickPage) {
//
//            if (_currentIndex == 1) {
//
//                if (_scrollDirection == ScrollLeft) {
//
//                    self.currentIndex = _pageArray.count - 2;
//                    [self.pageControl setCurrentPage:_currentIndex - 1];
//                    CGPoint position = CGPointMake(self.bounds.size.width * _currentIndex, 0);
//                    [self.scrollView setContentOffset:position animated:NO];
//                    [self restartTimer];
//                }
//            } else if (_currentIndex == _pageArray.count - 2) {
//
//                if (_scrollDirection == ScrollRight) {
//
//                    self.currentIndex = 1;
//                    [self.pageControl setCurrentPage:0];
//                    CGPoint position = CGPointMake(self.bounds.size.width * _currentIndex, 0);
//                    [self.scrollView setContentOffset:position animated:NO];
//                    [self restartTimer];
//                }
//            }
//        }
//    }
//}
//
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//
//    BOOL dragToDragStop = scrollView.tracking && !scrollView.dragging && !scrollView.decelerating;
//    if (dragToDragStop) {
//
//        if (_isTimerCancel && !_isClickPage) {
//
//            if (_currentIndex == 1) {
//
//                if (_scrollDirection == ScrollLeft) {
//
//                    self.currentIndex = _pageArray.count - 2;
//                    [self.pageControl setCurrentPage:_currentIndex - 1];
//                    CGPoint position = CGPointMake(self.bounds.size.width * _currentIndex, 0);
//                    [self.scrollView setContentOffset:position animated:NO];
//                    [self restartTimer];
//                }
//            } else if (_currentIndex == _pageArray.count - 2) {
//
//                if (_scrollDirection == ScrollRight) {
//
//                    self.currentIndex = 1;
//                    [self.pageControl setCurrentPage:0];
//                    CGPoint position = CGPointMake(self.bounds.size.width * _currentIndex, 0);
//                    [self.scrollView setContentOffset:position animated:NO];
//                    [self restartTimer];
//                }
//            }
//        }
//    }
//}

- (void)gestureBanner:(UIGestureRecognizer *)gesture {
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            
            [self cancelTimer];
        }
            break;
        case UIGestureRecognizerStateCancelled: {
            
            [self restartTimer];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            
        }
            break;
            
        case UIGestureRecognizerStateEnded: {
            
            [self restartTimer];
        }
            break;
        default:
            break;
    }
}

//开始定时执行轮播操作
- (void)statrtPaging {
    
    if (_isTimerCancel) {
        self.isTimerCancel = NO;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC));
    dispatch_time_t interval = 3.0 * NSEC_PER_SEC;
    
    dispatch_source_set_timer(self.timer, start, interval, 0);
    __weak typeof(self) weakself = self;
    
    dispatch_source_set_event_handler(weakself.timer, ^{
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            NSInteger page = (weakself.scrollView.contentOffset.x + weakself.bounds.size.width / 2) / weakself.bounds.size.width;
            weakself.currentIndex = page;
            
            if (weakself.currentIndex < weakself.pageArray.count - 2 && weakself.currentIndex >= 1) {
                
                self.currentIndex ++;
                [self.pageControl setCurrentPage:weakself.currentIndex - 1];
                [weakself.scrollView scrollRectToVisible:CGRectMake(weakself.bounds.size.width * weakself.currentIndex, 0, weakself.bounds.size.width, weakself.bounds.size.height) animated:NO];
            } else {
                
                self.currentIndex = 1;
                [self.pageControl setCurrentPage:weakself.currentIndex - 1];
                [weakself.scrollView scrollRectToVisible:CGRectMake(weakself.bounds.size.width * weakself.currentIndex, 0, weakself.bounds.size.width, weakself.bounds.size.height) animated:NO];
            }
        }];
    });
    dispatch_resume(weakself.timer);
}

- (void)changePage:(UIPageControl *)sender {
    
    self.isClickPage = YES;
    [self cancelTimer];
    NSLog(@"%ld", sender.currentPage);
    self.currentIndex = sender.currentPage;
    [self.pageControl setCurrentPage:_currentIndex];
    CGPoint point = CGPointMake(self.bounds.size.width * _currentIndex, 0);
    [self.scrollView setContentOffset:point animated:NO];
    self.isClickPage = NO;
    [self restartTimer];
}

- (void)clickControlPage:(UIPageControl *)sender event:(UIEvent *)event {
    
    self.isClickPage = YES;
    [self cancelTimer];
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint point = [touch locationInView:_pageControl];
    CGFloat centerX = _pageControl.center.x;
    CGFloat left = centerX - 15.0 * _pageArray.count / 2;
    [self.pageControl setCurrentPage: (int)(point.x - left) / 15];
    [self.scrollView setContentOffset:CGPointMake((_pageControl.currentPage + 1) * self.bounds.size.width, 0) animated:NO];
    self.isClickPage = NO;
    [self restartTimer];
}

//停止定时操作
//- (void)pauseTimer {
//
//    if (_timer) {
//
//        if (!_isTimerPause) {
//
//            dispatch_suspend(_timer);
//            self.isTimerPause = YES;
//        }
//    }
//}

//重启定时器
//- (void)resumeTimer {
//
//    if (_timer) {
//
//        if (_isTimerPause) {
//
//            dispatch_resume(_timer);
//            self.isTimerPause = NO;
//        }
//    }
//}

//重启定时器
- (void)restartTimer {
    
    [self statrtPaging];
    self.isTimerCancel = NO;
}

//终止定时器
- (void)cancelTimer {
    
    if (_timer) {
        
        dispatch_source_cancel(_timer);
        self.isTimerCancel = YES;
        self.timer = nil;
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self cancelTimer];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self restartTimer];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self cancelTimer];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self restartTimer];
}

//gesture代理，防止手势被其他动作覆盖
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return TRUE;
}

//释放
- (void)dealloc {
    
    [self cancelTimer];
}

@end
