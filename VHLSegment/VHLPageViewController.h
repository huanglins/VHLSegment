//
//  VHLPageViewController.h
//  VHLPageViewController
//
//  Created by Vincent on 2018/9/26.
//  Copyright © 2018 Darnel Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VHLPageViewController;

@protocol VHLPageViewControllerDataSource <NSObject>
// 需要提供数据源
/** controllers numbers*/
- (NSInteger)VHL_numberOfControllersInPageViewController:(VHLPageViewController * _Nonnull)pageViewController;
/** controller */
- (nullable UIViewController *)VHL_pageViewController:(VHLPageViewController * _Nonnull)pageViewController viewControllerForIndex:(NSInteger)index;

@end

@protocol VHLPageViewControllerDelegate <NSObject>

@optional
// 生命周期回调
- (void)VHL_pageViewController:(VHLPageViewController * _Nonnull)pageViewController willAppearController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index;

- (void)VHL_pageViewController:(VHLPageViewController * _Nonnull)pageViewController didAppearController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index;

- (void)VHL_pageViewController:(VHLPageViewController * _Nonnull)pageViewController willDisappearController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index;

- (void)VHL_pageViewController:(VHLPageViewController * _Nonnull)pageViewController didDisappearController:(UIViewController * _Nonnull) controller atIndex:(NSInteger)index;

// 滚动相关回调
// 滚动 | if (!scrollView.isDragging && !scrollView.isDecelerating) {return;} 过滤不是手动触发
- (void)VHL_pageViewController:(VHLPageViewController * _Nonnull)pageViewController scrollViewDidScroll:(UIScrollView * _Nonnull)scrollView;      // 滚动中
- (void)VHL_pageViewController:(VHLPageViewController * _Nonnull)pageViewController scrollViewWillBeginDragging:(UIScrollView * _Nonnull)scrollView;      // 将要滚动
- (void)VHL_pageViewController:(VHLPageViewController * _Nonnull)pageViewController scrollViewDidEndDecelerating:(UIScrollView * _Nonnull)scrollView;      // 停止滚动

@end
// ---------------------------------------------------------------------------------------------------------
@interface VHLPageScrollView : UIScrollView

/** 传入需要和滚动视图解决拖动手势冲突问题的类名数组 */
@property (nonatomic, strong) NSArray *hitShieldClassNameArray;  // @[@"UISlider"]

@end

@interface VHLPageViewController : UIViewController

/** pageViewController 容器视图 */
@property (nonatomic, strong) VHLPageScrollView *  _Nullable containerView;
/** 当前 index, 默认为 0*/
@property (nonatomic, assign) NSUInteger currentIndex;

@property (nonatomic, weak) id<VHLPageViewControllerDataSource> dataSource;
@property (nonatomic, weak) id<VHLPageViewControllerDelegate> delegate;

// 跳转到某一页
- (void)gotoPageWithIndex:(NSInteger)index animated:(BOOL)animated;
// 刷新
- (void)reloadData;

@end

/**
 错误： Unbalanced calls to begin/end appearance transitions for
 当一个 vc 已经被操作过后，不能再重复进行。合理的处理动画操作状态
 */

