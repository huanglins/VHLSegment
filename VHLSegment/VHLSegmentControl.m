//
//  VHLSegmentControl.m
//  VHLPageViewController
//
//  Created by vincent on 2018/10/19.
//  Copyright © 2018年 Darnel Studio. All rights reserved.
//

#import "VHLSegmentControl.h"

//顶部ScrollView高度
#define VHLSegmentHeight           44.0f
#define VHLCuttinglineHeight       (0.5f)
//static const CGFloat SegmentHeight = 44.0f;

@interface VHLSegmentControl () <VHLSegmentDelegate, VHLPageViewControllerDataSource, VHLPageViewControllerDelegate>

@property (nonatomic, strong) UIView *bottomLine;

@end

@implementation VHLSegmentControl

- (instancetype)initWithFrame:(CGRect)frame Titles:(NSArray <NSString *>*)titles viewControllers:(NSArray <UIViewController *>*)viewControllers{
    if (self = [super initWithFrame:frame]) {
        [self buildUI];
        self.titles = titles;
        self.viewControllers = viewControllers;
    }
    return self;
}

- (void)buildUI {
    [self addSubview:[UIView new]];
    // 添加分段选择器
    _segment = [[VHLSegment alloc] init];
    _segment.frame = CGRectMake(0, 0, self.frame.size.width, VHLSegmentHeight - VHLCuttinglineHeight);
    _segment.shadowStyle = VHLSegmentShadowStyleSpring;
    _segment.needAverageScreen = NO;
    _segment.delegate = self;
    [self addSubview:_segment];
    
    // 底部浅色分割线
    self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, VHLSegmentHeight - VHLCuttinglineHeight, self.frame.size.width, VHLCuttinglineHeight)];
    [self addSubview:self.bottomLine];
    self.bottomLine.backgroundColor = [UIColor colorWithRed:0.95 green:0.96 blue:0.96 alpha:1.00];
    
    // 添加分页滚动视图控制器
    _pageVC = [[VHLPageViewController alloc] init];
    _pageVC.view.frame = CGRectMake(0, VHLSegmentHeight, self.bounds.size.width, self.bounds.size.height - VHLSegmentHeight);
    _pageVC.dataSource = self;
    _pageVC.delegate = self;
    [self addSubview:_pageVC.view];
    
    // 控制属性初始化
    self.useScrollAnimation = YES;
    self.needHiddenOneSegment = YES;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (!newSuperview) {        // 添加或删除父视图触发
        [self switchToIndex:_selectedIndex];
    }
}
#pragma mark Setter & Getter
- (void)setViewControllers:(NSArray *)viewControllers {
    _viewControllers = viewControllers;
    [_pageVC reloadData];
}
- (void)setTitles:(NSArray *)titles {
    _titles = titles;
    _segment.titles = titles;
    if (_needHiddenOneSegment && self.titles.count == 1) {
        self.segment.hidden = YES;
        self.bottomLine.hidden = YES;
        self.pageVC.view.bounds = self.bounds;
    } else {
        self.segment.hidden = NO;
        self.bottomLine.hidden = NO;
    }
}
- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    _segment.selectedIndex = _selectedIndex;
    [self switchToIndex:_selectedIndex];
}
- (void)setItemSelectedColor:(UIColor *)itemSelectedColor {
    _segment.itemSelectedColor = itemSelectedColor;
}
- (void)setItemNormalColor:(UIColor *)itemNormalColor {
    _segment.itemNormalColor = itemNormalColor;
}
- (void)setItemNormalFont:(UIFont *)itemNormalFont {
    _itemNormalFont = itemNormalFont;
    _segment.itemNormalFont = itemNormalFont;
}
- (void)setItemSelectedFont:(UIFont *)itemSelectedFont {
    _itemSelectedFont = itemSelectedFont;
    _segment.itemSelectedFont = itemSelectedFont;
}
- (void)setShadowStyle:(VHLSegmentShadowStyle)shadowStyle {
    _shadowStyle = shadowStyle;
    _segment.shadowStyle = shadowStyle;
}
- (void)setShadowWidth:(CGFloat)shadowWidth {
    _shadowWidth = shadowWidth;
    _segment.shadowWidth = shadowWidth;
}
- (void)setHideShadow:(BOOL)hideShadow {
    _hideShadow = hideShadow;
    _segment.hideShadow = _hideShadow;
}
- (void)setNeedHiddenOneSegment:(BOOL)needHiddenOneSegment {
    _needHiddenOneSegment = YES;
    if (_needHiddenOneSegment && self.titles.count == 1) {
        self.segment.hidden = YES;
        self.bottomLine.hidden = YES;
        self.pageVC.view.bounds = self.bounds;
    } else {
        self.segment.hidden = NO;
        self.bottomLine.hidden = NO;
    }
}
- (void)setNeedAverageScreen:(BOOL)needAverageScreen {
    _needAverageScreen = needAverageScreen;
    _segment.needAverageScreen = needAverageScreen;
}
- (void)setUseScrollAnimation:(BOOL)useScrollAnimation {
    _useScrollAnimation = useScrollAnimation;
    _segment.followScrollView = useScrollAnimation?_pageVC.containerView:nil;
}
#pragma mark - public method
- (void)showInViewController:(UIViewController *)viewController {
    [viewController addChildViewController:_pageVC];
    [viewController.view addSubview:self];
    _bottomLine.hidden = NO;
    if (_needHiddenOneSegment && self.titles.count == 1) {
        _segment.hidden = YES;
        _bottomLine.hidden = YES;
        _pageVC.view.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    }
}
- (void)showInNavigationController:(UINavigationController *)navigationController {
    [navigationController.topViewController.view addSubview:self];
    [navigationController.topViewController addChildViewController:_pageVC];
    navigationController.topViewController.navigationItem.titleView = _segment;
    _pageVC.view.frame = self.bounds;
    _segment.backgroundColor = [UIColor clearColor];
    _bottomLine.hidden = YES;       // 添加到导航栏时要将这条线隐藏掉
}
- (void)chooseTheIndex:(NSInteger)index {
    [_segment chooseTheIndex:index];
    [_pageVC gotoPageWithIndex:index animated:YES];
}
#pragma mark VHLSegmentDelegate ---------------------------------------------
- (void)slideSegmentDidSelectedAtIndex:(NSInteger)index {
    // if (index == _selectedIndex) {return;}
    [self switchToIndex:index];
    [self performSwitchDelegateMethod];
}
#pragma mark - VHLPageViewControllerDataSource
- (NSInteger)VHL_numberOfControllersInPageViewController:(VHLPageViewController *)pageViewController {
    return self.viewControllers.count;
}
- (UIViewController *)VHL_pageViewController:(VHLPageViewController *)pageViewController viewControllerForIndex:(NSInteger)index {
    return [self.viewControllers objectAtIndex:index];
}
#pragma mark - VHLPageViewControllerDelegate
- (void)VHL_pageViewController:(VHLPageViewController *)pageViewController didAppearController:(UIViewController *)controller atIndex:(NSInteger)index {
    _selectedIndex = index;
    [_segment chooseTheIndex:index];
    [self performSwitchDelegateMethod];
}
- (void)VHL_pageViewController:(VHLPageViewController *)pageViewController scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.isDragging && !scrollView.isDecelerating) {return;}
    // 计算当前 page 偏移量
//    if (self.useScrollAnimation) {
//        CGFloat pageOffset = scrollView.contentOffset.x / (scrollView.contentSize.width / self.viewControllers.count);
//        [_segment progressAnimationWithPageOffset:pageOffset];
//    }
}

#pragma mark 其他方法 --------------------------------------------------------------------
- (void)switchToIndex:(NSInteger)index {
    if (index < 0 || _viewControllers.count <= index) return;
    _selectedIndex = index;
    [_pageVC gotoPageWithIndex:index animated:YES];
}

// 执行切换代理方法
- (void)performSwitchDelegateMethod {
    if (self.delegate && [_delegate respondsToSelector:@selector(segmentControlDidselectAtIndex:)]) {
        [_delegate segmentControlDidselectAtIndex:_selectedIndex];
    }
}

#pragma mark - 解决拖动滑条界面被拖动问题
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    // 开启自身滚动
    _pageVC.containerView.scrollEnabled = YES;
    
    if ([self pointInside:point withEvent:event]) {
        NSArray<UIView *> * superViews = self.subviews;
        // 倒序 从最上面的一个视图开始查找
        for (NSUInteger i = superViews.count; i > 0; i--) {
            UIView * subview = superViews[i - 1];
            // 转换坐标系 使坐标基于子视图
            CGPoint newPoint = [self convertPoint:point toView:subview];
            // 得到子视图 hitTest 方法返回的值
            UIView * view = [subview hitTest:newPoint withEvent:event];
            // 如果子视图返回一个view 就直接返回 不在继续遍历
            if (view) {
                if ([NSStringFromClass(view.class) isEqualToString:@"VHLSlider"]) {
                    // 关闭自身滚动
                    _pageVC.containerView.scrollEnabled = NO;
                }
                return view;
            }
        }
        // 所有子视图都没有返回 则返回自身
        return self;
    }
    return nil;
}

@end
