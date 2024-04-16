#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(ReactNativePasskeys, NSObject)

RCT_EXTERN_METHOD(create:(NSDictionary *)request
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject);

RCT_EXTERN_METHOD(get:(NSDictionary *)request
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject);

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end


