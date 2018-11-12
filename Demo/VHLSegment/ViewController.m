//
//  ViewController.m
//  VPageViewController
//
//  Created by Vincent on 2018/9/26.
//  Copyright © 2018 Darnel Studio. All rights reserved.
//

#import "ViewController.h"
#import "MJRefresh/MJRefresh.h"
#import "TestViewController.h"

#import "VHLSegmentControl.h"

#import "VHLHoverScrollViewController.h"

@interface ViewController () <VHLSegmentDelegate, VHLPageViewControllerDataSource, VHLPageViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

//@property (nonatomic, strong) MyTableView *tableView;
@property (nonatomic, strong) UIView *headerView;

@property (nonatomic, strong) VHLSegmentControl *segmentControl;
@property (nonatomic, strong) VHLSegment *segment;
@property (nonatomic, strong) VHLPageViewController *pageVC;

@property (nonatomic, strong) CALayer * bottomLine;

@property (nonatomic, strong) UIScrollView *subScrollView;          // 子滚动视图
@property (nonatomic, assign) CGPoint subScrollViewLastOffset;      // 子滚动视图上一次偏移

@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *viewControllers;

@end

@implementation ViewController

- (VHLSegment *)segment {
    if (!_segment) {
        _segment = [[VHLSegment alloc] init];
        _segment.frame = CGRectMake(0, 0, self.view.frame.size.width, 44 - 0.5);
        _segment.shadowStyle = VHLSegmentShadowStyleSpring;
        _segment.itemSelectedColor = [UIColor colorWithRed:0.00 green:0.49 blue:1.00 alpha:1.00];
        //_segment.itemSelectedColor = [UIColor whiteColor];
        _segment.itemSelectedColors = @[[UIColor redColor], [UIColor blueColor]];
//        _segment.itemNormalFont = [UIFont fontWithName:@"PingFangSC-Light" size:15];
//        _segment.itemNormalLeftImages = @[[UIImage imageNamed:@"s_logo1"],@"",@"",[UIImage imageNamed:@"s_shalou"]];
//        _segment.itemSelectLeftImages = @[[UIImage imageNamed:@"s_logo"],@"",[UIImage imageNamed:@"s_logo"],@"",[UIImage imageNamed:@"s_logo"]];
//        _segment.itemStyle = VHLSegmentItemStyleProgress;
//        _segment.itemInteritemSpacing = 6;
//        _segment.itemInnerItemSpacing = 0;
//        //_segment.shadowColor = [UIColor grayColor];
//        _segment.shadowRadius = 2;
//        _segment.shadowWidth = -1;
//        _segment.shadowHeight = 4;
        _segment.shadowMarginBottom = 2;
        _segment.needAverageScreen = YES;
        _segment.delegate = self;
    }
    return _segment;
}
- (VHLPageViewController *)pageVC {
    if (!_pageVC) {
        _pageVC = [[VHLPageViewController alloc] init];
        _pageVC.view.frame = CGRectMake(0, _segment.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height - _segment.frame.size.height);
        _pageVC.containerView.hitShieldClassNameArray = @[@"UISlider",@"UILabel"];
        _pageVC.dataSource = self;
        _pageVC.delegate = self;
    }
    return _pageVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    
//    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
//    footerView.backgroundColor = [UIColor yellowColor];
//    self.tableView.tableFooterView = footerView;
    
    //NSLog(@"%f %f", [[UIScreen mainScreen] currentMode].size.width, [[UIScreen mainScreen] currentMode].size.height);
    // Do any additional setup after loading the view, typically from a nib.
    self.titles = [NSMutableArray array];
    self.viewControllers = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        TestViewController *testvc = [TestViewController new];
        testvc.tag = i;
        [self.viewControllers addObject:testvc];
        [self.titles addObject:[NSString stringWithFormat:@"segment %d", i]];
    }
    
    // 1.
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 300)];
    headerView.userInteractionEnabled = YES;
    headerView.backgroundColor = [UIColor grayColor];
    
    self.segment.titles = self.titles;
    self.segment.followScrollView = self.pageVC.containerView;
    [self addChildViewController:self.pageVC];
    
    VHLHoverScrollViewController *hoverVC = [[VHLHoverScrollViewController alloc] initWithFrame:self.view.bounds hoverStyle:VHLHoverStyleCenter headerView:headerView hoverView:self.segment bodyView:self.pageVC.view];
    [self.view addSubview:hoverVC.view];
    [self addChildViewController:hoverVC];
    
//    // new
//    self.segmentControl = [[VHLSegmentControl alloc] initWithFrame:self.tableView.bounds Titles:self.titles viewControllers:self.viewControllers];
//    //设置代理
//    self.segmentControl.backgroundColor = [UIColor whiteColor];
//    self.segmentControl.itemSelectedColor = [UIColor colorWithRed:0.00 green:0.49 blue:1.00 alpha:1.00];
////    segmentControl.itemNormalFont = [UIFont fontWithName:@"PingFangSC-Semibold" size:15];
////    segmentControl.itemSelectedFont = [UIFont fontWithName:@"PingFangSC-Semibold" size:16];
//
//    self.segmentControl.shadowStyle = ShadowStyleSpring;
//    self.segmentControl.shadowWidth = 10;
//    self.segmentControl.selectedIndex = 1;
//    // self.segmentControl.pageVC.containerView.delegate = self;
//
//    [self addChildViewController:self.segmentControl.pageVC];
//    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 84, self.view.bounds.size.width, self.view.bounds.size.height - 84) style:UITableViewStylePlain];
//    self.tableView.dataSource = self;
//    self.tableView.delegate = self;
//    self.tableView.tag = 9999;
//    self.tableView.showsVerticalScrollIndicator = NO;
//    self.tableView.tableFooterView = [UIView new];
//    //    self.tableView.delaysContentTouches = YES;
//    //    self.tableView.canCancelContentTouches = NO;
//    [self.view addSubview:self.tableView];
//
//    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
//        // 下拉刷新
//        [self.tableView.mj_header endRefreshing];
//        //[self downPullUpdateData];
//    }];
//
//    // 1. 头部刷新
//    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
//    self.headerView.backgroundColor = [UIColor greenColor];
//    self.tableView.tableHeaderView = self.headerView;
//
//    // 2. 局部刷新
////    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
////    self.headerView.backgroundColor = [UIColor greenColor];
////    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
////    headerView.backgroundColor = [UIColor clearColor];
////    self.tableView.tableHeaderView = headerView;
////    [self.tableView insertSubview:self.headerView atIndex:0];
//
//    self.segment.titles = self.titles;
//    self.segment.followScrollView = self.pageVC.containerView;
//    [self addChildViewController:self.pageVC];
//
//    // 监听子控制器发出的通知
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subTableViewDidScroll:) name:@"SubTableViewDidScroll" object:nil];
    //显示方法
    //[segmentControl showInViewController:self];
    //[segmentControl showInNavigationController:self.navigationController];
    
    // page 单独测试
//    VHLPageViewController *pageVC = [[VHLPageViewController alloc] init];
//    pageVC.dataSource = self;
//    pageVC.delegate = self;
//    pageVC.view.frame = self.view.frame;
//    [self addChildViewController:pageVC];
//    [self.view addSubview:pageVC.view];
}
#pragma mark - DataSource - VHLPageViewControllerDataSource
- (NSInteger)VHL_numberOfControllersInPageViewController:(VHLPageViewController *)pageViewController {
    return self.viewControllers.count;
}
- (UIViewController *)VHL_pageViewController:(VHLPageViewController *)pageViewController viewControllerForIndex:(NSInteger)index {
    return [self.viewControllers objectAtIndex:index];
}
#pragma mark - DataSource - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    //
    [cell.contentView addSubview:self.segment];
    [cell.contentView addSubview:self.pageVC.view];
    // 底部浅色分割线
    self.bottomLine = [CALayer new];
    [cell.contentView.layer addSublayer:self.bottomLine];
    self.bottomLine.backgroundColor = [UIColor colorWithRed:0.95 green:0.96 blue:0.96 alpha:1.00].CGColor;
    self.bottomLine.frame = CGRectMake(0, _segment.frame.size.height - 0.5, cell.contentView.bounds.size.width, 0.5);
    
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.segment.bounds.size.height + self.pageVC.view.bounds.size.height;
}
#pragma mark VHLSegmentDelegate ---------------------------------------------
//- (void)slideSegmentDidSelectedAtIndex:(NSInteger)index {
//    [self switchToIndex:index];
//}
#pragma mark - VHLPageViewControllerDelegate
//- (void)VHL_pageViewController:(VHLPageViewController *)pageViewController didAppearController:(UIViewController *)controller atIndex:(NSInteger)index {
//    [_segment chooseTheIndex:index];
//}
#pragma mark - scrollView -------------------------------------------------------------------------------------
//- (void)subTableViewDidScroll:(NSNotification *)noti {
//
//    UIScrollView *scrollView = (UIScrollView *)noti.object;
//    self.subScrollView = scrollView;
//
//    // 1.顶部刷新
//    self.subScrollView.scrollsToTop = NO;
//    if (self.tableView.contentOffset.y < 100) {
//        scrollView.contentOffset = CGPointZero;
//        scrollView.showsVerticalScrollIndicator = NO;
//        self.tableView.showsVerticalScrollIndicator = YES;
//    } else {
//        scrollView.scrollEnabled = YES;
//        scrollView.showsVerticalScrollIndicator = YES;
//        self.tableView.showsVerticalScrollIndicator = NO;
//    }
//
//    // 2. 局部刷新
////    self.tableView.scrollsToTop = YES;
////    if (self.tableView.contentOffset.y < 100) {
////        scrollView.showsVerticalScrollIndicator = YES;
////        NSLog(@"%f %f", self.subScrollView.contentOffset.y, self.tableView.contentOffset.y);
////        if ((self.subScrollView.contentOffset.y > 0 && self.subScrollView.contentOffset.y < 100) ||
////            (self.tableView.contentOffset.y > 0 && self.tableView.contentOffset.y < 100)) {
////            // ** 需要通过设置 headerView 和 segment 的 origin y 来达到移动的效果，设置 contentOffset 是不行的
//////            NSLog(@"%f %f", self.subScrollView.contentOffset.y, self.tableView.contentOffset.y);
//////            CGFloat offsetDifference = scrollView.contentOffset.y - self.subScrollViewLastOffset.y;
//////
//////            CGRect segmentBounds = self.segmentControl.segment.bounds;
//////            segmentBounds.origin.y -= offsetDifference;
//////            self.segmentControl.segment.frame = segmentBounds;
//////
//////            CGRect headerBounds = self.headerView.bounds;
//////            headerBounds.origin.y -= offsetDifference;
//////            self.headerView.bounds = headerBounds;
//////            NSLog(@"bounds y %f %f", self.headerView.bounds.origin.y, self.segmentControl.segment.bounds.origin.y);
////            //self.tableView.contentOffset = CGPointMake(0, self.subScrollView.contentOffset.y * 2);
////        }
////    } else {
////        CGRect segmentBounds = self.segmentControl.segment.bounds;
////        segmentBounds.origin.y = 0;
////        self.segmentControl.segment.frame = segmentBounds;
////
////        CGRect headerBounds = self.headerView.bounds;
////        headerBounds.origin.y = 0;
////        self.headerView.bounds = headerBounds;
////
////        self.subScrollViewLastOffset = CGPointMake(0, 0);
////        scrollView.showsVerticalScrollIndicator = YES;
////    }
////    self.subScrollViewLastOffset = scrollView.contentOffset;
//}
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    if (scrollView == self.tableView) {
//        //  1. 顶部刷新
//        if ((self.subScrollView && self.subScrollView.contentOffset.y > 0) || (scrollView.contentOffset.y > 100)) {
//            self.tableView.contentOffset = CGPointMake(0, 100);
//        }
//
//        // 2. 局部刷新
////        if ((self.subScrollView && self.subScrollView.contentOffset.y > 100) && self.tableView.contentOffset.y != 100) {
////            self.tableView.contentOffset = CGPointMake(0, 100); // 悬停
////        } else if ((self.subScrollView && self.subScrollView.contentOffset.y < 0) || self.tableView.contentOffset.y < 0) {
////            self.tableView.contentOffset = CGPointZero;         // 到顶
////        }
////
////        // ** 这里可以根据 tableview contentOffset，比如根据 offset 处理 headerView 的过渡效果
////        CGFloat offSetY = scrollView.contentOffset.y;
////        // 滚动出悬停通知
////        if (offSetY < 100) {
////            [[NSNotificationCenter defaultCenter] postNotificationName:@"ScrollHeaderViewToTop" object:nil];
////        }
//    }
//}
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//    self.tableView.scrollEnabled = YES;
//}
//#pragma mark 其他方法 --------------------------------------------------------------------
//- (void)switchToIndex:(NSInteger)index {
//    if (index < 0 || _viewControllers.count <= index) return;
//    [_pageVC gotoPageWithIndex:index animated:YES];
//}

@end
