//
//  VHLSegment.m
//  VHLPageViewController
//
//  Created by vincent on 2018/10/19.
//  Copyright © 2018年 Darnel Studio. All rights reserved.
//

#import "VHLSegment.h"
#import "VHLSegmentItem.h"

#define scrollViewContentOffset @"contentOffset"

@interface VHLSegment () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>
{
    UICollectionView *_collectionView;
    UIView *_shadow;
}

@property (nonatomic, strong) NSMutableArray *widthArray; // 缓存宽度，避免重复计算宽度耗时

@property (nonatomic, assign) BOOL isFirstLoad;         // 第一次加载
@property (nonatomic, assign) BOOL isDelay;             // 是否延时

@end

@implementation VHLSegment

- (void)dealloc {
    [self.followScrollView removeObserver:self forKeyPath:scrollViewContentOffset];        // 注销监听
}
- (instancetype)init {
    if (self = [super init]) {
        [self buildUI];
    }
    return self;
}

- (void)buildUI {
    self.titles = [NSMutableArray array];
    // 初始化值
    self.itemNormalColor = [UIColor colorWithRed:0.58 green:0.58 blue:0.58 alpha:1.00];
    self.itemSelectedColor = [UIColor colorWithRed:0.00 green:0.48 blue:0.98 alpha:1.00];
    self.itemNormalFont = [UIFont fontWithName:@"PingFangSC-Semibold" size:15];
    self.itemSelectedFont = [UIFont fontWithName:@"PingFangSC-Semibold" size:15];
    self.itemInteritemSpacing = 10;
    self.itemInnerItemSpacing = 0;
    self.shadowStyle = VHLSegmentShadowStyleSpring;
    self.shadowWidth = 10;
    self.shadowHeight = 4;
    self.shadowRadius = 2.0;
    self.shadowMarginBottom = 4;
    self.hideShadow = NO;
    
    // iOS 9 以前没有内置苹方字体
    if (!self.itemNormalFont) {
        self.itemNormalFont = [UIFont boldSystemFontOfSize:15];
        self.itemSelectedFont = [UIFont boldSystemFontOfSize:15];
    }
    
    [self addSubview:[UIView new]];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
//    layout.minimumLineSpacing = ItemMargin;       // 左右间距
//    layout.minimumInteritemSpacing = ItemMargin;  // 上下间距
//    layout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor clearColor];
    [_collectionView registerClass:[VHLSegmentItem class] forCellWithReuseIdentifier:@"VHLSegmentItem"];
    _collectionView.showsHorizontalScrollIndicator = false;
    [self addSubview:_collectionView];
    
    _shadow = [[UIView alloc] init];
    [_collectionView addSubview:_shadow];
    [_collectionView sendSubviewToBack:_shadow];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self relayout];
    [_collectionView sendSubviewToBack:_shadow];
}
- (void)relayout {
    _collectionView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    
    // 预计算 titles 总宽度，判断是否均分屏幕
    CGFloat itemWidthSum = 0;
    if (_needAverageScreen && self.titles.count <= 5) { // 太多就没必要再判断是否均分
        for (int i = 0; i < self.titles.count; i++) {
            CGFloat itemWidth = [self itemWidthOfIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            itemWidthSum += itemWidth;
        }
        itemWidthSum += 10 * self.titles.count;
        if (itemWidthSum <= _collectionView.bounds.size.width) {
            _needAverageScreen = YES;
        } else {
            _needAverageScreen = NO;
        }
    } else {
        _needAverageScreen = NO;
    }
    
    // 设置阴影
    _shadow.backgroundColor = self.shadowColor?self.shadowColor:[self getItemSelectedColorWithIndex:_selectedIndex];
    _shadow.hidden = self.hideShadow;
    _shadow.layer.cornerRadius = self.shadowRadius;
    _shadow.frame = [self shadowRectOfIndex:_selectedIndex];
    
    self.isFirstLoad = YES;
    self.selectedIndex = _selectedIndex;
}

#pragma mark - Setter - shadow
- (void)setShadowWidth:(CGFloat)shadowWidth {
    _shadowWidth = shadowWidth;
    _shadow.frame = [self shadowRectOfIndex:_selectedIndex];
}
- (void)setShadowHeight:(CGFloat)shadowHeight {
    _shadowHeight = shadowHeight;
    _shadow.frame = [self shadowRectOfIndex:_selectedIndex];
}
- (void)setShadowMarginBottom:(CGFloat)shadowMarginBottom {
    _shadowMarginBottom = shadowMarginBottom;
    _shadow.frame = [self shadowRectOfIndex:_selectedIndex];
}
- (void)setHideShadow:(BOOL)hideShadow {
    _hideShadow = hideShadow;
    _shadow.hidden = _hideShadow;
}
#pragma mark setter - item
- (void)setItemInteritemSpacing:(CGFloat)itemInteritemSpacing {
    _itemInteritemSpacing = itemInteritemSpacing;
    [self relayout];
    [_collectionView reloadData];
}
#pragma mark - Setter
- (void)setTitles:(NSArray *)titles {
    _titles = titles;
    // 缓存宽度数组
    self.widthArray = [NSMutableArray array];
    for (int i = 0; i < _titles.count; i++) {
        [self.widthArray addObject:@(0.0)];
    }
    self.isFirstLoad = YES;
    [_collectionView reloadData];
    
    [self chooseTheIndex:0];
    [self relayout];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    if (selectedIndex < 0 || selectedIndex >= self.titles.count) {
        NSLog(@"- 设置选择项错误");
        return;
    }
    VHLSegmentItem *currentItem = (VHLSegmentItem *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0]];
    currentItem.selected = NO;
    currentItem.textLabel.textColor = _itemNormalColor;
    currentItem.textLabel.font = _itemNormalFont;
    
    VHLSegmentItem *nextItem = (VHLSegmentItem *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0]];
    nextItem.selected = YES;
    nextItem.textLabel.textColor = _itemSelectedColor;
    nextItem.textLabel.font = _itemSelectedFont;
    
    _selectedIndex = selectedIndex;
    // 避免 set selectIndex 和 gotoPage 相互影响
    if (!self.isDelay) {
        if ([_delegate respondsToSelector:@selector(slideSegmentDidSelectedAtIndex:)]) {
            [_delegate slideSegmentDidSelectedAtIndex:_selectedIndex];
        }
    }
    
    CGFloat centerX = 10;
    for (NSInteger i = 0; i<=_selectedIndex; i++) {
        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        if (i == _selectedIndex) {
            centerX += [self itemWidthOfIndexPath:indexPath]/2.0;
        } else {
            centerX += [self itemWidthOfIndexPath:indexPath];
        }
    }
    centerX = centerX + selectedIndex * 10;
    
    // * 判断是否是第一次加载，不做动画，避免闪动
    if (self.isFirstLoad) {
        self->_shadow.frame = [self shadowRectOfIndex:self->_selectedIndex];
        self->_shadow.center = CGPointMake(centerX, self->_shadow.center.y);
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self->_shadow.frame = [self shadowRectOfIndex:self->_selectedIndex];
            self->_shadow.center = CGPointMake(centerX, self->_shadow.center.y);  // self.bounds.size.height - self.shadowHeight / 2 - 3
        } completion:^(BOOL finished) {}];
    }
    _shadow.backgroundColor = self.shadowColor?self.shadowColor:[self getItemSelectedColorWithIndex:selectedIndex];
    
    // 居中滚动标题
    if (self->_titles.count <= self->_selectedIndex) return;
    
    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:self->_selectedIndex inSection:0];
    //[self->_collectionView selectItemAtIndexPath:indexPath animated:!self.isFirstLoad scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    [self->_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:!self.isFirstLoad];
    [self->_collectionView reloadData];  // fix: 当选中项不在屏幕内，由滚动触发结束设置时会导致 shadow 正确，但是 item 的选中状态不正确
    
    self.isFirstLoad = NO;
}
- (void)setFollowScrollView:(UIScrollView *)followScrollView {
    if (followScrollView) {
        [followScrollView addObserver:self forKeyPath:scrollViewContentOffset options:NSKeyValueObservingOptionNew context:nil];
    } else {
        [self.followScrollView removeObserver:self forKeyPath:scrollViewContentOffset];        // 注销监听
    }
    _followScrollView = followScrollView;
}
#pragma mark - getter
- (UIColor *)getItemNormalColorWithIndex:(NSInteger)index {
    UIColor *normalColor = self.itemNormalColor;
    if (self.itemNormalColors && self.itemNormalColors.count > index) {
        if ([[self.itemNormalColors objectAtIndex:index] isKindOfClass:[UIColor class]]) {
            normalColor = [self.itemNormalColors objectAtIndex:index];
        }
    }
    return normalColor;
}
- (UIColor *)getItemSelectedColorWithIndex:(NSInteger)index {
    UIColor *selectedColor = self.itemSelectedColor;
    if (self.itemSelectedColors && self.itemSelectedColors.count > index) {
        if ([[self.itemSelectedColors objectAtIndex:index] isKindOfClass:[UIColor class]]) {
            selectedColor = [self.itemSelectedColors objectAtIndex:index];
        }
    }
    return selectedColor;
}
- (UIFont *)getItemNormalFontWithIndex:(NSInteger)index {
    UIFont *normalFont = self.itemNormalFont;
    if (self.itemNormalFonts && self.itemNormalFonts.count > index) {
        if ([[self.itemNormalFonts objectAtIndex:index] isKindOfClass:[UIFont class]]) {
            normalFont = [self.itemNormalFonts objectAtIndex:index];
        }
    }
    return normalFont;
}
- (UIFont *)getItemSelectedFontWithIndex:(NSInteger)index {
    UIFont *selectedFont = self.itemSelectedFont;
    if (self.itemSelectedFonts && self.itemSelectedFonts.count > index) {
        if ([[self.itemSelectedFonts objectAtIndex:index] isKindOfClass:[UIFont class]]) {
            selectedFont = [self.itemSelectedFonts objectAtIndex:index];
        }
    }
    return selectedFont;
}
- (UIImage *)getItemNormalLeftImageWithIndex:(NSInteger)index {
    UIImage *image = nil;
    if (self.itemNormalLeftImages && self.itemNormalLeftImages.count > index) {
        if ([[self.itemNormalLeftImages objectAtIndex:index] isKindOfClass:[UIImage class]]) {
            image = [self.itemNormalLeftImages objectAtIndex:index];
        }
    }
    return image;
}
- (UIImage *)getItemSelectedLeftImageWithIndex:(NSInteger)index {
    UIImage *image = nil;
    if (self.itemSelectLeftImages && self.itemSelectLeftImages.count > index) {
        if ([[self.itemSelectLeftImages objectAtIndex:index] isKindOfClass:[UIImage class]]) {
            image = [self.itemSelectLeftImages objectAtIndex:index];
        }
    }
    return image;
}

#pragma mark - 计算 item 的宽度
- (CGFloat)itemWidthOfIndexPath:(NSIndexPath*)indexPath {
    CGFloat iWidth = 0;
    if (indexPath.row < _titles.count && indexPath.row < _widthArray.count) {
        // 减少计算 boundingRectWithSize
//        CGFloat cacheWidth = [[self.widthArray objectAtIndex:indexPath.row] floatValue];
//        if (cacheWidth > 0) {
//            return cacheWidth;
//        }
        NSString *title = [_titles objectAtIndex:indexPath.row];
        NSStringDrawingOptions opts = NSStringDrawingUsesLineFragmentOrigin |
        NSStringDrawingUsesFontLeading;
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineBreakMode:NSLineBreakByTruncatingTail];
        
        // 选中和未选中的字体取大的一个
        UIFont *calculateFont = [self getItemNormalFontWithIndex:indexPath.row];
        CGFloat pointSize = calculateFont.pointSize;
        if ([self getItemSelectedFontWithIndex:indexPath.row].pointSize > pointSize) {
            calculateFont = [self getItemSelectedFontWithIndex:indexPath.row];
            pointSize = calculateFont.pointSize;
        }
        
        NSDictionary *attributes = @{NSFontAttributeName : calculateFont, NSParagraphStyleAttributeName : style };
        CGSize textSize = [title boundingRectWithSize:CGSizeMake(self.bounds.size.width, self.bounds.size.height)
                                              options:opts
                                           attributes:attributes
                                              context:nil].size;
        
        iWidth = textSize.width + 10;
        // 判断是否有左边图标
        if ([self getItemNormalLeftImageWithIndex:indexPath.row] || [self getItemSelectedLeftImageWithIndex:indexPath.row]) {
            iWidth += 20;
        }
        
        if (self.needAverageScreen) {  // 20 为 layout inset 左右边距
            iWidth = MAX((_collectionView.bounds.size.width - self.titles.count * 20 + 10) / self.titles.count, iWidth);
        }
        // 计算 size 无效的时候，预估一个宽度
        if (iWidth < 20 || textSize.width < 10) {
            iWidth = MAX(iWidth, MAX(15, self.itemSelectedFont.pointSize) * title.length + 10);
        }
        iWidth += MAX(0, self.itemInnerItemSpacing) * 2;
        [_widthArray replaceObjectAtIndex:indexPath.row withObject:@(iWidth)];
    }
    return iWidth;
}
#pragma mark -  获取底部线条的 frame
- (CGRect)shadowRectOfIndex:(NSInteger)index {
    CGFloat wd = [self itemWidthOfIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    CGFloat shadowWidth = self.shadowWidth;
    CGFloat margin = (wd-self.shadowWidth)/2.0;
    if (shadowWidth <= 0) {
        shadowWidth = wd;
        margin = 0;
    }
    
    CGFloat shadowHeight = self.shadowHeight;
    if (shadowHeight < 0) {
        shadowHeight = _collectionView.frame.size.height - self.shadowMarginBottom * 2;
    }
    
    UICollectionViewCell * cell = [_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    CGRect rect = CGRectMake(cell.frame.origin.x+margin, self.bounds.size.height - shadowHeight - self.shadowMarginBottom, self.titles.count > 0?shadowWidth:0.0, shadowHeight);
    return rect;
}
#pragma mark - 进度 - 执行阴影过渡动画
- (void)updateShadowPosition:(CGFloat)progress {
    // progress > 1 向左滑动表格反之向右滑动表格
    NSInteger nextIndex = progress > 1 ? _selectedIndex + 1 : _selectedIndex - 1;
    if (nextIndex == _titles.count) {return;}
    // 如果当前cell 不可见，不做任何操作
    NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:_selectedIndex inSection:0];
    if (![[_collectionView indexPathsForVisibleItems] containsObject:currentIndexPath]) return;
    
    //获取当前阴影位置
    CGRect currentRect = [self shadowRectOfIndex:_selectedIndex];
    CGRect nextRect = [self shadowRectOfIndex:nextIndex];
    //如果在此时cell不在屏幕上 则不显示动画
    if (CGRectGetMinX(currentRect) <= 0 || CGRectGetMinX(nextRect) <= 0) {
        _shadow.frame = currentRect;
        return;
    }
    
    progress = progress > 1 ? progress - 1 : 1 - progress;
    
    // 更新颜色
    if (!self.shadowColor) {
        UIColor *currentSelectedColor = [self getItemSelectedColorWithIndex:_selectedIndex];
        UIColor *nextSelectedColor = [self getItemSelectedColorWithIndex:nextIndex];
        if (currentSelectedColor != nextSelectedColor) {            // 如果两个颜色不一样
            _shadow.backgroundColor = [self transformFromColor:currentSelectedColor toColor:nextSelectedColor progress:progress];
        } else {
            if (0 <= progress && progress <= 0.5) {
                _shadow.backgroundColor = [self transformFromColor:[self getItemSelectedColorWithIndex:_selectedIndex] toColor:[self getItemNormalColorWithIndex:_selectedIndex] progress:progress];
            } else if (0.5 < progress && progress <= 1.0) {
                _shadow.backgroundColor = [self transformFromColor:[self getItemNormalColorWithIndex:nextIndex] toColor:[self getItemSelectedColorWithIndex:nextIndex] progress:progress];
            }
        }
    } else {
        _shadow.backgroundColor = self.shadowColor;
    }
    
    // 更新位置
    CGFloat distance = CGRectGetMidX(nextRect) - CGRectGetMidX(currentRect);
    CGFloat x = CGRectGetMidX(currentRect) + progress * distance;
    // 如果动画的的起点不在屏幕内，则不显示动画
    if (x < _collectionView.contentOffset.x ||
        x > (_collectionView.contentOffset.x + _collectionView.bounds.size.width)) {
        return;
    }
    
    CGFloat xWidth = 0;
    CGRect shadowFrame = _shadow.frame;
    if (0 <= progress && progress <= 0.5) {
        if (self.shadowWidth > 0) {
            xWidth = self.shadowWidth + fabs(distance * (progress / 0.5));
        } else {
            xWidth = CGRectGetWidth(currentRect) + fabs(distance * (progress / 0.5));
        }
    } else if (0.5 < progress && progress <= 1.0) {
        if (self.shadowWidth > 0) {
            xWidth = self.shadowWidth + fabs(distance * ((1 - progress) / 0.5));
        } else {
            xWidth = CGRectGetWidth(nextRect) + fabs(distance * ((1 - progress) / 0.5));
        }
    }
    shadowFrame.size.width = xWidth;
    shadowFrame.origin.x = x - fabs(xWidth / 2);
    [UIView animateWithDuration:0.3 animations:^{
        // 只移动位置
        if (self.shadowStyle == VHLSegmentShadowStyleDefault) {
            self->_shadow.center = CGPointMake(x, self->_shadow.center.y);
        }
        // 位置加线条长度变化
        else if (self.shadowStyle == VHLSegmentShadowStyleSpring) {
            self->_shadow.frame = shadowFrame;
        } else {
            self->_shadow.center = CGPointMake(x, self->_shadow.center.y);
        }
    }];
}

#pragma mark - 进度 - 更新 item 样式
- (void)updateItem:(CGFloat)progress {
    NSInteger nextIndex = progress > 1 ? _selectedIndex + 1 : _selectedIndex - 1;
    if (nextIndex < 0 || nextIndex == _titles.count) {return;}
    
    VHLSegmentItem *currentItem = (VHLSegmentItem *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0]];
    VHLSegmentItem *nextItem = (VHLSegmentItem *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:nextIndex inSection:0]];
    progress = progress > 1 ? progress - 1 : 1 - progress;
    
    // 更新颜色
    if (self.itemStyle == VHLSegmentItemStyleProgress) {
        if (nextIndex < _selectedIndex) {
            [nextItem.textLabel setStartProgress:1 - progress toProgress:1 selectedColor:[self getItemSelectedColorWithIndex:nextIndex]];
            [currentItem.textLabel setStartProgress:1 - progress toProgress:1 selectedColor:[self getItemNormalColorWithIndex:_selectedIndex]];
        } else {
            [nextItem.textLabel setStartProgress:0 toProgress:progress selectedColor:[self getItemSelectedColorWithIndex:nextIndex]];
            [currentItem.textLabel setStartProgress:0 toProgress:progress selectedColor:[self getItemNormalColorWithIndex:_selectedIndex]];
        }
    } else {
        currentItem.textLabel.textColor = [self transformFromColor:[self getItemSelectedColorWithIndex:_selectedIndex] toColor:[self getItemNormalColorWithIndex:_selectedIndex] progress:progress];
        nextItem.textLabel.textColor = [self transformFromColor:[self getItemNormalColorWithIndex:nextIndex] toColor:[self getItemSelectedColorWithIndex:nextIndex] progress:progress];
    }
    
    // 更新字体大小变化，可替换为对 view 的 scale
    UIFont *currentNormalFont = [self getItemNormalFontWithIndex:_selectedIndex];
    UIFont *currentSelectedFont = [self getItemSelectedFontWithIndex:_selectedIndex];
    UIFont *nextNormalFont = [self getItemNormalFontWithIndex:nextIndex];
    UIFont *nextSeletedFont = [self getItemSelectedFontWithIndex:nextIndex];
    
    CGFloat cnFontSize = currentNormalFont.pointSize;
    CGFloat csFontSize = currentSelectedFont.pointSize;
    CGFloat nnFontSize = nextNormalFont.pointSize;
    CGFloat nsFontSize = nextSeletedFont.pointSize;
    
    if (0 <= progress && progress <= 0.5) {
        currentItem.textLabel.font = [currentSelectedFont fontWithSize:csFontSize - (csFontSize - cnFontSize) * progress];
        nextItem.textLabel.font = [nextNormalFont fontWithSize:nnFontSize + (nsFontSize - nnFontSize) * progress];
    } else if (0.5 < progress && progress <= 1.0) {
        currentItem.textLabel.font = [currentNormalFont fontWithSize:csFontSize - (csFontSize - cnFontSize) * progress];
        nextItem.textLabel.font = [nextSeletedFont fontWithSize:nnFontSize + (nsFontSize - nnFontSize) * progress];
    }
    
    if (progress > 0.5) {
        currentItem.selected = NO;
        nextItem.selected = YES;
    } else {
        currentItem.selected = YES;
        nextItem.selected = NO;
    }
}

#pragma mark - Delegate - CollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _titles.count;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake([self itemWidthOfIndexPath:indexPath], _collectionView.bounds.size.height);
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    VHLSegmentItem *item = [collectionView dequeueReusableCellWithReuseIdentifier:@"VHLSegmentItem" forIndexPath:indexPath];
    item.textLabel.text = [_titles objectAtIndex:indexPath.row];
    item.leftImageView.image = [self getItemNormalLeftImageWithIndex:indexPath.row];
    //
    item.textLabel.font = [self getItemNormalFontWithIndex:indexPath.row];
    item.textLabel.textColor = [self getItemNormalColorWithIndex:indexPath.row];
    [item.textLabel setStartProgress:0 toProgress:0 selectedColor:nil];
    
    if (self.selectedIndex == indexPath.row) {
        item.leftImageView.image = [self getItemSelectedLeftImageWithIndex:indexPath.row];
        item.textLabel.font = [self getItemSelectedFontWithIndex:indexPath.row];
        item.textLabel.textColor = [self getItemSelectedColorWithIndex:indexPath.row];
    }
    item.selected = self.selectedIndex == indexPath.row;
    [item relayout];
    
    return item;
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, self.itemInteritemSpacing, 0, self.itemInteritemSpacing);
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.itemInteritemSpacing;  // 每一项的左右间距
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.itemInteritemSpacing;  // 每一项的上下间距
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.isDelay = NO;
    self.selectedIndex = indexPath.row;
}
#pragma mark - KVO - 监听 scrollView offset
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.followScrollView) {
        if ([keyPath isEqualToString:scrollViewContentOffset]) {
            // 当scrolllView滚动时,让跟踪器跟随scrollView滑动
            if (!self.followScrollView.isDragging && !self.followScrollView.isDecelerating) {return;}
            CGFloat pageOffset = self.followScrollView.contentOffset.x / (self.followScrollView.contentSize.width / self.titles.count);
            [self progressAnimationWithPageOffset:pageOffset];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
- (void)progressAnimationWithPageOffset:(CGFloat)pageOffset {
    // ** 连续跨行优化，先将 from 移动到最近的一行,避免切换跳跃
    self.isDelay = YES;     // 标记为滚动触发，避免设置 selectedIndex 后 delegate 相互影响
    // 偏移异常的情况
    if (pageOffset - self.selectedIndex > 2.2) {
        pageOffset -= ((int)pageOffset - self.selectedIndex);
    }
    // 这里加一点小数值，避免整数变浮点数会多一些，比如: 2.00088888
    if (pageOffset - (int)_selectedIndex > 0.999 || pageOffset - (int)_selectedIndex < -1.1) {
        // ** 设置 selectedIndex 后会触发 delegate 进而触发 gotoPage 相互影响 ，在 set selectIndex 中控制回调频率
        if (pageOffset > _selectedIndex) {
            self.selectedIndex = MIN(self.titles.count - 1, ceil((pageOffset - 0.1))); // 向上取整,不超过最大值
        } else {
            self.selectedIndex = MAX(0, floor(pageOffset));      // 向下取整，触发 属性set方法
        }
    } else if(pageOffset > (int)_selectedIndex){
        _selectedIndex = MAX(0, floor(pageOffset));              // 向下取整，不触发 属性set方法
    } else if(fabs((int)pageOffset - pageOffset)<1e-6) {         // 如果是整数
        if (self.selectedIndex != pageOffset) {
            self.selectedIndex = pageOffset;
        }
    }
    // 过渡效果
    CGFloat nProgress = MAX(0, pageOffset) - _selectedIndex;
    nProgress = nProgress > 0 ? nProgress + 1 : 1 - (_selectedIndex - MAX(0, pageOffset));
    
    [self updateItem: nProgress];
    [self updateShadowPosition:nProgress];
}
#pragma mark - public method
- (void)chooseTheIndex:(NSInteger)index {
    self.isDelay = NO;
    self.selectedIndex = index;
}
#pragma mark - 颜色过渡
- (UIColor *)transformFromColor:(UIColor*)fromColor toColor:(UIColor *)toColor progress:(CGFloat)progress {
    if (!fromColor || !toColor) {
        NSLog(@"Warning !!! color is nil");
        return [UIColor blackColor];
    }
    
    progress = progress >= 1 ? 1 : progress;
    progress = progress <= 0 ? 0 : progress;
    
    const CGFloat * fromeComponents = CGColorGetComponents(fromColor.CGColor);
    const CGFloat * toComponents = CGColorGetComponents(toColor.CGColor);
    
    size_t  fromColorNumber = CGColorGetNumberOfComponents(fromColor.CGColor);
    size_t  toColorNumber = CGColorGetNumberOfComponents(toColor.CGColor);
    
    if (fromColorNumber == 2) {
        CGFloat white = fromeComponents[0];
        fromColor = [UIColor colorWithRed:white green:white blue:white alpha:1];
        fromeComponents = CGColorGetComponents(fromColor.CGColor);
    }
    
    if (toColorNumber == 2) {
        CGFloat white = toComponents[0];
        toColor = [UIColor colorWithRed:white green:white blue:white alpha:1];
        toComponents = CGColorGetComponents(toColor.CGColor);
    }
    
    CGFloat red = fromeComponents[0]*(1 - progress) + toComponents[0]*progress;
    CGFloat green = fromeComponents[1]*(1 - progress) + toComponents[1]*progress;
    CGFloat blue = fromeComponents[2]*(1 - progress) + toComponents[2]*progress;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1];
}

@end
