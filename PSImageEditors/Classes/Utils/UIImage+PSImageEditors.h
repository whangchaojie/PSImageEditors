//
//  UIImage+PSImageEditors.h
//  PSImageEditors
//
//  Created by paintingStyle on 2018/8/25.
//

#import <UIKit/UIKit.h>

@interface UIImage (PSImageEditors)

+ (UIImage *)ps_imageNamed:(NSString *)name;

+ (NSBundle *)bundleForClass:(Class)class withBundleName:(NSString *)name;
	
/** 通过遍历像素点实现马赛克效果,level越大,马赛克颗粒越大,若level为0则默认为图片1/20 */
+ (UIImage *)ps_mosaicImage:(UIImage *)image level:(NSInteger)level;

/** 截屏 */
+ (UIImage *)ps_screenshot:(UIView *)view imageRect:(CGRect)imageRect;

/** 图片解码 */
- (UIImage *)ps_decode;

/** 图片旋转角度 */
- (UIImage *)ps_imageRotatedByRadians:(CGFloat)radians;

/** 根据image本身创建指定rect的image */
- (UIImage *)ps_imageAtRect:(CGRect)rect;

/** 压缩图片 */
- (UIImage *)ps_imageCompress;

@end
