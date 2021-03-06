//
//  PSTexTool.m
//  PSImageEditors
//
//  Created by rsf on 2018/11/16.
//

#import "PSTexTool.h"
#import "PSTopToolBar.h"
#import "PSBottomToolBar.h"
#import "PSColorToolBar.h"
#import "PSMovingView.h"
#import "UIView+PSImageEditors.h"

static const NSInteger kTextMaxLimitNumber = 100;
static NSString *kDefalutText = @"点击输入";
#define kDefalutFont [UIFont systemFontOfSize:18]
#define kDefalutColor PSColorFromRGB(0xff1d12)

@interface PSTexTool()

@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIFont *textFont;
@property (nonatomic, strong) PSColorToolBar *colorToolBar;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, assign) BOOL initializeTextItem;

@end

@implementation PSTexTool

#pragma mark - Subclasses Override

- (void)initialize {
    [super initialize];
	
	if (!_drawingView) {
	   self.initializeTextItem = YES;
	  _drawingView = [[UIImageView alloc] initWithFrame:self.editor.imageView.bounds];
	  [self.editor.imageView addSubview:_drawingView];
	}
}

- (void)resetRect:(CGRect)rect {
	
	_drawingView.frame = self.editor.imageView.bounds;
	[_drawingView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if ([obj isKindOfClass:[PSMovingView class]]) {
			[obj removeFromSuperview];
		}
	}];
}

- (UIImage *)textImage {
	
	[PSMovingView setActiveEmoticonView:nil];
	UIImage *image = [_drawingView captureImageAtFrame:_drawingView.bounds];
	return image;
}

- (void)setup {
    
    [super setup];
    
	_drawingView.userInteractionEnabled = YES;
	self.editor.imageView.userInteractionEnabled = YES;
    self.textColor = self.option[kImageToolTextColorKey];
    self.textFont = self.option[kImageToolTextFontKey];
   
	if (!self.tapGesture) {
		 self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(drawingViewDidTap:)];
		 [_drawingView addGestureRecognizer:self.tapGesture];
	 }
	self.tapGesture.enabled = YES;
	
	if (!self.colorToolBar) {
	   self.colorToolBar = [[PSColorToolBar alloc] initWithType:PSColorToolBarTypeColor];
	   self.colorToolBar.delegate = self;
	   [self.editor.view addSubview:self.colorToolBar];
	   [self.colorToolBar mas_makeConstraints:^(MASConstraintMaker *make) {
		   make.bottom.equalTo(self.editor.bottomToolBar.editorItemsView.mas_top);
		   make.left.right.equalTo(self.editor.view);
		   make.height.equalTo(@(PSDrawColorToolBarHeight));
	   }];
   }
   [self.colorToolBar setToolBarShow:YES animation:NO];
   [self setItemsEnabled:YES];
	
	if (self.initializeTextItem) {
		NSDictionary *attrs = @{
				NSBackgroundColorAttributeName:[UIColor clearColor],
				NSForegroundColorAttributeName:kDefalutColor,
				NSFontAttributeName:kDefalutFont,
			};
		[self addTextItemWithText:kDefalutText
							withAttrs:attrs
							withPoint:CGPointMake(_drawingView.bounds.size.width *0.5, _drawingView.bounds.size.height *0.5)];
		self.initializeTextItem = NO;
	}else {
		[PSMovingView setActiveEmoticonView:[self activeMovingView]];
	}
	
}

- (void)refresUndoState {
    
	if ([self canUndo]) {
		[self.editor addTrajectoryName:NSStringFromClass([self class])];
	}
}

- (void)cleanup {
    [super cleanup];
	
	_drawingView.userInteractionEnabled = NO;
	self.editor.imageView.userInteractionEnabled = NO;
	self.tapGesture.enabled = NO;
	
	[PSMovingView setActiveEmoticonView:nil];
	[self.colorToolBar setToolBarShow:NO animation:NO];
	[self setItemsEnabled:NO];
}

- (void)addTextItemWithText:(NSString *)text
				  withAttrs:(NSDictionary *)attrs
				  withPoint:(CGPoint)point {
	
	// 过滤颜色卡的点击范围
	if (CGRectGetMinY(self.colorToolBar.frame) >0 && (point.y > CGRectGetMinY(self.colorToolBar.frame))) { return; }
	
	UIColor *fillColor = attrs[NSBackgroundColorAttributeName];
	UIColor *strokeColor = attrs[NSForegroundColorAttributeName];
	UIFont *font = attrs[NSFontAttributeName];

	CGPoint center = point;
	// 修正超长图文字的显示位置
	if (CGRectGetHeight(self.editor.imageView.frame) >PS_SCREEN_H)
	{ center.y = self.editor.scrollView.contentOffset.y + PS_SCREEN_H *0.5; }

	NSAttributedString *attribString = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:font,
																									NSForegroundColorAttributeName:strokeColor,
																									NSBackgroundColorAttributeName:fillColor}];
	
	PSStickerItem *item = [PSStickerItem mainWithAttributedText:attribString imageRect:self.editor.imageView.bounds];
	PSMovingView *movingView = [[PSMovingView alloc] initWithItem:item];
	movingView.bottomSafeDistance = CGRectGetHeight(self.colorToolBar.frame);
	movingView.imageView = self.editor.imageView;
	movingView.center = center;
	
	[PSMovingView setActiveEmoticonView:movingView];
	[_drawingView insertSubview:movingView belowSubview:self.editor.topToolBar];
	
	__weak typeof(self)weakSelf = self;
	[movingView setTapEnded:^BOOL(PSMovingView * _Nonnull view, CGPoint point) {
		// 优先处理关闭按钮
		BOOL clickClose = point.x <= (CGRectGetMaxX(weakSelf.editor.topToolBar.frame) +10)
						  && point.y <= (CGRectGetMaxY(weakSelf.editor.topToolBar.frame) +10);
		if (clickClose) {
			[weakSelf.editor dismiss];
		}else if (view.isActive) {
			[weakSelf presentTextViewWithView:view];
		}
		return !clickClose;
	}];
	[movingView setMoveCenter:^(UIGestureRecognizerState state) {
		if (weakSelf.editor.editorMode != PSImageEditorModeText) { return; }
		
		if (state == UIGestureRecognizerStateEnded) {
			[weakSelf.colorToolBar setToolBarShow:YES animation:YES];
		}else {
			[weakSelf.colorToolBar setToolBarShow:NO animation:YES];
		}
	}];
	[movingView setDelete:^{
		[weakSelf.editor removeLastTrajectoryName:NSStringFromClass([self class])];
	}];
	
	self.editor.scrollViewDidZoomBlock = ^(CGFloat zoomScale) {
		[weakSelf.editor.view.subviews enumerateObjectsUsingBlock:
		 ^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			if ([obj isKindOfClass:[PSMovingView class]]) {
				[((PSMovingView *)obj) setScale:zoomScale];
			}
		}];
	};
	
	
	[self refresUndoState];
}

- (BOOL)canUndo {
	return [self activeMovingView];
}

- (void)undo {
	[[self activeMovingView] removeFromSuperview];
}

- (void)presentTextViewWithView:(PSMovingView *)view {

	self.tapGesture.enabled = NO;
	
	self.textView = [[PSTextView alloc] initWithFrame:self.editor.view.bounds];
	self.textView.inputView.textColor = self.textColor;
	self.textView.inputView.font = self.textFont;

	// 点击了激活的item，再次进入编辑模式
	NSRange range = NSMakeRange(0, view.item.attributedText.string.length);
	NSMutableDictionary *attrs = [view.item.attributedText attributesAtIndex:0 effectiveRange:&range];
	UIColor *fillColor = attrs[NSBackgroundColorAttributeName];
	UIColor *strokeColor = attrs[NSForegroundColorAttributeName];
	UIFont *font = kDefalutFont;
	
	self.textView.inputView.text = [view.item.attributedText.string isEqualToString:kDefalutText] ? @"":view.item.attributedText.string;
	self.textView.attrs = @{NSFontAttributeName:font,
							NSForegroundColorAttributeName:strokeColor,
							NSBackgroundColorAttributeName:fillColor};

	__weak typeof(self)weakSelf = self;
	self.textView.dissmissBlock = ^(NSString *text, NSDictionary *attrs, BOOL done) {
		
		if (!done) {
			[view removeFromSuperview];
			[weakSelf.textView removeFromSuperview];
			weakSelf.tapGesture.enabled = YES;
			[weakSelf.editor removeLastTrajectory];
			return;
		}
		
		UIColor *fillColor = attrs[NSBackgroundColorAttributeName];
		UIColor *strokeColor = attrs[NSForegroundColorAttributeName];
		UIFont *font = kDefalutFont;

		NSAttributedString *attribString = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:font,
																										   NSForegroundColorAttributeName:strokeColor,
																										   NSBackgroundColorAttributeName:fillColor}];
		PSStickerItem *item = [PSStickerItem mainWithAttributedText:attribString imageRect:self.editor.imageView.bounds];
		view.item = item;
		[weakSelf.textView removeFromSuperview];
		weakSelf.tapGesture.enabled = YES;
	};
	if (!self.textView.superview) {
		[self.editor.view addSubview:self.textView];
	}
}

- (void)drawingViewDidTap:(UITapGestureRecognizer *)tap {
	
	CGPoint point = [tap locationInView:tap.view];
	// 修正超长图文字的显示位置
	if (CGRectGetHeight(self.editor.imageView.frame) >PS_SCREEN_H) { point.y = self.editor.scrollView.contentOffset.y + PS_SCREEN_H *0.5; }

	NSDictionary *attrs = @{
		NSBackgroundColorAttributeName:[UIColor clearColor],
		NSForegroundColorAttributeName:self.colorToolBar.currentColor,
		NSFontAttributeName:kDefalutFont,
	};
	NSAttributedString *attribString = [[NSAttributedString alloc] initWithString:kDefalutText attributes:attrs];
	PSStickerItem *item = [PSStickerItem mainWithAttributedText:attribString imageRect:self.editor.imageView.bounds];
	CGRect itemRect = item.displayView.bounds;
	CGFloat startCenterX = (itemRect.size.width *0.5) +11;
	CGFloat endCenterX = CGRectGetWidth(_drawingView.frame)- ((itemRect.size.width +22) *0.5);

	if (point.x <startCenterX) {
		point = CGPointMake(startCenterX, point.y);
	}
	if (point.x >endCenterX) {
		point = CGPointMake(endCenterX, point.y);
	}
	
	[self addTextItemWithText:kDefalutText
						withAttrs:attrs
						withPoint:point];
}

- (void)executeWithCompletionBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock {
    
}

- (void)changeColor:(NSNotification *)notification {
    
	UIColor *panColor = (UIColor *)notification.object;
    if (panColor && self.textView) {
        [self.textView.inputView setTextColor:panColor];
    }
}

- (void)setItemsEnabled:(BOOL)enabled {
	
	[_drawingView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		   if ([obj isKindOfClass:[PSMovingView class]]) {
			    obj.userInteractionEnabled = enabled;
		   }
	}];
}

- (BOOL)produceChanges {
	
	__block BOOL containsTexItem = NO;
	[_drawingView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if ([obj isKindOfClass:[PSMovingView class]]) {
			containsTexItem = YES;
			*stop = YES;
		}
	}];
	
	return containsTexItem;
}

- (PSMovingView *)activeMovingView {
	
	PSMovingView *activeMovingView = nil;
	NSArray *subviews = _drawingView.subviews;
	for (UIView *obj in subviews) {
		if ([obj isKindOfClass:[PSMovingView class]]) {
			activeMovingView = obj;
		}
	}
	
	return activeMovingView;
}

@end


#pragma mark - PSTextView

@interface PSTextView () <UITextViewDelegate,PSTopToolBarDelegate,PSColorToolBarDelegate>

@property (nonatomic, strong) PSTopToolBar *topToolBar;
@property (nonatomic, strong) PSColorToolBar *colorToolBar;
@property (nonatomic, strong) NSString *needReplaceString;
@property (nonatomic, assign) NSRange   needReplaceRange;
@property (nonatomic, assign) BOOL wilDismiss;

@end

@implementation PSTextView

- (void)setAttrs:(NSDictionary *)attrs {
    
    _attrs = attrs;
    if (!attrs.allValues.count) { return; }
    
    UIColor *fillColor = attrs[NSBackgroundColorAttributeName];
    UIColor *strokeColor = attrs[NSForegroundColorAttributeName];
    
    self.colorToolBar.changeBgColor = !CGColorEqualToColor(fillColor.CGColor, [UIColor clearColor].CGColor);
    self.colorToolBar.currentColor = self.colorToolBar.changeBgColor ? fillColor:strokeColor;
	[self.colorToolBar setChangeBgColorButtonSelected:!CGColorEqualToColor(fillColor.CGColor, [UIColor clearColor].CGColor)];
	
    [self refreshTextViewDisplay];
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor clearColor];
        self.wilDismiss = NO;
        
        __weak typeof(self)weakSelf = self;
        
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        self.effectView = [[UIVisualEffectView alloc] initWithEffect:blur];
        self.effectView.frame = frame;
        [self addSubview:self.effectView];
        
        self.topToolBar = [[PSTopToolBar alloc] initWithType:PSTopToolBarTypeCancelAndDoneIcon];
        self.topToolBar.delegate = self;
        self.topToolBar.frame = CGRectMake(0, 0, PS_SCREEN_W, PSTextTopToolBarHeight);
        [self addSubview:self.topToolBar];
        
        self.inputView = [[UITextView alloc] init];
        CGRect frame = CGRectInset(self.bounds, 15, 0);
        frame.origin.y = CGRectGetMaxY(self.topToolBar.frame);
        frame.size.height -= CGRectGetMaxY(self.topToolBar.frame);
        self.inputView.frame = frame;
        self.inputView.scrollEnabled = YES;
        self.inputView.returnKeyType = UIReturnKeyDone;
        self.inputView.backgroundColor = [UIColor clearColor];
        self.inputView.delegate = self;
        [self addSubview:self.inputView];
        
        self.colorToolBar = [[PSColorToolBar alloc] initWithType:PSColorToolBarTypeText];
        self.colorToolBar.delegate = self;
        self.colorToolBar.frame = CGRectMake(0, 0, PS_SCREEN_W, PSTextColorToolBarHeight);
        self.inputView.inputAccessoryView = self.colorToolBar;
		
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - PSTopToolBarDelegate

- (void)topToolBar:(PSTopToolBar *)toolBar event:(PSTopToolBarEvent)event {
    
    if (event == PSTopToolBarEventCancel) {
        [self dismissTextEditing:NO];
    }else {
        [self dismissTextEditing:YES];
    }
}

#pragma makr - PSColorToolBarDelegate

- (void)colorToolBar:(PSColorToolBar *)toolBar event:(PSColorToolBarEvent)event {
    
    if (event == PSColorToolBarEventSelectColor ||
        event == PSColorToolBarEventChangeBgColor) {
        [self refreshTextViewDisplay];
    }
}

- (void)refreshTextViewDisplay {
    
    NSDictionary *attributes = nil;
    UIColor *bgcolor = self.colorToolBar.currentColor ? :kDefalutColor;
    UIColor *textColor = self.colorToolBar.currentColor ? :[UIColor whiteColor];
    UIFont *font = self.inputView.font ? :[UIFont systemFontOfSize:24.f weight:UIFontWeightRegular];
    
    if (self.colorToolBar.isChangeBgColor) {
        // 当处于改变文字背景的模式，背景颜色为白色，文字为黑色，其他情况统一为白色
        if ([self.colorToolBar isWhiteColor]) {
            textColor = [UIColor blackColor];
        }else {
            textColor = [UIColor whiteColor];
        }
        attributes = @{
                       NSFontAttributeName:font,
                       NSForegroundColorAttributeName:textColor,
                       NSBackgroundColorAttributeName:bgcolor
                       };
    }else {
        attributes = @{
                       NSFontAttributeName:font,
                       NSForegroundColorAttributeName:textColor,
                       NSBackgroundColorAttributeName:[UIColor clearColor]
                       };
    }
    self.inputView.attributedText = [[NSAttributedString alloc] initWithString:self.inputView.text
                                                                   attributes:attributes];
}

- (void)keyboardWillShow:(NSNotification *)notification {
	
    NSDictionary *userinfo = notification.userInfo;
    CGRect  keyboardRect              = [[userinfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardAnimationDuration = [[userinfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions keyboardAnimationCurve = [[userinfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    self.hidden = YES;
    [UIView animateWithDuration:keyboardAnimationDuration delay:keyboardAnimationDuration options:keyboardAnimationCurve animations:^{
        
        CGRect frame = self.inputView.frame;
        frame.size.height = [UIScreen mainScreen].bounds.size.height - keyboardRect.size.height;
        self.inputView.frame = frame;
        
        CGRect frame2 = self.frame;
        frame2.origin.y = 0;
        self.frame = frame2;
        
    } completion:^(BOOL finished) {}];
    
    [UIView animateWithDuration:3 animations:^{
        self.hidden = NO;
    }];
    
}

- (void)keyboardWillHide:(NSNotification *)notification {
    
    NSDictionary *userinfo = notification.userInfo;
    CGFloat keyboardAnimationDuration = [[userinfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions keyboardAnimationCurve = [[userinfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [UIView animateWithDuration:keyboardAnimationDuration delay:0.f options:keyboardAnimationCurve animations:^{
        
        CGRect frame = self.frame;
        frame.origin.y = CGRectGetHeight(self.effectView.frame);
        self.frame = frame;
    } completion:^(BOOL finished) {
        if (!self.wilDismiss) { // 处理非用户操作造成的键盘收起情况，关闭页面，比如收到通话邀请
            [self dismissTextEditing:YES];
        }
    }];
}

- (void)dismissTextEditing:(BOOL)done {
    
    self.wilDismiss = YES;
    
    NSDictionary *attrs = nil;
    if (self.inputView.text.length) {
        NSRange range = NSMakeRange(0, self.inputView.text.length);
		attrs = [self.inputView.attributedText attributesAtIndex:0 effectiveRange:&range];
	}else {
		attrs = @{
			NSBackgroundColorAttributeName:[UIColor clearColor],
			NSForegroundColorAttributeName:kDefalutColor,
			NSFontAttributeName:kDefalutFont};
	}
	
    if (self.dissmissBlock) {
		NSString *text = self.inputView.text.length ? self.inputView.text:kDefalutText;
        self.dissmissBlock(text, attrs, done);
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.inputView becomeFirstResponder];
            [self.inputView scrollRangeToVisible:NSMakeRange(self.inputView.text.length-1, 0)];
        });
    } else {
        
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    
    // 选中范围的标记
    UITextRange *textSelectedRange = [textView markedTextRange];
    // 获取高亮部分
    UITextPosition *textPosition = [textView positionFromPosition:textSelectedRange.start offset:0];
    // 如果在变化中是高亮部分在变, 就不要计算字符了
    if (textSelectedRange && textPosition) {
        return;
    }
    // 文本内容
    NSString *textContentStr = textView.text;
    NSInteger existTextNumber = textContentStr.length;
    
    if (existTextNumber > kTextMaxLimitNumber) {
        // 截取到最大位置的字符(由于超出截取部分在should时被处理了,所以在这里为了提高效率不在判断)
        NSString *str = [textContentStr substringToIndex:kTextMaxLimitNumber];
        [textView setText:str];
        //[AlertBox showMessage:@"输入字符不能超过100\n多余部分已截断" hideAfter:3];
    }
    [self refreshTextViewDisplay];
}

- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text {
    
    if ([text isEqualToString:@"\n"]) {
        [self dismissTextEditing:YES];
        return NO;
    }
    
    UITextRange *selectedRange = [textView markedTextRange];
    //获取高亮部分
    UITextPosition *pos = [textView positionFromPosition:selectedRange.start offset:0];
    
    //如果有高亮且当前字数开始位置小于最大限制时允许输入
    if (selectedRange && pos) {
        NSInteger startOffset = [textView offsetFromPosition:textView.beginningOfDocument toPosition:selectedRange.start];
        NSInteger endOffset = [textView offsetFromPosition:textView.beginningOfDocument toPosition:selectedRange.end];
        NSRange offsetRange = NSMakeRange(startOffset, endOffset - startOffset);
        
        if (offsetRange.location < kTextMaxLimitNumber && textView.text.length - offsetRange.length <= kTextMaxLimitNumber) {
            self.needReplaceRange = offsetRange;
            self.needReplaceString = text;
            return YES;
        }
        else
        {
            return NO;
        }
    }
    
    
    NSString *comcatstr = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    NSInteger caninputlen = kTextMaxLimitNumber - comcatstr.length;
    
    if (caninputlen >= 0)
    {
        return YES;
    }
    else
    {
        NSInteger len = text.length + caninputlen;
        //防止当text.length + caninputlen < 0时，使得rg.length为一个非法最大正数出错
        NSRange rg = {0,MAX(len,0)};
        
        if (rg.length > 0)
        {
            NSString *s = @"";
            //判断是否只普通的字符或asc码(对于中文和表情返回NO)
            BOOL asc = [text canBeConvertedToEncoding:NSASCIIStringEncoding];
            if (asc) {
                s = [text substringWithRange:rg];//因为是ascii码直接取就可以了不会错
            }
            else
            {
                __block NSInteger idx = 0;
                __block NSString  *trimString = @"";//截取出的字串
                //使用字符串遍历，这个方法能准确知道每个emoji是占一个unicode还是两个
                [text enumerateSubstringsInRange:NSMakeRange(0, [text length])
                                         options:NSStringEnumerationByComposedCharacterSequences
                                      usingBlock: ^(NSString* substring, NSRange substringRange, NSRange enclosingRange, BOOL* stop) {
                                          
                                          NSInteger steplen = substring.length;
                                          if (idx >= rg.length) {
                                              *stop = YES; //取出所需要就break，提高效率
                                              return ;
                                          }
                                          
                                          trimString = [trimString stringByAppendingString:substring];
                                          
                                          idx = idx + steplen;//这里变化了，使用了字串占的长度来作为步长
                                      }];
                
                s = trimString;
            }
            //rang是指从当前光标处进行替换处理(注意如果执行此句后面返回的是YES会触发didchange事件)
            [textView setText:[textView.text stringByReplacingCharactersInRange:range withString:s]];
        }
        return NO;
    }
}

@end

