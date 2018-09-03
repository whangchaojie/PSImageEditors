//
//  PSTextBoard.m
//  PSImageEditors
//
//  Created by paintingStyle on 2018/8/29.
//

#import "PSTextBoard.h"

static const CGFloat kTopOffset = 0.f;
static const CGFloat kTextTopOffset = 0.f;
static const NSInteger kTextMaxLimitNumber = 100;
static const CGFloat kColorToolBarHeight = 48.0f;

#import "PSTopToolBar.h"
#import "PSColorToolBar.h"

@implementation PSTextBoard

- (void)setup {
    
	
    //self.previewImageView.scrollView.pinchGestureRecognizer.enabled = NO;

    __weak typeof(self)weakSelf = self;
    self.textView = [[PSTextView alloc] initWithFrame:CGRectMake(0, kTopOffset, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - kTopOffset)];
    self.textView.textView.textColor = self.currentColor;
    self.textView.textView.font = [UIFont systemFontOfSize:24.f weight:UIFontWeightRegular];
//    self.editor.backButton.enabled = NO;
//    self.editor.undoButton.enabled = NO;
    self.textView.dissmissTextTool = ^(NSString *currentText, BOOL isUse) {
     
//        weakSelf.editor.scrollView.pinchGestureRecognizer.enabled = YES;
//        weakSelf.editor.backButton.enabled = YES;
//        weakSelf.editor.undoButton.enabled = YES;
        
        if (weakSelf.isEditAgain) {
            if (weakSelf.editAgainCallback && isUse) {
                weakSelf.editAgainCallback(currentText);
            }
            weakSelf.isEditAgain = NO;
        } else {
            if (isUse) {
                [weakSelf addNewText:currentText];
            }
        }
        
        weakSelf.dissmissTextTool(currentText);
    };
    [self.editorView addSubview:self.textView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeColor:) name:@"kColorPanNotificaiton" object:nil];
    //TODO: todo?
}

- (void)cleanup {
    
    [self.textView removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kColorPanNotificaiton" object:nil];
    //TODO: todo?
}

- (void)executeWithCompletionBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock {
    
}

- (void)changeColor:(NSNotification *)notification {
    UIColor *panColor = (UIColor *)notification.object;
    if (panColor && self.textView) {
        [self.textView.textView setTextColor:panColor];
    }
}

- (void)addNewText:(NSString *)text
{
    if (text == nil || text.length <= 0) {
        return;
    }
    
//    CGPoint point = [self.previewView.imageView.superview convertPoint:self.previewView.imageView.center
//                                                    toView:self.previewView.drawingView];
	CGPoint point = [self.previewView.imageView convertPoint:self.previewView.imageView.center
													  toView:self.previewView.drawingView];
    // 修正超长图文字的显示位置
    if (CGRectGetHeight(self.previewView.imageView.frame) >PS_SCREEN_H) {
        point.y = self.previewView.scrollView.contentOffset.y + PS_SCREEN_H *0.5;
    }
    
    PSTextBoardItem *view = [[PSTextBoardItem alloc] initWithTool:self text:text font:self.textView.textView.font orImage:nil];
    view.delegate = self.itemDelegate;
    view.fillColor = self.currentColor;
    view.borderColor = [UIColor whiteColor];
    view.font = self.textView.textView.font;
    view.text = text;
    view.center = point;
    view.userInteractionEnabled = YES;
    [self.previewView.drawingView addSubview:view];

    [PSTextBoardItem setActiveTextView:view];
}

@end


#pragma mark - PSTextView

@interface PSTextView () <UITextViewDelegate,PSTopToolBarDelegate,PSColorToolBarDelegate>

@property (nonatomic, strong) PSTopToolBar *topToolBar;
@property (nonatomic, strong) PSColorToolBar *colorToolBar;
@property (nonatomic, strong) NSString *needReplaceString;
@property (nonatomic, assign) NSRange   needReplaceRange;

@end

@implementation PSTextView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        __weak typeof(self)weakSelf = self;
        
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        self.effectView = [[UIVisualEffectView alloc] initWithEffect:blur];
        self.effectView.frame = CGRectMake(0, -kTopOffset, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        [self addSubview:self.effectView];
        
        self.topToolBar = [[PSTopToolBar alloc] initWithType:PSTopToolTypeCancelAndDoneIcon];
        self.topToolBar.delegate = self;
        self.topToolBar.frame = CGRectMake(0, 0, PS_SCREEN_W, PS_NAV_BAR_H);
        [self addSubview:self.topToolBar];
        
        self.textView = [[UITextView alloc] init];
        CGRect frame = CGRectInset(self.bounds, 15, 0);
        frame.origin.y = kTextTopOffset+PS_NAV_BAR_H;
        frame.size.height -= PS_NAV_BAR_H;
        self.textView.frame = frame;
        self.textView.scrollEnabled = YES;
        self.textView.returnKeyType = UIReturnKeyDone;
        self.textView.delegate = self;
        self.textView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.textView];
        
        self.colorToolBar = [[PSColorToolBar alloc] initWithType:PSColorToolBarTypeText];
        self.colorToolBar.delegate = self;
        self.colorToolBar.frame = CGRectMake(0, 0, PS_SCREEN_W, kColorToolBarHeight);
        self.textView.inputAccessoryView = self.colorToolBar;
        
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

- (void)topToolBarType:(PSTopToolType)type event:(PSTopToolEvent)event {
    
    if (event == PSTopToolEventCancel) {
        [self dismissTextEditing:NO];
    }else if (event == PSTopToolEventDone) {
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
    UIColor *bgcolor = self.colorToolBar.currentColor ? :[UIColor redColor];
    UIColor *textColor = self.colorToolBar.currentColor ? :[UIColor whiteColor];
    UIFont *font = self.textView.font ? :[UIFont systemFontOfSize:24.f weight:UIFontWeightRegular];
    
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
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.textView.text
                                                                   attributes:attributes];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userinfo = notification.userInfo;
    CGRect  keyboardRect              = [[userinfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardAnimationDuration = [[userinfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions keyboardAnimationCurve = [[userinfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    
    self.hidden = YES;
    [UIView animateWithDuration:keyboardAnimationDuration delay:keyboardAnimationDuration options:keyboardAnimationCurve animations:^{
        
        CGRect frame = self.textView.frame;
        frame.size.height = [UIScreen mainScreen].bounds.size.height - keyboardRect.size.height - kTextTopOffset;
        self.textView.frame = frame;
        
        CGRect frame2 = self.frame;
        frame2.origin.y = kTopOffset;
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
        frame.origin.y = CGRectGetHeight(self.effectView.frame) + kTopOffset;
        self.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)dismissTextEditing:(BOOL)done {
    
    [self.textView resignFirstResponder];
    if (self.dissmissTextTool) {
        self.dissmissTextTool(self.textView.text, done);
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.textView becomeFirstResponder];
            [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length-1, 0)];
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
    NSLog(@"text = %@",textView.text);
    NSInteger existTextNumber = textContentStr.length;
    
    if (existTextNumber > kTextMaxLimitNumber) {
        // 截取到最大位置的字符(由于超出截取部分在should时被处理了,所以在这里为了提高效率不在判断)
        NSString *str = [textContentStr substringToIndex:kTextMaxLimitNumber];
        [textView setText:str];
        //[AlertBox showMessage:@"输入字符不能超过100\n多余部分已截断" hideAfter:3];
    }
     [self refreshTextViewDisplay];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSLog(@"%@", text);
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
