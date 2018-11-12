//
//  VHLPageViewController.m
//  VHLPageViewController
//
//  Created by Vincent on 2018/9/26.
//  Copyright © 2018 Darnel Studio. All rights reserved.
//

#import "VHLPageViewController.h"
#import <objc/runtime.h>

@implementation VHLPageScrollView

#pragma mark - 解决滚动视图和侧滑手势冲突
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    // fix: velocityInView: unrecognized selector sent to instance
    if (![gestureRecognizer respondsToSelector:@selector(velocityInView:)]) {
        return YES;
    }
    CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self];
    CGPoint location = [gestureRecognizer locationInView:self];

    if (velocity.x > 0.0f && (int)location.x % (int)[UIScreen mainScreen].bounds.size.width < 40) {     // 距离左边 40 的位置内
        return NO;
    }
    return YES;
}

#pragma mark - 解决滚动视图内的其他 slider 拖动视图冲突问题
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    // 开启自身滚动
    self.scrollEnabled = YES;
    
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
                if ([view isKindOfClass:[UISlider class]] ||
                    (self.hitShieldClassNameArray && [self.hitShieldClassNameArray containsObject:NSStringFromClass(view.class)])) { //  UISlider
                    // 关闭自身滚动
                    self.scrollEnabled = NO;
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
// -------------------------------------------------------------------------------------------------
//controller状态
typedef NS_ENUM(NSUInteger, AppearanceStatus) {
    appearanceDefault,
    appearanceWillAppear,
    appearanceDidAppear,
    appearanceWillDisappear,
    appearanceDidDisappear,
};
// 扩展 ViewController ，增加 pageIndex 和 生命周期状态
static char kVHLPageViewControllerIndexKey;
static char kVHLPageViewControllerAppearanceKey;

@interface UIViewController (VHLPageViewController)

@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, assign) AppearanceStatus appearanceStatus;

@end

@implementation UIViewController (VHLPageViewController)

//
- (void)setPageIndex:(NSInteger)pageIndex {
    objc_setAssociatedObject(self, &kVHLPageViewControllerIndexKey, @(pageIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSInteger)pageIndex {
    NSNumber *num = objc_getAssociatedObject(self, &kVHLPageViewControllerIndexKey);
    return num ? [num integerValue] : 0;
}

- (void)setAppearanceStatus:(AppearanceStatus)appearanceStatus {
    objc_setAssociatedObject(self, &kVHLPageViewControllerAppearanceKey, @(appearanceStatus), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (AppearanceStatus)appearanceStatus {
    NSNumber *num = objc_getAssociatedObject(self, &kVHLPageViewControllerAppearanceKey);
    return num ? [num integerValue] : 0;
}

@end
// -------------------------------------------------------------------------------------------------

@interface VHLPageViewController ()<UIScrollViewDelegate>

/** controllers 数目*/
@property (nonatomic, assign) NSInteger numberOfControllers;
/** 前一个 pageIndex*/
@property (nonatomic, assign) NSInteger preIndex;
/** 潜在的下一个，左右滑动改变*/
@property (nonatomic, assign) NSInteger potentialNextIndex;
// 之前的 ContentOffset，用来处理子controller的forwardAppearance
@property (nonatomic, assign) CGPoint preContentOffset;
// 是否已经处理过了转发生命周期
@property (nonatomic, assign) BOOL hasProcessForwardAppearance;
// 是否是第一次进来，避免第一次生命周期触发两次
@property (nonatomic, assign) BOOL isFirstViewDidAppear;

@end

@implementation VHLPageViewController
#pragma mark - getter
- (UIScrollView *)containerView {
    if (!_containerView) {
        _containerView = [[VHLPageScrollView alloc] initWithFrame:self.view.frame];
        _containerView.delegate = self;
        _containerView.showsHorizontalScrollIndicator = NO;
        _containerView.showsVerticalScrollIndicator = NO;
        _containerView.alwaysBounceVertical = NO;
        _containerView.alwaysBounceHorizontal = YES;
        _containerView.pagingEnabled = YES;
        _containerView.backgroundColor = [UIColor clearColor];
        _containerView.scrollsToTop = NO;
        if (@available(iOS 11.0, *)) {
            _containerView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _containerView;
}
- (NSInteger)numberOfControllers {
    if (_numberOfControllers == 0 && self.dataSource && [self.dataSource respondsToSelector:@selector(VHL_numberOfControllersInPageViewController:)]) {
        _numberOfControllers = [self.dataSource VHL_numberOfControllersInPageViewController:self];
    }
    return _numberOfControllers;
}
#pragma mark - setter
- (void)setDataSource:(id<VHLPageViewControllerDataSource>)dataSource {
    _dataSource = dataSource;
    [self relayout];
}
#pragma mark -----------------------------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.isFirstViewDidAppear = YES;
    [self.view addSubview:self.containerView];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.isFirstViewDidAppear) {
        [self controllerWillAppearAtIndex:self.currentIndex];
    }
    self.potentialNextIndex = -1;
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.isFirstViewDidAppear) {
        [self controllerDidAppearAtIndex:self.currentIndex];
    }
    self.isFirstViewDidAppear = NO;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self controllerWillDisappearAtIndex:self.currentIndex];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self controllerDidDisappearAtIndex:self.currentIndex];
}
//
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // 优化在初始化view 后再初始化 dataSource 时，第一次不能正确初始化
    if (self.numberOfControllers == 0 || ![self hasLayoutControllerAtIndex:self.currentIndex]) {
        [self relayout];
    } else {
        [self resetSubViewSize];
    }
}
#pragma mark - private - method
// 传递生命周期
- (void)controllerWillAppearAtIndex:(NSInteger)index {
    UIViewController *controller = [self childViewControllerForIndex:index];
    if (!controller || controller.appearanceStatus == appearanceWillAppear) return;
    
    if (controller.appearanceStatus != appearanceWillAppear) {
        [controller beginAppearanceTransition:YES animated:YES];
    }
    controller.appearanceStatus = appearanceWillAppear;
    
    if([self.delegate respondsToSelector:@selector(VHL_pageViewController:willAppearController:atIndex:)]) {
        [self.delegate VHL_pageViewController:self willAppearController:controller atIndex:index];
    }
}
- (void)controllerDidAppearAtIndex:(NSInteger)index {
    UIViewController *controller = [self childViewControllerForIndex:index];
    if (!controller || controller.appearanceStatus == appearanceDidAppear) return;
    // willAppear -> didAppear
    if (controller.appearanceStatus != appearanceWillAppear) {
        [self controllerWillAppearAtIndex:index];
    }
    controller.appearanceStatus = appearanceDidAppear;
    [controller endAppearanceTransition];
    
    if([self.delegate respondsToSelector:@selector(VHL_pageViewController:didAppearController:atIndex:)]) {
        [self.delegate VHL_pageViewController:self didAppearController:controller atIndex:index];
    }
}
- (void)controllerWillDisappearAtIndex:(NSInteger)index {
    UIViewController *controller = [self childViewControllerForIndex:index];
    if (!controller || controller.appearanceStatus == appearanceWillDisappear) return;
    
    controller.appearanceStatus = appearanceWillDisappear;
    [controller beginAppearanceTransition:NO animated:YES];
    
    if([self.delegate respondsToSelector:@selector(VHL_pageViewController:willDisappearController:atIndex:)]) {
        [self.delegate VHL_pageViewController:self willDisappearController:controller atIndex:index];
    }
}
- (void)controllerDidDisappearAtIndex:(NSInteger)index {
    UIViewController *controller = [self childViewControllerForIndex:index];
    if (!controller || controller.appearanceStatus == appearanceDidDisappear) return;
    // willAppear -> didAppear
    if (controller.appearanceStatus != appearanceWillDisappear) {
        [self controllerWillDisappearAtIndex:index];
    }
    controller.appearanceStatus = appearanceDidDisappear;
    [controller endAppearanceTransition];
    
    if([self.delegate respondsToSelector:@selector(VHL_pageViewController:didDisappearController:atIndex:)]) {
        [self.delegate VHL_pageViewController:self didDisappearController:controller atIndex:index];
    }
}
// ------------------------------------------------------------------------------------------------------------
/** 根据 scrollview offset 计算当前位置索引*/
- (NSInteger)caculateCurrentIndex {
    return self.numberOfControllers > 0 ? floor(self.containerView.contentOffset.x / (self.containerView.contentSize.width / self.numberOfControllers)) : 0;
}
/** 根据下标获取 vc*/
- (UIViewController *)childViewControllerForIndex:(NSInteger)index {
    for (UIViewController *childController in self.childViewControllers) {
        if (childController.pageIndex == index) {
            return childController;
        }
    }
    return nil;
}
/** 在index位置是否已经有controller占用了*/
- (BOOL)hasLayoutControllerAtIndex:(NSInteger)index {
    for(UIViewController *childController in self.childViewControllers) {
        if(childController.pageIndex == index) {
            return YES;
        }
    }
    return NO;
}
/** 移除一个 child viewController*/
- (void)removeChildController:(UIViewController *)childController {
    [childController willMoveToParentViewController:nil];
    [childController.view removeFromSuperview];
    [childController removeFromParentViewController];
}
// 删除除去 当前，前一个，后一个 controller 之外的其他所有 controller
- (void)removeOtherControllers {
    NSInteger index = self.currentIndex;
    for(UIViewController *childController in self.childViewControllers) {
        if(childController.pageIndex < index - 1 || childController.pageIndex > index + 1) {
            [self removeChildController:childController];
        }
    }
}
- (void)resetSubViewSize {
    if(self.dataSource && [self.dataSource respondsToSelector:@selector(VHL_numberOfControllersInPageViewController:)]) {
        self.numberOfControllers = [self.dataSource VHL_numberOfControllersInPageViewController:self];
    } else {
        NSAssert((self.dataSource != nil), @"VHLPageViewController 必须先设置数据源");
    }
    // 设置 scrollView 容器视图内容大小
    CGFloat vWidth = self.view.bounds.size.width;
    CGFloat vHeight = self.view.bounds.size.height;
    self.containerView.frame = self.view.bounds;
    if (self.numberOfControllers > 0) {
        // ** 这里contentSize 的 height 为 1，避免 iPad 下没超过高度也能滚动的问题 **
        self.containerView.contentSize = CGSizeMake(vWidth * self.numberOfControllers, 1);
    }
    // 重新设置 child viewController 位置
    for (UIViewController *vc in self.childViewControllers) {
        CGRect frame = vc.view.frame;
        frame.origin.x = vc.pageIndex * vWidth;
        frame.size.width = vWidth;
        frame.size.height = vHeight;
        vc.view.frame = frame;
    }
}
/** 重新布局 controllers */
- (void)relayout {
    [self resetSubViewSize];
    
    if (self.dataSource) {
        if ([self.dataSource respondsToSelector:@selector(VHL_numberOfControllersInPageViewController:)]) {
            self.numberOfControllers = [self.dataSource VHL_numberOfControllersInPageViewController:self];
        }
        _currentIndex = [self caculateCurrentIndex];
        if ([self.dataSource respondsToSelector:@selector(VHL_pageViewController:viewControllerForIndex:)]) {
            [self relayoutCurrentViewController];  // 重新布局当前页
            //
            [self controllerWillAppearAtIndex:self.currentIndex];
            [self controllerDidAppearAtIndex:self.currentIndex];
            
            [self relayoutPreController];
            [self relayoutNextController];
        }
    }
}
// 重新布局 current index 位置的 controller
- (void)relayoutCurrentViewController {
    NSInteger index = self.currentIndex;
    if (0 <= index && index < self.numberOfControllers) {
        [self replaceWithController:[self.dataSource VHL_pageViewController:self viewControllerForIndex:index] atIndex:index];
    }
}
// 如果当前位置没有 controller ，重新布局 current index 位置的 controller
- (void)relayoutCurrentControllerIfNeed {
    NSInteger index = self.currentIndex;
    if(0 <= index && ![self hasLayoutControllerAtIndex:index]) {
        [self replaceWithController:[self.dataSource VHL_pageViewController:self viewControllerForIndex:index] atIndex:index];
    }
}
// 重新布局currentIndex - 1位置的controller
- (void)relayoutPreController {
    NSInteger preIndex = self.currentIndex - 1;
    if(0 <= preIndex && preIndex < self.numberOfControllers) {
        [self replaceWithController:[self.dataSource VHL_pageViewController:self viewControllerForIndex:preIndex] atIndex:preIndex];
    }
}
// 如果currentIndex - 1的位置没有controller则重新布局
- (void)relayoutPreControllerIfNeed {
    NSInteger preIndex = self.currentIndex - 1;
   if(0 <= preIndex && preIndex < self.numberOfControllers) {
        if(![self hasLayoutControllerAtIndex:preIndex]) {
            [self replaceWithController:[self.dataSource VHL_pageViewController:self viewControllerForIndex:preIndex] atIndex:preIndex];
        }
    }
}

// 重新布局currentIndex + 1位置的controller
- (void)relayoutNextController {
    NSInteger nextIndex = self.currentIndex + 1;
    if(0 <= nextIndex && nextIndex < self.numberOfControllers) {
        [self replaceWithController:[self.dataSource VHL_pageViewController:self viewControllerForIndex:nextIndex] atIndex:nextIndex];
    }
}
// 如果currentIndex + 1的位置没有controller则重新布局
- (void)relayoutNextControllerIfNeed {
    NSInteger nextIndex = self.currentIndex + 1;
    if(0 <= nextIndex && nextIndex < self.numberOfControllers) {
        if(![self hasLayoutControllerAtIndex:nextIndex]) {
            [self replaceWithController:[self.dataSource VHL_pageViewController:self viewControllerForIndex:nextIndex] atIndex:nextIndex];
        }
    }
}

- (void)replaceWithController:(UIViewController *)controller atIndex:(NSInteger)index {
    if (!controller || index < 0 || index >= self.numberOfControllers) {
        return;
    }
    // 如果是同一个 controller 就直接回调代理
    if ([self childViewControllerForIndex:index] == controller) {
        return;
    }
    // 设置 viewController 的 pageIndex
    controller.pageIndex = index;
    // 如果 childControllers 里面包含同样的 pageIndex的Controller，先将其移除
    for (UIViewController *childController in self.childViewControllers) {
        if (childController.pageIndex == index) {
            [self removeChildController:childController];
        }
    }
    // 将 controller 加入 childViewControllers ，同时更新 view 的 frame
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:self];
    
    //
    CGRect frame = controller.view.frame;
    if(index > 0) {
        frame.origin.x = index * CGRectGetWidth(self.view.bounds);
    } else {
        frame.origin.x = 0;
    }
    frame.size.width = self.view.bounds.size.width;
    frame.size.height = self.view.bounds.size.height;
    
    controller.view.frame = frame;
    
    [self.containerView addSubview:controller.view];
}
/** 拖拽过程中通知各个controller回调各个Appearance相关的方法 */
- (void)updateControllersAppearanceStautsWhenDraging {
    if(!self.containerView.isDragging) return;
    // 向右边滑动
    if(self.potentialNextIndex == self.currentIndex - 1 && self.potentialNextIndex >= 0) {
        [self controllerWillAppearAtIndex:self.potentialNextIndex];
        [self controllerWillDisappearAtIndex:self.currentIndex];
        [self controllerWillDisappearAtIndex:self.currentIndex + 1];
    }
    // 向左边滑动
    else if(self.potentialNextIndex == self.currentIndex + 1 &&
            self.potentialNextIndex < self.numberOfControllers) {
        [self controllerWillAppearAtIndex:self.potentialNextIndex];
        [self controllerWillDisappearAtIndex:self.currentIndex];
        [self controllerWillDisappearAtIndex:self.currentIndex - 1];
    }
}
/** 拖拽即将停止的时候通知各个 controller 回调各个Appearance相关的方法 */
- (void)updateControllersAppearanceStautsWhenEndCelerating {
    [self controllerDidAppearAtIndex:self.currentIndex];
    [self controllerDidDisappearAtIndex:self.currentIndex - 1];
    [self controllerDidDisappearAtIndex:self.currentIndex + 1];
    
    // 如果滑动前的controller滚出了左、右范围，需要通知其disappear
    // NSInteger 不会为负数
    if((int)self.preIndex < (int)self.currentIndex - 1 || self.preIndex > self.currentIndex + 1) {
        [self controllerWillDisappearAtIndex:self.preIndex];
        [self controllerDidDisappearAtIndex:self.preIndex];
    }
}
#pragma mark - public - method
- (void)reloadData {
    [self relayout];
}
// 跳转到某一页
- (void)gotoPageWithIndex:(NSInteger)index animated:(BOOL)animated {
    if (self.containerView.contentSize.width <= 0) {
        [self resetSubViewSize];
    }
    if(index < self.numberOfControllers && index >= 0 && self.currentIndex != index) {
        // 优化跨 index 切换
        if (abs((int)(self.currentIndex - index)) > 1) {
            NSInteger nearIndex = self.currentIndex > index? index + 1:index - 1;
            // 将当前 vc 移动到目标 vc 的旁边。（这个貌似没什么效果，因为后面会初始化左右 vc）
            UIViewController *preViewController = [self childViewControllerForIndex:self.currentIndex];
            
            CGRect nearReact = CGRectMake(CGRectGetWidth(self.containerView.bounds) * nearIndex , 0 , CGRectGetWidth(self.containerView.bounds), CGRectGetHeight(self.containerView.bounds));
            preViewController.view.frame = nearReact;
            
            [self.containerView scrollRectToVisible:nearReact animated:NO];
        }
        self.preIndex = _currentIndex;
        _currentIndex = index;
        
        [self controllerWillDisappearAtIndex:self.preIndex];
        [self controllerDidDisappearAtIndex:self.preIndex];
        
        [self relayoutCurrentControllerIfNeed];
        [self controllerWillAppearAtIndex:self.currentIndex];
        if(!animated) {
            [self controllerDidAppearAtIndex:self.currentIndex];
        }
        // 生成左右两个
        [self relayoutPreControllerIfNeed];
        [self relayoutNextControllerIfNeed];
        
        CGRect toRect = CGRectMake(CGRectGetWidth(self.containerView.bounds) * index , 0 , CGRectGetWidth(self.containerView.bounds), CGRectGetHeight(self.containerView.bounds));
        [self.containerView scrollRectToVisible:toRect animated:animated];
        
        [self removeOtherControllers];
    }
}
#pragma mark - UIScrollViewDelegate
// scrollView: 将要拖动
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView == self.containerView) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(VHL_pageViewController:scrollViewWillBeginDragging:)]) {
            [self.delegate VHL_pageViewController:self scrollViewWillBeginDragging:scrollView];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.preIndex = self.currentIndex;
            self.preContentOffset = self.containerView.contentOffset;
            self.hasProcessForwardAppearance = NO;
        });
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView == self.containerView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
    }
}
// scrollView: 停止拖动
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView == self.containerView) {
        dispatch_async(dispatch_get_main_queue(), ^{
        });
    }
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.containerView) {
        
        if ([self.delegate respondsToSelector:@selector(VHL_pageViewController:scrollViewDidScroll:)]) {
            [self.delegate VHL_pageViewController:self scrollViewDidScroll:scrollView];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!scrollView.isDragging && !scrollView.isDecelerating) return;
            
            const CGFloat offsetX = 4;
            // 通知生命周期
            // 向左滑动
            //NSLog(@"%f %f %f %d", self.containerView.contentOffset.x, self.preContentOffset.x, self.containerView.contentOffset.x - self.preContentOffset.x, self.containerView.contentOffset.x - self.preContentOffset.x < -offsetX);
            if (self.containerView.contentOffset.x - self.preContentOffset.x > offsetX) {
                if ((self.potentialNextIndex < self.currentIndex) || !self.hasProcessForwardAppearance ) {
                    self.potentialNextIndex = self.currentIndex + 1;
                    [self updateControllersAppearanceStautsWhenDraging];
                    self.hasProcessForwardAppearance = YES;
                }
            }
            // 向右滑动
            else if(self.containerView.contentOffset.x - self.preContentOffset.x < -offsetX) {
                if((self.potentialNextIndex > self.currentIndex) || !self.hasProcessForwardAppearance) {
                    self.potentialNextIndex = self.currentIndex - 1;
                    [self updateControllersAppearanceStautsWhenDraging];
                    self.hasProcessForwardAppearance = YES;
                }
            }
            // 优化连续滚动
            NSInteger cIndex = [self caculateCurrentIndex];
            //if ((int)cIndex - (int)self.currentIndex >= 1 || (int)self.currentIndex - (int)cIndex >= 2) {
            if (self.currentIndex != cIndex) {
                if (self.dataSource && [self.dataSource respondsToSelector:@selector(VHL_pageViewController:viewControllerForIndex:)]) {
                    self.currentIndex = cIndex;
                    if (self.preIndex != self.currentIndex) {
                        [self relayoutCurrentControllerIfNeed];
                        [self relayoutPreControllerIfNeed];
                        [self relayoutNextControllerIfNeed];
                        
                        [self controllerWillAppearAtIndex:self.currentIndex];
                        [self controllerWillDisappearAtIndex:self.currentIndex - 1];
                        [self controllerWillDisappearAtIndex:self.currentIndex + 1];
                        
                        [self removeOtherControllers];
                        self.preIndex = self.currentIndex;
                    }
                } else {
                    // 如果存在潜在的下一个页面
                    [self updateControllersAppearanceStautsWhenEndCelerating];
                }
            }
        });
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.containerView) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(VHL_pageViewController:scrollViewDidEndDecelerating:)]) {
            [self.delegate VHL_pageViewController:self scrollViewDidEndDecelerating:scrollView];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.hasProcessForwardAppearance = NO;
            
            self.currentIndex = [self caculateCurrentIndex];
            if (self.dataSource && [self.dataSource respondsToSelector:@selector(VHL_pageViewController:viewControllerForIndex:)]) {
                //if (self.preIndex != self.currentIndex) {
                [self relayoutCurrentControllerIfNeed];
                [self relayoutPreControllerIfNeed];
                [self relayoutNextControllerIfNeed];
                
                [self updateControllersAppearanceStautsWhenEndCelerating];
                
                [self removeOtherControllers];
                self.preIndex = self.currentIndex;
                //}
            } else {
                // 如果存在潜在的下一个页面
                [self updateControllersAppearanceStautsWhenEndCelerating];
            }
        });
    }
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView == self.containerView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self controllerDidAppearAtIndex:self.currentIndex];
        });
    }
}
#pragma mark - System
// ** 是否自动将生命周期传递给 child viewController ，这里设置为 NO，然后自己来管理 child vc 的生命周期
- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return NO;
}

@end
