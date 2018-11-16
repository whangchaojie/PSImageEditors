//
//  PSImageObject.h
//  Pods-PSImageEditors
//
//  Created by rsf on 2018/8/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PSImageObject : NSObject

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, copy)   NSURL *url;

@property (nonatomic, strong, nullable) UIImage *image;
@property (nonatomic, strong, nullable) FLAnimatedImage *GIFImage;
@property (nonatomic, copy) NSString *originSize;

@property (nonatomic, assign, getter=isScaling) BOOL scaling;

/// 是否处于编辑模式
@property (nonatomic, assign, getter=isEditor) BOOL editor;

/// 是否开启双击缩放
@property (nonatomic, assign, getter=isDoubleClickZoom) BOOL doubleClickZoom;

@property (nonatomic, assign) CGSize displayContentSize;

@property (nonatomic, copy) void(^fetchOriginSizeBlock)(NSString *originSize);

+ (instancetype)imageObjectWithIndex:(NSInteger)index
								 url:(NSURL *)url
							   image:(UIImage *)image
							GIFImage:(FLAnimatedImage *)GIFImage;

- (void)calculateDisplayContentSize;

@end

NS_ASSUME_NONNULL_END