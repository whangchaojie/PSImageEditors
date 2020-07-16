<p align="center" >
  <img src="https://github.com/paintingStyle/PSImageEditors/blob/master/Screenshot/logo.png" alt="PSImageEditors" title="PSImageEditors">
</p>



![image1](https://raw.github.com/PSImageEditors/PSImageEditors/Screenshot/logo.png)

![image2](https://upload.jianshu.io/admin_banners/web_images/4991/f35f847410c2d919aee3f40701e6c2e8d234661e.jpg?imageMogr2/auto-orient/strip|imageView2/1/w/1250/h/540)


# PSImageEditors
简而至美的一个图片编辑器
- 支持图片编辑，包括涂鸦，添加文字，添加马赛克，裁剪等功能

## 画笔
![image](https://github.com/paintingStyle/PSImageEditors/blob/master/Screenshot/1.jpg)

## 文字（支持更换文字背景颜色）
![image](https://github.com/paintingStyle/PSImageEditors/blob/master/Screenshot/2.jpg)

## 马赛克（两种马赛克样式）
![image](https://github.com/paintingStyle/PSImageEditors/blob/master/Screenshot/3.jpg)

## 裁剪
![image](https://github.com/paintingStyle/PSImageEditors/blob/master/Screenshot/4.jpg)

## Requirements 要求
* iOS 8+
* Xcode 8+

## Installation 安装
### 1.手动安装:
`下载Demo后,将子文件夹PSImageEditors拖入到项目中, 导入头文件PSImageEditors.h开始使用,注意: 项目中需要有Masonry.1.1.0!`
### 2.CocoaPods安装:
`pod 'PSImageEditors'`
如果发现pod search PSImageEditors 不是最新版本，可在终端执行 pod repo update 更新本地仓库，更新完成重新搜索即可。

## Usage 使用方法

````
<key>NSAppTransportSecurity</key>
<dict>
<key>NSAllowsArbitraryLoads</key>
<true/>
</dict>
<key>NSCameraUsageDescription</key>
<string>App需要您的同意,才能访问相机</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>App需要您的同意,才能访问相册</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>App需要您的同意,才能访问相册</string>
````

## 使用方法

导入头文件 #import "PSImageEditors.h"

## 更新日志
```
• 2018.06.14(tag:0.1.0): 提交0.1.0版本
```
