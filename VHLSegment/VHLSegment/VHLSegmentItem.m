//
//  VHLSegmentItem.m
//  VHLPageViewController
//
//  Created by vincent on 2018/10/19.
//  Copyright © 2018年 Darnel Studio. All rights reserved.
//

#import "VHLSegmentItem.h"

@implementation VHLSegmentLabel

- (void)setStartProgress:(CGFloat)startProgress toProgress:(CGFloat)toProgress selectedColor:(UIColor *)sColor {
    _startProgress = startProgress;
    _progress = toProgress;
    _selectedColor = sColor;
    
    [self setNeedsDisplay];     // 触发 drawRect 方法
}
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (self.selectedColor) {
        [self.selectedColor set];
        
        CGRect newRect = rect;
        newRect.origin.x = rect.size.width * self.startProgress;
        newRect.size.width = rect.size.width * (self.progress - self.startProgress);
        UIRectFillUsingBlendMode(newRect, kCGBlendModeSourceIn);        // 文字歌词效果
    }
}

@end

@implementation VHLSegmentItem

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self buildUI];
    }
    return self;
}

- (void)buildUI {
    _leftImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, (self.contentView.bounds.size.height - 20) / 2, 20, 20)];
    _leftImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_leftImageView];
    
    _textLabel = [[VHLSegmentLabel alloc] init];
    _textLabel.textAlignment = NSTextAlignmentCenter;
    _textLabel.font = [UIFont systemFontOfSize:15];
    [self.contentView addSubview:_textLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self relayout];
}
- (void)relayout {
    CGFloat imageWidth = _leftImageView.bounds.size.width;
    CGFloat cellWidth = self.contentView.frame.size.width;
    if (_leftImageView && _leftImageView.image) {
        _leftImageView.frame = CGRectMake(0, (self.contentView.bounds.size.height - 20) / 2, 20, 20);
        _textLabel.frame = CGRectMake(imageWidth, 0, cellWidth - imageWidth, self.contentView.frame.size.height);
        if ([_textLabel.text isEqualToString:@""]) {
            _leftImageView.center = self.contentView.center;
        }
    } else {
        _textLabel.frame = self.bounds;
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
}

@end
