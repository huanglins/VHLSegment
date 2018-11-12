//
//  VHLSegmentItem.h
//  VHLPageViewController
//
//  Created by vincent on 2018/10/19.
//  Copyright © 2018年 Darnel Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VHLSegmentLabel : UILabel

@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, assign) CGFloat startProgress;
@property (nonatomic, assign) CGFloat progress;

- (void)setStartProgress:(CGFloat)startProgress toProgress:(CGFloat)toProgress selectedColor:(UIColor *)sColor;

@end

@interface VHLSegmentItem : UICollectionViewCell

@property (nonatomic, strong) UIImageView *leftImageView;
@property (nonatomic, strong) VHLSegmentLabel *textLabel;

- (void)relayout;

@end
