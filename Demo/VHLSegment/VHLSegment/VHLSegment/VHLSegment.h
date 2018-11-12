//
//  VHLSegment.h
//  VHLPageViewController
//
//  Created by vincent on 2018/11/1.
//  Copyright © 2018年 Darnl Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VHLSegmentShadowStyle) {
    VHLSegmentShadowStyleDefault,             // 底部线条默认样式，
    VHLSegmentShadowStyleSpring,              // 底部线条，弹性线条
};
typedef NS_ENUM(NSInteger, VHLSegmentItemStyle) {
    VHLSegmentItemStyleTransition,  // 文字过渡效果，渐变。默认
    VHLSegmentItemStyleProgress,    // 歌词进度效果
};

@protocol VHLSegmentDelegate <NSObject>

- (void)slideSegmentDidSelectedAtIndex:(NSInteger)index;

@end

@interface VHLSegment : UIView

@property (nonatomic, strong) NSArray *titles;                      
@property (nonatomic, assign) NSInteger selectedIndex;              // 当前选中项

@property (nonatomic, assign) BOOL needAverageScreen;               // item 宽度小于一屏时是否均分屏幕
@property (nonatomic, assign) CGFloat itemInteritemSpacing;         // 每项间的左右外间距，默认 10
@property (nonatomic, assign) CGFloat itemInnerItemSpacing;         // 每项的内边距，左右 * 2，默认 0
@property (nonatomic, assign) VHLSegmentItemStyle itemStyle;        // 文字过渡样式,默认渐变效果
// 文字颜色
@property (nonatomic, strong) UIColor *itemNormalColor;             // 普通颜色   灰色
@property (nonatomic, strong) UIColor *itemSelectedColor;           // 选中颜色   蓝色
@property (nonatomic, strong) NSArray *itemNormalColors;            // 普通颜色数组，如果有优先判断
@property (nonatomic, strong) NSArray *itemSelectedColors;          // 选中项颜色数组
// 文字字体
@property (nonatomic, strong) UIFont *itemNormalFont;               // 默认字体     15号
@property (nonatomic, strong) UIFont *itemSelectedFont;             // 选中字体     15号
@property (nonatomic, strong) NSArray *itemNormalFonts;             // 默认字体数组，如果有优先判断
@property (nonatomic, strong) NSArray *itemSelectedFonts;           // 选择字体数组
// 左边图标
@property (nonatomic, strong) NSArray *itemNormalLeftImages;        // 默认左边图标数组。默认图标大小为 20x20
@property (nonatomic, strong) NSArray *itemSelectLeftImages;        // 默认左边图标数组
// 底部线条
@property (nonatomic, strong) UIColor *shadowColor;                 // 底部横线的颜色, 默认为当前项的选中颜色
@property (nonatomic, assign) CGFloat shadowWidth;                  // 底部横线宽度，默认 10，如果设置为小于0，默认使用当前项的宽度
@property (nonatomic, assign) CGFloat shadowHeight;                 // 底部横线高度，默认 4，如果设置小于0，默认使用当前项的高度（减去上下间距）
@property (nonatomic, assign) CGFloat shadowRadius;                 // 底部线条圆角，默认 2
@property (nonatomic, assign) CGFloat shadowMarginBottom;           // 底部横线距离底部的距离
@property (nonatomic, assign) VHLSegmentShadowStyle shadowStyle;    // 底部线条过渡样式
@property (nonatomic, assign) BOOL hideShadow;                      // 是否隐藏底部线条

@property (nonatomic, strong) UIScrollView *followScrollView;       // 监听该 scrollView 的滚动状态，并更新 page 动画

@property (nonatomic, weak) id<VHLSegmentDelegate> delegate;

- (void)chooseTheIndex:(NSInteger)index;
// 滚动联动动画 pageOffset。 比如 第一页到第二页：1.23 ..
- (void)progressAnimationWithPageOffset:(CGFloat)pageOffset;

@end

/**
   ** Invalid update: invalid number of items in section 0.  The number of items contained in an existing section after the update
 
    UICollection 在执行完 performBatchUpdates 操作之后，collection view 会自动 reloadData。
    如果这时数据源设置不正确，会触发以上 Crash，需要注意。
 
    - 联动动画
    可以设置监听 scrollView contentOffset,
    或者自己计算分页数据手动调用 progressAnimationWithPageOffset 进行设置
 */
