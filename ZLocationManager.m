//
//  ZLocationManager.m
//  MultiFunctions
//
//  Created by apple on 16/4/15.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "ZLocationManager.h"

static const CLLocationAccuracy kINTUHorizontalAccuracyThresholdCity =         5000.0;  // in meters
//static const CLLocationAccuracy kINTUHorizontalAccuracyThresholdNeighborhood = 1000.0;  // in meters
//static const CLLocationAccuracy kINTUHorizontalAccuracyThresholdBlock =         100.0;  // in meters
//static const CLLocationAccuracy kINTUHorizontalAccuracyThresholdHouse =          15.0;  // in meters
//static const CLLocationAccuracy kINTUHorizontalAccuracyThresholdRoom =            5.0;  // in meters
//
//static const NSTimeInterval kINTUUpdateTimeStaleThresholdCity =             600.0;  // in seconds
//static const NSTimeInterval kINTUUpdateTimeStaleThresholdNeighborhood =     300.0;  // in seconds
//static const NSTimeInterval kINTUUpdateTimeStaleThresholdBlock =             60.0;  // in seconds
//static const NSTimeInterval kINTUUpdateTimeStaleThresholdHouse =             15.0;  // in seconds
//static const NSTimeInterval kINTUUpdateTimeStaleThresholdRoom =               5.0;  // in seconds


@interface ZLocationManager () <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL autoClose;
@property (nonatomic) CLGeocoder *geoCoder;

+ (instancetype)shareLocationManager;

@end


@implementation ZLocationManager

+ (instancetype)shareLocationManager {

    static ZLocationManager *shareInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shareInstance = [[ZLocationManager alloc] init];
    });
    
    return shareInstance;
}

+ (instancetype)defaultLocationManager {

    return [ZLocationManager new];
}

- (id)init {

    self = [super init];
    if (self) {
        
        [self initLocationManager];
        self.keepLocationUntilSuc = YES;
        
        [self cleanDefaultCategories];
    }
    
    return self;
}

- (void)dealloc {

    [self clean];
}

- (void)clean {

    if (self.isLocationing) {
        [self closeGPS];
    }
    
    if (self.GPSSuccess) {
        self.GPSSuccess = nil;
    }
    
    if (self.GPSFail) {
        self.GPSFail = nil;
    }
    
    if (self.GPSAuthError) {
        self.GPSAuthError = nil;
    }
    
    if (self.ReverseGeocoding) {
        self.ReverseGeocoding = nil;
    }
    
    self.locationManager = nil;
    
    self.geoCoder = nil;
    
}

- (void)initLocationManager {

    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kINTUHorizontalAccuracyThresholdCity;
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
}

- (void)cleanDefaultCategories {

    self.autoClose = NO;
    self.isLocationing = NO;
}

- (void)openClose {

    self.autoClose = YES;
}

#pragma mark - Private Methods
- (void)startLocation {

    if ([ZLocationManager checkGPSAllowedStatus]) {
        [self closeGPS];
        [_locationManager startUpdatingLocation];
        self.isLocationing = YES;
    }
    else {
        
        if (self.GPSAuthError) {
            self.GPSAuthError([ZLocationManager queryGPSAuthorization]);
        }
    }
}

- (void)reverseGeocoding {

    if (!self.geoCoder) {
        self.geoCoder = [CLGeocoder new];
    }
    
    __weak typeof(self) weakSelf = self;
    [self.geoCoder reverseGeocodeLocation:self.latestLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error) {
            if (strongSelf.GPSFail) {
                strongSelf.GPSFail(error);
            }
        }
        else {
        
            
            if ([placemarks count] != 0) {
                
                CLPlacemark *placeMark = [placemarks lastObject];
                
                NSString *city = [placeMark locality];

                if (!city) {
                    //四大直辖市的城市信息无法通过locality获得，只能通过获取省份的方法来获得（如果city为空，则可知为直辖市）
                    city = placeMark.administrativeArea;
                }
                
                strongSelf.ReverseGeocoding(city);
            }
            else {
            
                NSError *cusError = [NSError errorWithDomain:@"127.0.0.1" code:100001 userInfo:@{ @"CustomErrorInfo" : @"异常"}];
                strongSelf.GPSFail(cusError);
            }
            
        }
        
    }];
}

#pragma mark - Public Methods
+ (GPSAuthorizationStatus)queryGPSAuthorization {

    if (![CLLocationManager locationServicesEnabled]) {
        return GPSAuthorizationClosed;
    }

    CLAuthorizationStatus stutas = [CLLocationManager authorizationStatus];
    
    if (stutas == kCLAuthorizationStatusNotDetermined) {
        
        return GPSAuthorizationNotDetermined;
    }
    else if (stutas == kCLAuthorizationStatusRestricted) {
    
        return GPSAuthorizationRestricted;
    }
    else if (stutas == kCLAuthorizationStatusDenied) {
    
        return GPSAuthorizationDenied;
    }
    else if (stutas == kCLAuthorizationStatusAuthorizedAlways) {
    
        return GPSAuthorizationAuthorizedAlways;
    }
    else if (stutas == kCLAuthorizationStatusAuthorizedWhenInUse) {
    
        return GPSAuthorizationAuthorizedWhenInUse;
    }
    else {
        
        return GPSAuthorizationUnknown;
    }
    
}

+ (BOOL)checkGPSAllowedStatus {

    GPSAuthorizationStatus status = [ZLocationManager queryGPSAuthorization];
    
    if ((status != GPSAuthorizationClosed) && (status != GPSAuthorizationDenied) && (status != GPSAuthorizationRestricted) && (status != GPSAuthorizationUnknown)) {
        
        return YES;
    }
    else {
        return NO;
    }
}

- (void)openGPSAutoClose {
    //取到数据或者定位出错即可关闭GPS
    [self openClose];

    [self startLocation];
}

- (void)openGPS {
    
    [self cleanDefaultCategories];
    
    [self startLocation];
}

- (void)closeGPS {
    
    [_locationManager stopUpdatingLocation];
    [self cleanDefaultCategories];
}

+ (void)openApplicationSetting {

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: UIApplicationOpenSettingsURLString]];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
//    NSLog(@"........%s", __func__);
    if ([locations count] != 0) {
        
        CLLocation * currentLocation = [locations lastObject];
        CLLocation * location = [[CLLocation alloc] initWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
        self.latestLocation = location;
        
        if (self.autoClose) {
            [self closeGPS];
        }
        
        if (self.GPSSuccess) {
            
            self.GPSSuccess(location);
        }
        
        if (self.ReverseGeocoding) {
            
            [self reverseGeocoding];
        }
        
    }
    else {
    
        //定位出错
        NSLog(@"没有拿到GPS回调数据");
        if (self.autoClose && !self.keepLocationUntilSuc) {
            [self closeGPS];
        }
        
        self.GPSAuthError(GPSAuthorizationUnknown);
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    if (self.autoClose && !self.keepLocationUntilSuc) {
        [self closeGPS];
    }
    
    if (error) {
        
        BOOL shouldQuit = NO;
        if ([error domain] == kCLErrorDomain) {
            
            // We handle CoreLocation-related errors here
            
            if ([ZLocationManager queryGPSAuthorization] == GPSAuthorizationClosed) {
                if (self.GPSAuthError) {
                    self.GPSAuthError(GPSAuthorizationClosed);
                }
                shouldQuit = YES;
            }
            else if ([error code] == kCLErrorDenied) {
            
                if (self.GPSAuthError) {
                    self.GPSAuthError(GPSAuthorizationDenied);
                }
                shouldQuit = YES;
            }
            
            if (!shouldQuit) {
                if (self.GPSFail) {
                    self.GPSFail(error);
                }
            }
            
        }
        else {
            if (self.GPSFail) {
                self.GPSFail(error);
            }
        }

    }
    else {
    
        NSLog(@"GPS错误回调异常");
        self.GPSAuthError(GPSAuthorizationUnknown);
    }
    
}



@end
