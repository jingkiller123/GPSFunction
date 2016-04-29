//
//  ZLocationManager.h
//  MultiFunctions
//
//  Created by apple on 16/4/15.
//  Copyright © 2016年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


/**
 *  	// User has not yet made a choice with regards to this application
	kCLAuthorizationStatusNotDetermined = 0,
 
	// This application is not authorized to use location services.  Due
	// to active restrictions on location services, the user cannot change
	// this status, and may not have personally denied authorization
	kCLAuthorizationStatusRestricted,
 
	// User has explicitly denied authorization for this application, or
	// location services are disabled in Settings.
	kCLAuthorizationStatusDenied,
 
	// User has granted authorization to use their location at any time,
	// including monitoring for regions, visits, or significant location changes.
	kCLAuthorizationStatusAuthorizedAlways NS_ENUM_AVAILABLE(NA, 8_0),
 
	// User has granted authorization to use their location only when your app
	// is visible to them (it will be made visible to them if you continue to
	// receive location updates while in the background).  Authorization to use
	// launch APIs has not been granted.
	kCLAuthorizationStatusAuthorizedWhenInUse NS_ENUM_AVAILABLE(NA, 8_0),
 
	// This value is deprecated, but was equivalent to the new -Always value.
	kCLAuthorizationStatusAuthorized NS_ENUM_DEPRECATED(10_6, NA, 2_0, 8_0, "Use kCLAuthorizationStatusAuthorizedAlways") __TVOS_PROHIBITED __WATCHOS_PROHIBITED = kCLAuthorizationStatusAuthorizedAlways
 */
typedef NS_ENUM(NSUInteger, GPSAuthorizationStatus) {
    
    GPSAuthorizationNotDetermined = 0,
    GPSAuthorizationRestricted = 1,
    GPSAuthorizationDenied = 2,
    GPSAuthorizationAuthorizedAlways = 3,
    GPSAuthorizationAuthorizedWhenInUse = 4,
    GPSAuthorizationClosed = 5,
    GPSAuthorizationUnknown = 6
};


@interface ZLocationManager : NSObject 

@property (nonatomic) CLLocation *latestLocation;   //保存最后一次的GPS定位位置
@property (nonatomic, assign) BOOL isLocationing;   //是否正在定位
@property (nonatomic, assign) BOOL keepLocationUntilSuc; //default = YES

//call back
@property (nonatomic, copy) void (^GPSSuccess)(id);
@property (nonatomic, copy) void (^GPSFail)(id);
@property (nonatomic, copy) void (^GPSAuthError)(GPSAuthorizationStatus status);
@property (nonatomic, copy) void (^ReverseGeocoding)(id);


+ (instancetype)defaultLocationManager;

//GPS状态查询
+ (GPSAuthorizationStatus)queryGPSAuthorization;
+ (BOOL)checkGPSAllowedStatus;

/**
 *  GPS的开、关；注意若是不是用 openGPSAutoClose ，定到位置后不再使用定位功能请主动关闭GPS closeGPS
 */
- (void)openGPSAutoClose;
- (void)openGPS;
- (void)closeGPS;

/**
 *  8.0 系统后才支持
 */
+ (void)openApplicationSetting;

@end
