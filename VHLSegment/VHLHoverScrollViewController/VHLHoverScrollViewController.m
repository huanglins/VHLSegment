//
//  VHLSubScrollViewController.m
//  VHLPageViewController
//
//  Created by Vincent on 2018/10/7.
//  Copyright © 2018 Darnel Studio. All rights reserved.
//

#import "VHLHoverScrollViewController.h"

@implementation VHLScrollView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
}

@end

// ---------------------------------------------------------------------------------------------------------------------------
@interface VHLHoverScrollViewController () <UIScrollViewDelegate>

/// 背景ScrollView
@property (nonatomic, strong, readwrite) VHLScrollView *bgScrollView;
/// 当前显示的页面
@property (nonatomic, strong) UIScrollView *currentScrollView;

/// 上次偏移的位置
@property (nonatomic, assign) CGFloat lastPositionX;
/// TableView距离顶部的偏移量
@property (nonatomic, assign) CGFloat insetTop;
// headerView 是否在 tableView 内
@property (nonatomic, assign) BOOL headerViewInTableView;
/// 记录bgScrollView Y 偏移量
@property (nonatomic, assign) CGFloat beginBgScrollOffsetY;
/// 记录currentScrollView Y 偏移量
@property (nonatomic, assign) CGFloat beginCurrentScrollOffsetY;

@end

@implementation VHLHoverScrollViewController

/**
 * 初始化方法
 */
- (instancetype)initWithFrame:(CGRect)frame
                   hoverStyle:(VHLHoverStyle)hoverStyle
                   headerView:(UIView *)headerView
                    hoverView:(UIView *)hoverView
                     bodyView:(UIView *)bodyView {
    if (self = [super init]) {
        self.headerView = headerView;
        self.hoverView = hoverView;
        self.bodyView = bodyView;
        self.hoverStyle = hoverStyle;
        self.view.frame = frame;
    }
    return self;
}
#pragma mark - public method
- (void)showInParentVC:(UIViewController *)parentVC {
    [parentVC addChildViewController:self];
    [parentVC didMoveToParentViewController:self];
    [parentVC.view addSubview:self.view];
}

#pragma mark - getter
- (VHLScrollView *)pageScrollView {
    if (!_pageScrollView) {
        _pageScrollView = [[VHLScrollView alloc] init];
        _pageScrollView.showsVerticalScrollIndicator = NO;
        _pageScrollView.showsHorizontalScrollIndicator = NO;
        _pageScrollView.scrollEnabled = YES;
        _pageScrollView.pagingEnabled = YES;
        _pageScrollView.bounces = NO;
        _pageScrollView.delegate = self;
        _pageScrollView.backgroundColor = [UIColor whiteColor];
        if (@available(iOS 11.0, *)) {
            _pageScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _pageScrollView;
}
- (CGFloat)headerViewHeight {           // 头部视图高度
    if (!self.headerView) {
        return 0.0;
    }
    return self.headerView.frame.size.height;
}
- (CGFloat)hoverViewHeight {
    if (!self.hoverView) {
        return 0.0;
    }
    return self.hoverView.frame.size.height;
}
- (CGFloat)bodyViewHeight {
    if (!self.bodyView) {
        return 0.0;
    }
    return self.bodyView.frame.size.height;
}
#pragma mark - viewDidLoad
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    _headerViewInTableView = YES;

    [self setupSubviews];
    
    // 监听子滚动视图发出的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vhl_subScrollViewDidScroll:) name:VHLHoverSubScrollViewDidScroll object:nil];
}

- (void)setupSubviews {
    [self setupPageScrollView];
    [self setupHeaderView];
    [self setupHoverView];
    [self setupBodyView];
    self.pageScrollView.contentSize = CGSizeMake(self.view.bounds.size.width, [self headerViewHeight] + [self hoverViewHeight] + [self bodyViewHeight]);
}
/// 初始化PageScrollView
- (void)setupPageScrollView {
    self.pageScrollView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    [self.view addSubview:self.pageScrollView];
}
- (void)setupHeaderView {
    CGRect headerRect = self.headerView.frame;
    headerRect.origin.y = 0;
    headerRect.origin.x = 0;
    self.headerView.frame = headerRect;
    [self.pageScrollView addSubview:self.headerView];
}
- (void)setupHoverView {
    CGRect hoverRect = self.hoverView.frame;
    hoverRect.origin.y = [self headerViewHeight];
    hoverRect.origin.x = 0;
    self.hoverView.frame = hoverRect;
    [self.pageScrollView addSubview:self.hoverView];
}
/// 初始化 bodyView
- (void)setupBodyView {
    CGRect bodyRect = self.bodyView.frame;
    bodyRect.origin.y = [self headerViewHeight] + [self hoverViewHeight];
    bodyRect.origin.x = 0;
    self.bodyView.frame = bodyRect;
    [self.pageScrollView addSubview:self.bodyView];
}

#pragma mark - Delegate - UIScrollView
// 将要拖动
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
}
// 停止拖动，是否减速
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
}
// 停止滚动
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}
// 滚动中
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //if (scrollView == self.currentScrollView) {
        //  1. 顶部刷新
        if ((self.currentScrollView && self.currentScrollView.contentOffset.y > 0) || (scrollView.contentOffset.y > 100)) {
            self.currentScrollView.contentOffset = CGPointMake(0, 100);
        }

        // 2. 局部刷新
//        if ((self.currentScrollView && self.currentScrollView.contentOffset.y > 100) && self.currentScrollView.contentOffset.y != 100) {
//            self.currentScrollView.contentOffset = CGPointMake(0, 100); // 悬停
//        } else if ((self.currentScrollView && self.currentScrollView.contentOffset.y < 0) || self.currentScrollView.contentOffset.y < 0) {
//            self.currentScrollView.contentOffset = CGPointZero;         // 到顶
//        }
//    }
}
#pragma mark - 需要联动的子滚动视图滚动事件
- (void)vhl_subScrollViewDidScroll:(NSNotification *)noti {
    UIScrollView *scrollView = (UIScrollView *)noti.object;
    self.currentScrollView = scrollView;
    
    // 1.顶部刷新
    self.currentScrollView.scrollsToTop = NO;
    if (self.currentScrollView.contentOffset.y < 100) {
        scrollView.contentOffset = CGPointZero;
        scrollView.showsVerticalScrollIndicator = NO;
        self.currentScrollView.showsVerticalScrollIndicator = YES;
    } else {
        scrollView.scrollEnabled = YES;
        scrollView.showsVerticalScrollIndicator = YES;
        self.currentScrollView.showsVerticalScrollIndicator = NO;
    }
//
//    CGFloat contentOffY = self.currentScrollView.contentOffset.y;
//    CGFloat pageContentOffY = self.pageScrollView.contentOffset.y;
//    NSLog(@"%f - %f",contentOffY, pageContentOffY);
//    [self calculateContentOffsetY];
}
- (void)calculateContentOffsetY {
    CGFloat contentOffY = self.currentScrollView.contentOffset.y;
    //CGFloat pageContentOffY = self.pageScrollView.contentOffset.y;
    //
    CGRect headerRect = self.headerView.frame;
    headerRect.origin.y = MAX(-[self headerViewHeight], headerRect.origin.y - contentOffY);
    self.currentScrollView.frame = headerRect;
    //
    CGRect hoverRect = self.hoverView.frame;
    hoverRect.origin.y = MAX(0, hoverRect.origin.y - contentOffY);
    self.hoverView.frame = headerRect;
    //
    CGRect bodyRect = self.bodyView.frame;
    bodyRect.origin.y = MAX([self hoverViewHeight], bodyRect.origin.y - contentOffY);
    self.bodyView.frame = bodyRect;
    
    NSLog(@"%f %f %f", headerRect.origin.y, hoverRect.origin.y, bodyRect.origin.y);
}

@end
