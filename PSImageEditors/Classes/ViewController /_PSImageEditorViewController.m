//
//  _PSImageEditorViewController.m
//  PSImageEditors
//
//  Created by paintingStyle on 2018/11/15.
//

#import "_PSImageEditorViewController.h"
#import "PSDrawTool.h"
#import "PSMosaicTool.h"
#import "PSTexTool.h"
#import "PSTexItem.h"
#import "PSClippingTool.h"
#import "PSExpandClickAreaButton.h"

@interface _PSImageEditorViewController ()
<UIScrollViewDelegate,
PSTopToolBarDelegate,
PSBottomToolBarDelegate> {
    BOOL _originalNavBarHidden;
	BOOL _originalStatusBarHidden;
	BOOL _originalInteractivePopGestureRecognizer;
    UIImage *_originalImage;
}

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) PSImageToolBase *currentTool;
@property (nonatomic, strong) PSDrawTool *drawTool;
@property (nonatomic, strong) PSMosaicTool *mosaicTool;
@property (nonatomic, strong) PSTexTool *texTool;
@property (nonatomic, strong) PSClippingTool *clippingTool;


@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong, readwrite) PSTopToolBar *topToolBar;
@property (nonatomic, strong, readwrite) PSBottomToolBar *bootomToolBar;
@property (nonatomic, assign) BOOL wilDismiss;
@property (nonatomic, assign) BOOL initializeTools;


@end

@implementation _PSImageEditorViewController

- (instancetype)initWithImage:(UIImage *)image
                     delegate:(id<PSImageEditorDelegate>)delegate
                   dataSource:(id<PSImageEditorDataSource>)dataSource {
    
    if (self = [super init]) {
		_originalNavBarHidden = self.navigationController.navigationBar.hidden;
		_originalStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
		if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]){
			_originalInteractivePopGestureRecognizer = self.navigationController.interactivePopGestureRecognizer.enabled;
		}
		_originalImage = [image ps_imageCompress];
        self.delegate = delegate;
        self.dataSource = dataSource;
    }
    return self;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self configUI];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
	[UIApplication sharedApplication].statusBarHidden = YES;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
	if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]){
		self.navigationController.interactivePopGestureRecognizer.enabled = NO;
	}
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
	[UIApplication sharedApplication].statusBarHidden = _originalStatusBarHidden;
	if (self.wilDismiss) {
		[self.navigationController setNavigationBarHidden:_originalNavBarHidden animated:NO];
		if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]){
			self.navigationController.interactivePopGestureRecognizer.enabled = _originalInteractivePopGestureRecognizer;
		}
	}
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self.topToolBar setToolBarShow:YES animation:YES];
    [self.bottomToolBar setToolBarShow:YES animation:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
	
	if (!self.initializeTools) {
		[self refreshImageView];
		// 绘图画布的加载顺序：text >draw > mosaic，马赛克显示在页面最底层
		[self.mosaicTool initialize];
		[self.drawTool initialize];
		[self.texTool initialize];
	}
	self.initializeTools = YES;
}

- (BOOL)prefersStatusBarHidden {
    
    return YES;
}

- (BOOL)shouldAutorotate {
	
    return NO;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Method

- (void)closeButtonDidClick {
	
	
}

- (void)buildClipImageCallback:(void(^)(UIImage *clipedImage))callback {
	
	if (!self.produceChanges) { // 没有产生改变直接返回原图
		if (callback) { callback(_originalImage); }
		return;
	}
	
    UIImageView *imageView =  self.imageView;
    UIImageView *drawingView =  self.drawTool->_drawingView;
    UIImage *mosaicImage = [self.mosaicTool mosaicImage];
    
    UIGraphicsBeginImageContextWithOptions(imageView.image.size, NO, [UIScreen mainScreen].scale);
    // 画笔
    [imageView.image drawAtPoint:CGPointZero];
	// 马赛克
    [mosaicImage drawAtPoint:CGPointZero];
    [drawingView.image drawInRect:CGRectMake(0, 0, imageView.image.size.width, imageView.image.size.height)];
    // 文字
    for (UIView *view in self.view.subviews) {
        if (![view isKindOfClass:[PSTexItem class]]) { continue; }
        
        PSTexItem *texItem = (PSTexItem *)view;
        [PSTexItem setInactiveTextView:texItem];
        
        CGFloat rotation = [[texItem.layer valueForKeyPath:@"transform.rotation.z"] doubleValue];
        CGFloat selfRw = imageView.bounds.size.width / imageView.image.size.width;
        CGFloat selfRh = imageView.bounds.size.height / imageView.image.size.height;
        
        CGRect texItemRect = [texItem.superview convertRect:texItem.frame toView:self.imageView.superview];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *textImg = [UIImage ps_screenshot:texItem];
            textImg = [textImg ps_imageRotatedByRadians:rotation];
            CGFloat sw = textImg.size.width / selfRw;
            CGFloat sh = textImg.size.height / selfRh;
            [textImg drawInRect:CGRectMake(texItemRect.origin.x/selfRw, texItemRect.origin.y/selfRh, sw, sh)];
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        UIImage *image = [UIImage imageWithCGImage:tmp.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
		if (callback) { callback(image); }
    });
}

- (void)resetImageViewFrame {
    
    CGSize size = (_imageView.image) ? _imageView.image.size : _imageView.frame.size;
    CGFloat ratio = MIN(_scrollView.frame.size.width / size.width, _scrollView.frame.size.height / size.height);
    CGFloat W = ratio * size.width;
    CGFloat H = ratio * size.height;
    _imageView.frame = CGRectMake(0, 0, W, H);
    _imageView.superview.bounds = _imageView.bounds;
}

- (void)resetZoomScaleWithAnimate:(BOOL)animated {
    
    CGFloat Rw = _scrollView.frame.size.width / _imageView.frame.size.width;
    CGFloat Rh = _scrollView.frame.size.height / _imageView.frame.size.height;
	
    CGFloat scale = 1;
    Rw = MAX(Rw, _imageView.image.size.width / (scale * _scrollView.frame.size.width));
    Rh = MAX(Rh, _imageView.image.size.height / (scale * _scrollView.frame.size.height));
    
    _scrollView.contentSize = _imageView.frame.size;
    _scrollView.minimumZoomScale = 1;
    _scrollView.maximumZoomScale = MAX(MAX(Rw, Rh), 1);
    
    [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:animated];
    [self scrollViewDidZoom:_scrollView];
}

- (void)refreshImageView {
	
	if (!_originalImage) { return; }
    [self resetImageViewFrame];
    [self resetZoomScaleWithAnimate:NO];
}

- (void)singleGestureClicked {

	BOOL show = !self.topToolBar.isShow;
	[self hiddenToolBar:!show animation:YES];
}

- (NSDictionary *)drawToolOption {
    
    NSMutableDictionary *option = [NSMutableDictionary dictionary];
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(imageEditorDefaultColor)]) {
        UIColor *defaultColor = [self.dataSource imageEditorDefaultColor];
        [option setObject:defaultColor ?:[UIColor redColor] forKey:kImageToolDrawLineColorKey];
    }
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(imageEditorDrawPathWidth)]) {
        CGFloat drawPathWidth = [self.dataSource imageEditorDrawPathWidth];
        [option setObject:@(MAX(1, drawPathWidth)) forKey:kImageToolDrawLineWidthKey];
    }
    
    return option;
}

- (NSDictionary *)textToolOption {
    
    NSMutableDictionary *option = [NSMutableDictionary dictionary];
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(imageEditorDefaultColor)]) {
        UIColor *defaultColor = [self.dataSource imageEditorDefaultColor];
        [option setObject:defaultColor ?:[UIColor redColor] forKey:kImageToolTextColorKey];
    }
    if (self.dataSource && [self.dataSource respondsToSelector:
                            @selector(imageEditorTextFont)]) {
        UIFont *textFont = [self.dataSource imageEditorTextFont];
        [option setObject:(textFont ? :[UIFont systemFontOfSize:24.0f]) forKey:kImageToolTextFontKey];
    }
    
    return option;
}

- (void)hiddenToolBar:(BOOL)hidden animation:(BOOL)animation {
	
	if (self.editorMode == PSImageEditorModeDraw) {
		[self.drawTool hiddenToolBar:hidden animation:animation];
	}else if (self.editorMode == PSImageEditorModeText) {
		[self.texTool hiddenToolBar:hidden animation:animation];
	}else if (self.editorMode == PSImageEditorModeMosaic) {
		[self.mosaicTool hiddenToolBar:hidden animation:animation];
	}
	
	[self.topToolBar setToolBarShow:!hidden animation:animation];
	[self.bottomToolBar setToolBarShow:!hidden animation:animation];
}

- (void)dismiss {
	
	self.wilDismiss = YES;
	if (self.presentingViewController
		&& self.navigationController.viewControllers.count == 1) {
		[self dismissViewControllerAnimated:YES completion:nil];
	} else {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

#pragma mark - PSTopToolBarDelegate

- (void)topToolBar:(PSTopToolBar *)toolBar event:(PSTopToolBarEvent)event {
    
    switch (event) {
        case PSTopToolBarEventCancel: {
			[self dismiss];
			if (self.delegate && [self.delegate respondsToSelector:@selector(imageEditorDidCancel)]) {
				[self.delegate imageEditorDidCancel];
			}
        }
        break;
        case PSTopToolBarEventDone: {
			[self buildClipImageCallback:^(UIImage *clipedImage) {
				if (self.delegate && [self.delegate respondsToSelector:@selector(imageEditor:didFinishEdittingWithImage:)]) {
					[self.delegate imageEditor:self didFinishEdittingWithImage:clipedImage];
				}
			}];
        }
        break;
        default:
            break;
    }
}

#pragma mark - PSBottomToolBarDelegate

- (void)bottomToolBar:(PSBottomToolBar *)toolBar
		didClickEvent:(PSBottomToolBarEvent)event {
	
	switch (event) {
		case PSBottomToolBarEventDraw:
			self.editorMode = PSImageEditorModeDraw;
			self.currentTool = self.drawTool;
			break;
		case PSBottomToolBarEventText:
			self.editorMode = PSImageEditorModeText;
            self.currentTool = self.texTool;
			break;
		case PSBottomToolBarEventMosaic:
			self.editorMode = PSImageEditorModeMosaic;
            self.currentTool = self.mosaicTool;
			break;
		case PSBottomToolBarEventClipping:
			self.editorMode = PSImageEditorModeClipping;
			self.currentTool = self.clippingTool;
			break;
		case PSBottomToolBarEventUndo:
		{
			if (self.currentTool == self.drawTool) {
				[self.drawTool undo];
				self.bootomToolBar.canUndo = [self.drawTool canUndo];
			}else if (self.currentTool == self.mosaicTool) {
				[self.mosaicTool undo];
				self.bootomToolBar.canUndo = [self.mosaicTool canUndo];
			}
		}
			break;
		case PSBottomToolBarEventDone:
		{
			[self buildClipImageCallback:^(UIImage *clipedImage) {
				if (self.delegate && [self.delegate respondsToSelector:@selector(imageEditor:didFinishEdittingWithImage:)]) {
					[self.delegate imageEditor:self didFinishEdittingWithImage:clipedImage];
				}
			}];
		}
			break;
		default:
			break;
	}
	if (!toolBar.isEditor) { self.currentTool = nil; }
}

#pragma mark- ScrollView

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    return _imageView.superview;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	
	if (self.scrollViewDidZoomBlock) {
		self.scrollViewDidZoomBlock(scrollView.zoomScale);
	}
	
    CGFloat Ws = _scrollView.frame.size.width - _scrollView.contentInset.left - _scrollView.contentInset.right;
    CGFloat Hs = _scrollView.frame.size.height - _scrollView.contentInset.top - _scrollView.contentInset.bottom;
    CGFloat W = _imageView.superview.frame.size.width;
    CGFloat H = _imageView.superview.frame.size.height;
    
    CGRect rct = _imageView.superview.frame;
    rct.origin.x = MAX((Ws-W)/2, 0);
    rct.origin.y = MAX((Hs-H)/2, 0);
    _imageView.superview.frame = rct;
}

#pragma mark - InitAndLayout

- (void)configUI {
    
    self.view.backgroundColor = [UIColor blackColor];
	[self.view addSubview:self.scrollView];
	[self.scrollView addSubview:self.contentView];
	[self.contentView addSubview:self.imageView];
	[self.view addSubview:self.topToolBar];
	[self.view addSubview:self.bottomToolBar];
	
	[self.topToolBar mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.left.right.equalTo(self.view);
		make.height.equalTo(@(PSTopToolBarHeight));
	}];
	[self.bottomToolBar mas_makeConstraints:^(MASConstraintMaker *make) {
		make.left.bottom.right.equalTo(self.view);
		make.height.equalTo(@(PSBottomToolBarHeight));
	}];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
		make.edges.equalTo(self.view);
    }];
    
    [self.topToolBar setToolBarShow:NO animation:NO];
    [self.bottomToolBar setToolBarShow:NO animation:NO];
}

#pragma mark - Getter/Setter

- (BOOL)produceChanges {
	
	return self.drawTool.produceChanges
		   || self.texTool.produceChanges
		   || self.mosaicTool.produceChanges
		   || self.clippingTool.produceChanges;
}

- (void)setCurrentTool:(PSImageToolBase *)currentTool {
	
	if (currentTool != _currentTool){
		[_currentTool cleanup];
		_currentTool = currentTool;
		[_currentTool setup];
		if (!currentTool) { self.editorMode = PSImageEditorModeNone; }
	}
}

- (PSClippingTool *)clippingTool {
    
    return LAZY_LOAD(_clippingTool, ({
        
        _clippingTool = [[PSClippingTool alloc] initWithImageEditor:self withOption:nil];
		@weakify(self);
		_clippingTool.clipedCompleteBlock = ^(UIImage *image, CGRect cropRect) {
			@strongify(self);
			self.imageView.image = image;
			[self refreshImageView];
			[self.drawTool resetRect:cropRect];
			[self.texTool resetRect:cropRect];
			[self.mosaicTool resetRect:cropRect];
		};
        _clippingTool;
    }));
}

- (PSDrawTool *)drawTool {
    
    return LAZY_LOAD(_drawTool, ({
        
		@weakify(self);
        _drawTool = [[PSDrawTool alloc] initWithImageEditor:self withOption:[self drawToolOption]];
		_drawTool.canUndoBlock = ^(BOOL canUndo) {
			@strongify(self);
			if (self.currentTool == _drawTool) {
				self.bootomToolBar.canUndo = canUndo;
			}
		};
        _drawTool;
    }));
}

- (PSMosaicTool *)mosaicTool {
    
    return LAZY_LOAD(_mosaicTool, ({
        @weakify(self);
        _mosaicTool = [[PSMosaicTool alloc] initWithImageEditor:self withOption:nil];
		_mosaicTool.canUndoBlock = ^(BOOL canUndo) {
			@strongify(self);
			if (self.currentTool == _mosaicTool) {
				self.bootomToolBar.canUndo = canUndo;
			}
		};
        _mosaicTool;
    }));
}

- (PSTexTool *)texTool {
    
    return LAZY_LOAD(_texTool, ({
        
        _texTool = [[PSTexTool alloc] initWithImageEditor:self withOption:[self textToolOption]];
        @weakify(self);
        _texTool.dissmissCallback = ^(NSString *currentText) {
            @strongify(self);
            [self.texTool cleanup];
			self.currentTool = nil;
            [self.bottomToolBar reset];
        };
        _texTool;
    }));
}

- (PSBottomToolBar *)bottomToolBar {
	
	return LAZY_LOAD(_bootomToolBar, ({
		
		_bootomToolBar = [[PSBottomToolBar alloc] initWithType:PSBottomToolTypeEditor];
		_bootomToolBar.delegate = self;
		_bootomToolBar;
	}));
}

- (PSTopToolBar *)topToolBar {
    
    return LAZY_LOAD(_topToolBar, ({
        
        _topToolBar = [[PSTopToolBar alloc] initWithType:PSTopToolBarTypeClose];
		_topToolBar.delegate = self;
        _topToolBar;
    }));
}

- (UIImageView *)imageView {
    
    return LAZY_LOAD(_imageView, ({
        
        _imageView = [[UIImageView alloc] initWithImage:_originalImage];
		_imageView.clipsToBounds = YES;
        _imageView;
    }));
}

- (UIView *)contentView {
    
    return LAZY_LOAD(_contentView, ({
        
        _contentView = [[UIView alloc] init];
        _contentView;
    }));
}

- (UIScrollView *)scrollView {
    
    return LAZY_LOAD(_scrollView, ({
        
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.delegate = self;
        _scrollView.multipleTouchEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delaysContentTouches = NO;
        _scrollView.scrollsToTop = NO;
        _scrollView.clipsToBounds = NO;
        if(@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior =
            UIScrollViewContentInsetAdjustmentNever;
        }
		UITapGestureRecognizer *singleGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleGestureClicked)];
		[_scrollView addGestureRecognizer:singleGesture];
        _scrollView;
    }));
}

@end
