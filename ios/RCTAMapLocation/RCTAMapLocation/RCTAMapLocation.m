
#define DefaultLocationTimeout 10
#define DefaultReGeocodeTimeout 5

#import "RCTAMapLocation.h"
#import <React/RCTUtils.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>

@interface RCTAMapLocation() <AMapLocationManagerDelegate>

@property (nonatomic, strong) AMapLocationManager *locationManager;

@property (nonatomic, strong) AMapLocationManager *locationManagerOnce;

@property (nonatomic, copy) AMapLocatingCompletionBlock completionBlock;

@end

@implementation RCTAMapLocation

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE(AMapLocation);


#pragma mark - Lifecycle
- (void)dealloc {
    self.locationManager = nil;
    self.locationManagerOnce = nil;
}

#pragma mark - Setter & Getter
- (AMapLocationManager *)locationManager {
    __weak __typeof__(self) weakSelf = self;
    if (!_locationManager) {
        _locationManager = [[AMapLocationManager alloc] init];
        _locationManager.delegate = weakSelf;
    }
    return _locationManager;
}

- (AMapLocationManager *)locationManagerOnce {
    if (!_locationManagerOnce) {
        _locationManagerOnce = [[AMapLocationManager alloc] init];
//        _locationManagerOnce.delegate = self;
    }
    return _locationManagerOnce;
}

- (void)setOptions:(NSDictionary *)options locationManager:(AMapLocationManager *)locationManager
{
    CLLocationAccuracy locationMode = kCLLocationAccuracyHundredMeters;
    CLLocationDistance distanceFilter = 100;
    BOOL locatingWithReGeocode = NO;
    BOOL pausesLocationUpdatesAutomatically = YES;
    BOOL allowsBackgroundLocationUpdates = NO;
    int locationTimeout = DefaultLocationTimeout;
    int reGeocodeTimeout = DefaultReGeocodeTimeout;
    
    if(options != nil) {
        
        NSArray *keys = [options allKeys];
        
        if ([keys containsObject:@"locatingWithReGeocode"]) {
            locatingWithReGeocode = [[options objectForKey:@"locatingWithReGeocode"] boolValue];
        }
        
        if ([keys containsObject:@"distanceFilter"]) {
            distanceFilter = [[options objectForKey:@"distanceFilter"] doubleValue];
        }
        
        if([keys containsObject:@"locationMode"]) {
            locationMode = [[options objectForKey:@"locationMode"] doubleValue];
        }
        
        if([keys containsObject:@"pausesLocationUpdatesAutomatically"]) {
            pausesLocationUpdatesAutomatically = [[options objectForKey:@"pausesLocationUpdatesAutomatically"] boolValue];
        }
        
        if([keys containsObject:@"allowsBackgroundLocationUpdates"]) {
            allowsBackgroundLocationUpdates = [[options objectForKey:@"allowsBackgroundLocationUpdates"] boolValue];
        }
        
        if([keys containsObject:@"locationTimeout"]) {
            locationTimeout = [[options objectForKey:@"locationTimeout"] intValue];
        }
        
        if([keys containsObject:@"reGeocodeTimeout"]) {
            reGeocodeTimeout = [[options objectForKey:@"reGeocodeTimeout"] intValue];
        }
    }
    
    [locationManager setLocatingWithReGeocode:locatingWithReGeocode];
    
    //设定定位的最小距离
    [locationManager setDistanceFilter:distanceFilter];
    
    //设置期望定位精度
    [locationManager setDesiredAccuracy:locationMode];
    
    //设置是否允许系统暂停定位
    [locationManager setPausesLocationUpdatesAutomatically:pausesLocationUpdatesAutomatically];
    
    //设置是否允许在后台定位
    [locationManager setAllowsBackgroundLocationUpdates:allowsBackgroundLocationUpdates];
    
    //设置定位超时时间
    [locationManager setLocationTimeout:locationTimeout];
    
    //设置逆地理超时时间
    [locationManager setReGeocodeTimeout:reGeocodeTimeout];

}

RCT_EXPORT_METHOD(getReGeocode:(NSDictionary *)option)
{
    [self setOptions:option locationManager:self.locationManagerOnce];
    //进行单次带逆地理定位请求
    [self.locationManagerOnce requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        NSDictionary *resultDic;
        if (error)
        {
            resultDic = [self setErrorResult:error];
        }
        else {
            resultDic = [self setSuccessResult:location regeocode:regeocode];
        }
        [self.bridge.eventDispatcher sendAppEventWithName:@"amap.location.onLocationResult.once"
                                                     body:resultDic];
    }];
}

RCT_EXPORT_METHOD(getLocation)
{
    //进行单次定位请求
    [self.locationManagerOnce requestLocationWithReGeocode:NO completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        NSDictionary *resultDic;
        if (error)
        {
            resultDic = [self setErrorResult:error];
        }
        else {
            resultDic = [self setSuccessResult:location regeocode:regeocode];
        }
        [self.bridge.eventDispatcher sendAppEventWithName:@"amap.location.onLocationResult.once"
                                                     body:resultDic];
    }];
}

RCT_EXPORT_METHOD(startUpdatingLocation:(NSDictionary *)option)
{
    [self setOptions:option locationManager:self.locationManager];
    //开始进行连续定位
    [self.locationManager startUpdatingLocation];
}

RCT_EXPORT_METHOD(stopUpdatingLocation)
{
    //停止连续定位
    [self.locationManager stopUpdatingLocation];
}

- (NSDictionary*)setErrorResult:(NSError *)error
{
    NSDictionary *resultDic;
    
    resultDic = @{
                  @"error": @{
                          @"code": @(error.code),
                          @"localizedDescription": error.localizedDescription
                          }
                  };
    return resultDic;
}

- (NSDictionary*)setSuccessResult:(CLLocation *)location regeocode:(AMapLocationReGeocode *)regeocode
{
    NSDictionary *resultDic;
    
    //得到定位信息
    if (location)
    {
        if(regeocode) {
            resultDic = @{
                          @"horizontalAccuracy": @(location.horizontalAccuracy),
                          @"verticalAccuracy": @(location.verticalAccuracy),
                          @"coordinate": @{
                                  @"latitude": @(location.coordinate.latitude),
                                  @"longitude": @(location.coordinate.longitude),
                                  },
                          @"formattedAddress": regeocode.formattedAddress?:[NSNull null],
                          @"country": regeocode.country?:[NSNull null],
                          @"province": regeocode.province?:[NSNull null],
                          @"city": regeocode.city?:[NSNull null],
                          @"district": regeocode.district?:[NSNull null],
                          @"citycode": regeocode.citycode?:[NSNull null],
                          @"adcode": regeocode.adcode?:[NSNull null],
                          @"street": regeocode.street?:[NSNull null],
                          @"number": regeocode.number?:[NSNull null],
                          @"POIName": regeocode.POIName?:[NSNull null],
                          @"AOIName": regeocode.AOIName?:[NSNull null]
                          };
        }
        else {
            resultDic = @{
                          @"horizontalAccuracy": @(location.horizontalAccuracy),
                          @"verticalAccuracy": @(location.verticalAccuracy),
                          @"coordinate": @{
                                  @"latitude": @(location.coordinate.latitude),
                                  @"longitude": @(location.coordinate.longitude),
                                  }
                          };
            
        }
    }
    else {
        resultDic = @{
                      @"error": @{
                              @"code": @(-1),
                              @"localizedDescription": @"定位结果不存在"
                              }
                      };
    }
    return resultDic;
}

#pragma mark - AMapLocationManager Delegate

- (void)amapLocationManager:(AMapLocationManager *)manager didFailWithError:(NSError *)error
{
//    NSLog(@"%s, amapLocationManager = %@, error = %@", __func__, [manager class], error);
    NSDictionary *resultDic;
    
    resultDic = [self setErrorResult:error];
    
    [self.bridge.eventDispatcher sendAppEventWithName:@"amap.location.onLocationResult"
                                                 body:resultDic];
}

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)regeocode
{
//    NSLog(@"location:{lat:%f; lon:%f; accuracy:%f; regeocode:%@}", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy, regeocode.formattedAddress);
    
    NSDictionary *resultDic;
    
    resultDic = [self setSuccessResult:location regeocode:regeocode];
    
    [self.bridge.eventDispatcher sendAppEventWithName:@"amap.location.onLocationResult"
                                                 body:resultDic];

}


- (NSDictionary *)constantsToExport
{
    return @{
             @"locationMode": @{
                     @"bestForNavigation": @(kCLLocationAccuracyBestForNavigation),
                     @"best": @(kCLLocationAccuracyBest),
                     @"nearestTenMeters": @(kCLLocationAccuracyNearestTenMeters),
                     @"hundredMeters": @(kCLLocationAccuracyHundredMeters),
                     @"kilometer":  @(kCLLocationAccuracyKilometer),
                     @"threeKilometers": @(kCLLocationAccuracyThreeKilometers)
                     }
             };
}


@end
