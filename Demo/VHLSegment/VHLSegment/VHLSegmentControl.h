//
//  VHLSegmentControl.h
//  VHLPageViewController
//
//  Created by vincent on 2018/10/19.
//  Copyright © 2018年 Darnel Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VHLSegment.h"
#import "VHLPageViewController.h"

@protocol VHLSegmentControlDelegate <NSObject>

@optional
/**
 * 切换位置后的代理方法
 */
- (void)segmentControlDidselectAtIndex:(NSInteger)index;

@end

@interface VHLSegmentControl : UIView

/** 将两个主要组件暴露出来，便于根据实际情况调整显示位置等*/
@property (nonatomic, strong) VHLSegment *segment;
@property (nonatomic, strong) VHLPageViewController *pageVC;

@property (nonatomic, assign) CGFloat segmentHeight;        // segment 高度

/**
 * 需要显示的视图
 */
@property (nonatomic, strong) NSArray *viewControllers;
/** 标题*/
@property (nonatomic, strong) NSArray *titles;

/** 选中位置*/
@property (nonatomic, assign) NSInteger selectedIndex;
/** 按钮正常时的颜色*/
@property (nonatomic, strong) UIColor *itemNormalColor;
/** 按钮选中时的颜色 */
@property (nonatomic, strong) UIColor *itemSelectedColor;

/** 按钮正常时的字体*/
@property (nonatomic, strong) UIFont *itemNormalFont;
/** 按钮选中时的字体 */
@property (nonatomic, strong) UIFont *itemSelectedFont;

/** 底部线条滚动样式*/
@property (nonatomic, assign) VHLSegmentShadowStyle shadowStyle;
/** 底部线条宽度*/
@property (nonatomic, assign) CGFloat shadowWidth;
/** 隐藏阴影*/
@property (nonatomic, assign) BOOL hideShadow;
/** 当只有一个数据源时，是否隐藏顶部 segment, 然后内容占满，默认为 YES*/
@property (nonatomic, assign) BOOL needHiddenOneSegment;
/** 是否需要在数据小于一屏时，均分数据项，默认开启*/
@property (nonatomic, assign) BOOL needAverageScreen;
/** 是否启用滚动联动动画，默认开启*/
@property (nonatomic, assign) BOOL useScrollAnimation;
/**
 * 代理方法
 */
@property (nonatomic, weak) id <VHLSegmentControlDelegate> delegate;
/**
 * 初始化方法
 */
- (instancetype)initWithFrame:(CGRect)frame Titles:(NSArray <NSString *>*)titles viewControllers:(NSArray <UIViewController *>*)viewControllers;

/** 标题显示在ViewController中*/
- (void)showInViewController:(UIViewController *)viewController;
/** 标题显示在NavigationBar中*/
- (void)showInNavigationController:(UINavigationController *)navigationController;

- (void)chooseTheIndex:(NSInteger)index;

@end
