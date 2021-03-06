//
//  PSColorToolBar.h
//  PSImageEditors
//
//  Created by rsf on 2018/11/16.
//

#import "PSEditorToolBar.h"
@class PSColorToolBar;

typedef NS_ENUM(NSInteger, PSColorToolBarType) {
    
    PSColorToolBarTypeColor =0,
    PSColorToolBarTypeText
};

typedef NS_ENUM(NSUInteger, PSColorToolBarEvent) {
	
	PSColorToolBarEventSelectColor = 0,
	PSColorToolBarEventChangeBgColor
};

@protocol PSColorToolBarDelegate<NSObject>

@optional

- (void)colorToolBar:(PSColorToolBar *)toolBar event:(PSColorToolBarEvent)event;

@end

@interface PSColorToolBar : PSEditorToolBar

- (instancetype)initWithType:(PSColorToolBarType)type;

// 当前颜色
@property (nonatomic, strong) UIColor *currentColor;

/// 是否可以改变文字颜色
@property (nonatomic, assign, getter=isChangeBgColor) BOOL changeBgColor;

@property (nonatomic, weak) id<PSColorToolBarDelegate> delegate;

- (BOOL)isWhiteColor;
- (void)setChangeBgColorButtonSelected:(BOOL)selected;

@end
