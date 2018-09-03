//
//  PSTopToolBar.m
//  PSImageEditors
//
//  Created by paintingStyle on 2018/8/25.
//

#import "PSTopToolBar.h"

#pragma mark - 色板

#define SPAP_COLOR_1  UIColorFromRGB(0x26242a)
#define SPAP_COLOR_2  UIColorFromRGB(0x666666)
#define SPAP_COLOR_3  UIColorFromRGB(0x999999)
#define SPAP_COLOR_4  UIColorFromRGB(0xbbbbbb)
#define SPAP_COLOR_5  UIColorFromRGB(0xcccccc)
#define SPAP_COLOR_6  UIColorFromRGB(0xe6e6e6)
#define SPAP_COLOR_7  UIColorFromRGB(0x4393f9)
#define SPAP_COLOR_8  UIColorFromRGBA(0x4393f9, 0.5)
#define SPAP_COLOR_9  UIColorFromRGB(0xf2f6f9)
#define SPAP_COLOR_10  UIColorFromRGB(0xffffff)
#define SPAP_COLOR_11  UIColorFromRGB(0x4ccfaf)
#define SPAP_COLOR_12  UIColorFromRGB(0xfe6972)
#define SPAP_COLOR_13  UIColorFromRGB(0xf5fafe)
#define SPAP_COLOR_14  UIColorFromRGB(0xfafafa)


#pragma mark - 字体

#define SPAP_FONT_SIZE_1  32
#define SPAP_FONT_SIZE_2  18
#define SPAP_FONT_SIZE_3  16
#define SPAP_FONT_SIZE_4  14
#define SPAP_FONT_SIZE_5  12
#define SPAP_FONT_SIZE_6  10
#define SPAP_FONT_SIZE_7  9

@interface PSTopToolBar()

@property (nonatomic, assign) PSTopToolType type;

// PSTopToolTypeDefault
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;

// PSTopToolTypeCancelAndDoneText
@property (nonatomic, strong) UIImageView *maskImageView;

@end

@implementation PSTopToolBar

- (void)setTitle:(NSString *)title {
	
	_title = title;
	self.titleLabel.text = title;
}

- (instancetype)initWithType:(PSTopToolType)type {
    
    if (self = [super init]) {
		self.type = type;
		self.show = YES;
        switch (type) {
            case PSTopToolTypeDefault:
                [self configDefaultUI];
                break;
            case PSTopToolTypePreview:
                [self configPreviewUI];
                break;
            case PSTopToolTypeCancelAndDoneText:
                [self configCancelAndDoneTextUI];
                break;
            case PSTopToolTypeCancelAndDoneIcon:
                [self configCancelAndDoneIconUI];
                break;
            default:
                break;
        }
    }
    return self;
}

- (void)setToolBarShow:(BOOL)show animation:(BOOL)animation {
	
	[UIView animateWithDuration:(animation ? 0.15:0) animations:^{
		if (show) {
			self.transform = CGAffineTransformIdentity;
		}else{
			self.transform = CGAffineTransformMakeTranslation(0, -PS_NAV_BAR_H);
		}
	} completion:^(BOOL finished) {
		self.show = show;
	}];
}

- (void)buttonDidClickSender:(UIButton *)btn {

	PSTopToolEvent event;
	if (btn == self.leftButton) {
		if (self.type == PSTopToolTypeCancelAndDoneText ||
			self.type == PSTopToolTypeCancelAndDoneIcon) {
			event = PSTopToolEventCancel;
		}else {
			event = PSTopToolEventBack;
		}
	}else if (btn == self.rightButton) {
		if (self.type == PSTopToolTypeCancelAndDoneText ||
			self.type == PSTopToolTypeCancelAndDoneIcon) {
			event = PSTopToolEventDone;
		}else {
			event = PSTopToolEventMore;
		}
	}
	if (self.delegate && [self.delegate respondsToSelector:
						  @selector(topToolBarType:event:)]) {
		[self.delegate topToolBarType:self.type event:event];
	}
}

- (void)configDefaultUI {
	
	self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6f];
	
	[self.leftButton setImage:[UIImage ps_imageNamed:@"btn_navBar_back"]
				 forState:UIControlStateNormal];
	[self addSubview:self.leftButton];
	
	[self.rightButton setImage:[UIImage ps_imageNamed:@"btn_previewView_more"]
				  forState:UIControlStateNormal];
	[self addSubview:self.rightButton];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    [self addSubview:self.titleLabel];
	
    [self.leftButton mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.equalTo(@44);
        make.left.equalTo(@15);
        make.centerY.equalTo(self).offset(PS_STATUS_BAR_H *0.5);
    }];
    
    [self.rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.equalTo(@44);
        make.right.equalTo(@(-15));
        make.centerY.equalTo(self.leftButton);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.equalTo(self.leftButton.mas_right).offset(15);
        make.right.equalTo(self.rightButton.mas_left).offset(-15);
        make.centerY.equalTo(self).offset(PS_STATUS_BAR_H *0.5);
    }];
}


- (void)configPreviewUI {
    
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6f];
}

- (void)configCancelAndDoneTextUI {
	
	[self addSubview:self.maskImageView];
	[self.maskImageView mas_makeConstraints:^(MASConstraintMaker *make) {
		make.edges.equalTo(self);
	}];
	
	[self.leftButton setTitle:@"取消" forState:UIControlStateNormal];
	[self.leftButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self addSubview:self.leftButton];
	
	[self.rightButton setTitle:@"完成" forState:UIControlStateNormal];
	[self.rightButton setTitleColor:PSColorFromRGB(0x4393f9) forState:UIControlStateNormal];
	[self addSubview:self.rightButton];
	
	[self.leftButton mas_makeConstraints:^(MASConstraintMaker *make) {
		
		make.size.equalTo(@44);
		make.left.equalTo(@15);
		make.centerY.equalTo(self).offset(PS_STATUS_BAR_H *0.5);
	}];
	
	[self.rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
		
		make.size.equalTo(@44);
		make.right.equalTo(@(-15));
		make.centerY.equalTo(self.leftButton);
	}];
}

- (void)configCancelAndDoneIconUI {

    [self addSubview:self.maskImageView];
    [self.maskImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [self.leftButton setImage:[UIImage ps_imageNamed:@"btn_cancel"]
                     forState:UIControlStateNormal];
    [self addSubview:self.leftButton];
    
    [self.rightButton setImage:[UIImage ps_imageNamed:@"btn_done"]
                      forState:UIControlStateNormal];
    [self addSubview:self.rightButton];
    
    
    [self.leftButton mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.equalTo(@44);
        make.left.equalTo(@15);
        make.centerY.equalTo(self).offset(PS_STATUS_BAR_H *0.5);
    }];
    
    [self.rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.equalTo(@44);
        make.right.equalTo(@(-15));
        make.centerY.equalTo(self.leftButton);
    }];
}

- (UIImageView *)maskImageView {
	
	return LAZY_LOAD(_maskImageView, ({
		
		_maskImageView = [[UIImageView alloc] initWithImage:[UIImage ps_imageNamed:@"icon_mask_top"]];
		_maskImageView;
	}));
}

- (UIButton *)leftButton {
	
	return LAZY_LOAD(_leftButton, ({
		
		_leftButton = [[UIButton alloc] init];
		[_leftButton setFrame:CGRectMake(0, 0, 44, 44)];
		_leftButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
		[_leftButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
		[_leftButton addTarget:self action:@selector(buttonDidClickSender:) forControlEvents:UIControlEventTouchUpInside];
		_leftButton;
	}));
}

- (UIButton *)rightButton {
	
	return LAZY_LOAD(_rightButton, ({
		
		_rightButton = [[UIButton alloc] init];
		[_rightButton setFrame:CGRectMake(0, 0, 44, 44)];
		_rightButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
		[_rightButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
		[_rightButton addTarget:self action:@selector(buttonDidClickSender:) forControlEvents:UIControlEventTouchUpInside];
		_rightButton;
	}));
}

@end

