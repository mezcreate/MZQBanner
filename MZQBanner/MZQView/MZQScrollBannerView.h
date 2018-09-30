//
//  MZQScrollBannerView.h
//  MZQBanner
//
//  Created by Sino-Kerry on 2018/9/27.
//  Copyright © 2018 Mac. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MZQScrollBannerView : UIView <UIScrollViewDelegate>

- (void)setBannerImage:(NSArray <UIImage *>*)imageArray andImageHeight:(CGFloat)imageHeight;

- (void)statrtPaging;

@end

NS_ASSUME_NONNULL_END
