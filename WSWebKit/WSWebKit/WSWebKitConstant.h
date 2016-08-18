//
//  WSWebKitConstant.h
//  Pods
//
//  Created by winter on 16/8/9.
//  Copyright © 2016年 王的世界. All rights reserved.
//


#ifndef WSWebKitConstant_h
#define WSWebKitConstant_h

#include <UIKit/UIKit.h>

const NSString const *KCHost = @"127.1.1.1";

/// 窗体类型
typedef NS_ENUM(NSInteger,KCWinStyle)
{
    KCWinStyleModal = 1 << 0,
    KCWinStyleNormal = 1 << 1
};
/// 操作
typedef NS_ENUM(NSInteger,KCOP)
{
    KCOPOpenWindow = 1 << 0,
    KCOPCloseWindow = 1 << 1,
    KCOPConsole = 1 << 2,  /// log
    KCOPAjax = 1 << 3  /// ajax crossdomain
};


//#define currentBundle 


#endif /* WSWebKitConstant_h */
