

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
// iOS code here
    #import <CoreBluetooth/CoreBluetooth.h>
    #import <CoreBluetooth/CBService.h>
    #import <UIKit/UIKit.h>
#else
// OS X code here
    #if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_9
        #import <CoreBluetooth/CoreBluetooth.h>
    #else
        #import <IOBluetooth/IOBluetooth.h>
        #import <CoreBluetooth/CBService.h>
    #endif

#endif

#if TARGET_OS_OSX
    typedef NS_ENUM(NSInteger, DYCBCentralManagerState) {
        DYCBCentralManagerStateUnknown = CBCentralManagerStateUnknown,
        DYCBCentralManagerStateResetting = CBCentralManagerStateResetting,
        DYCBCentralManagerStateUnsupported = CBCentralManagerStateUnsupported,
        DYCBCentralManagerStateUnauthorized = CBCentralManagerStateUnauthorized,
        DYCBCentralManagerStatePoweredOff = CBCentralManagerStatePoweredOff,
        DYCBCentralManagerStatePoweredOn = CBCentralManagerStatePoweredOn,
    };
#else
    #if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
        typedef NS_ENUM(NSInteger, DYCBCentralManagerState) {
            DYCBCentralManagerStateUnknown = CBManagerStateUnknown,
            DYCBCentralManagerStateResetting = CBManagerStateResetting,
            DYCBCentralManagerStateUnsupported = CBManagerStateUnsupported,
            DYCBCentralManagerStateUnauthorized = CBManagerStateUnauthorized,
            DYCBCentralManagerStatePoweredOff = CBManagerStatePoweredOff,
            DYCBCentralManagerStatePoweredOn = CBManagerStatePoweredOn,
        };
    #else
        typedef NS_ENUM(NSInteger, DYCBCentralManagerState) {
            DYCBCentralManagerStateUnknown = CBCentralManagerStateUnknown,
            DYCBCentralManagerStateResetting = CBCentralManagerStateResetting,
            DYCBCentralManagerStateUnsupported = CBCentralManagerStateUnsupported,
            DYCBCentralManagerStateUnauthorized = CBCentralManagerStateUnauthorized,
            DYCBCentralManagerStatePoweredOff = CBCentralManagerStatePoweredOff,
            DYCBCentralManagerStatePoweredOn = CBCentralManagerStatePoweredOn,
        };
    #endif
#endif

//#define DYCOREBLUETOOTH_DEBUG

#ifdef DYCOREBLUETOOTH_DEBUG
#define DYCBDEBUG(...) NSLog(@"%s==%@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#define DYCBDEBUGLN(...) NSLog(@"%s==%@\r\n", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
#define DYCBDEBUG(...) do { } while (0)
#define DYCBDEBUGLN(...) do { } while (0)
#endif
