//
//  VHLSubScrollViewController.h
//  VHLPageViewController
//
//  Created by Vincent on 2018/10/7.
//  Copyright © 2018 Darnel Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "VHLSegment.h"
#import "VHLPageViewController.h"


// 重写 pan 手势判定，让 tableView 能响应子滚动视图的手势
@interface VHLScrollView : UIScrollView

@end

// --------------------------------------------------------------------------------
#define VHLHoverSubScrollViewDidScroll @"VHLHoverSubScrollViewDidScroll"

/**
    嵌套滚动视图封装，顶部 headerView / 悬停 hoverView / 主内容 bodyView
 
    ** bodyView 中的 subScrollView 需要在 scrollViewDidScroll 代理中发送 VHLHoverSubScrollViewDidScroll 的通知，用于悬停联动 **
 */

typedef NS_ENUM(NSUInteger, VHLHoverStyle) {
    VHLHoverStyleTop,               // HeaderView 可拉动（滚动条从顶部开始）
    VHLHoverStyleTop2,              // HeaderView 可拉动（滚动条从子滚动视图开始）
    VHLHoverStyleCenter,            // 子滚动视图 可拉动 (下拉刷新在悬停视图下)
};

@interface VHLHoverScrollViewController : UIViewController

@property (nonatomic, strong) VHLScrollView *pageScrollView;

/** 头部视图*/
@property (nonatomic, strong) UIView *headerView;
/** 悬停视图*/
@property (nonatomic, strong) UIView *hoverView;
/** 主内容视图*/
@property (nonatomic, strong) UIView *bodyView;
/** 悬停方式*/
@property (nonatomic, assign) VHLHoverStyle hoverStyle;

/**
 * 初始化方法
 */
- (instancetype)initWithFrame:(CGRect)frame
                   hoverStyle:(VHLHoverStyle)hoverStyle
                   headerView:(UIView *)headerView
                    hoverView:(UIView *)hoverView
                     bodyView:(UIView *)bodyView;

- (void)showInParentVC:(UIViewController *)parentVC;

@end
