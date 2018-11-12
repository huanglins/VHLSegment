//
//  TestViewController.m
//  VPageViewController
//
//  Created by Vincent on 2018/9/26.
//  Copyright © 2018 Darnel Studio. All rights reserved.
//

#import "TestViewController.h"
#import "MJRefresh/MJRefresh.h"
#import "NestViewController.h"
#import "ViewController.h"

#define PageMenuH 40
#define NaviH 64
#define HeaderViewH 200

#define kScreenW [UIScreen mainScreen].bounds.size.width
#define kScreenH [UIScreen mainScreen].bounds.size.height

#define iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define insert (isIPhoneX ? (84+34+PageMenuH) : 0)

@interface TestViewController ()<UITableViewDataSource, UITableViewDelegate>


@property (nonatomic, assign) NSInteger rowCount;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.tableView];
    NSLog(@"%f", self.tableView.frame.size.height);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollHeaderViewToTop) name:@"ScrollHeaderViewToTop" object:nil];
    
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200)];
    headerView.backgroundColor = [UIColor grayColor];
    self.tableView.tableHeaderView = headerView;
    
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        // 上拉加载
        [self upPullLoadMoreData];
    }];
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        // 上拉加载
        [self upPullLoadMoreData];
    }];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = CGRectMake(0, 0, kScreenW, kScreenH-PageMenuH-84);
    //self.tableView.frame = self.view.frame;
}
- (void)scrollHeaderViewToTop{
    // self.tableView.contentOffset = CGPointZero;
    // NSLog(@"%f", 2.1);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// 上拉加载
- (void)upPullLoadMoreData {
    
    self.rowCount = 30;
    [self.tableView reloadData];
    // 模拟网络请求，1秒后结束刷新
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.rowCount = 20;
        [self.tableView.mj_footer endRefreshing];
        [self.tableView.mj_header endRefreshing];
    });
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kScreenW, kScreenH-PageMenuH-84) style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _tableView.showsVerticalScrollIndicator = YES;
        
    }
    return _tableView;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ID = @"cell_2";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
        
        UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 160, 30)];
        infoLabel.userInteractionEnabled = YES;
        infoLabel.text = [NSString stringWithFormat:@"拖动手势 %d-%d-%d", self.tag, (int)indexPath.section, (int)indexPath.row];
        infoLabel.backgroundColor = [UIColor grayColor];
        [cell.contentView addSubview:infoLabel];
        // 拖动手势测试
        UIPanGestureRecognizer *panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
        [infoLabel addGestureRecognizer:panGR];
        // slider test
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(170, 16, 100, 12)];
        [cell.contentView addSubview:slider];
    }
    //cell.textLabel.text = [NSString stringWithFormat:@"第 %d 页，%d-%d", self.tag, (int)indexPath.section, (int)indexPath.row];
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%ld", (long)indexPath.row);
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ViewController *nestVC = [[ViewController alloc] init];
    [self.navigationController pushViewController:nestVC animated:YES];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30.0f)];
    sectionView.backgroundColor = [UIColor redColor];
    return sectionView;
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 滚动时发出通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VHLHoverSubScrollViewDidScroll" object:scrollView];
}

- (void)panAction:(UIGestureRecognizer *)gestureRecognizer {
    NSLog(@"拖动手势");
}

@end
