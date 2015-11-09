//
//  DYCoreBluetooth.h
//
//
//  Created by Danny Lin on 12/12/19.
//  Copyright (c) 2012年 danny. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
// iOS code here
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>
#import <UIKit/UIKit.h>
#else
// OS X code here
#import <IOBluetooth/IOBluetooth.h>
#endif
#define CBAdvDataRSSI @"kCBAdvDataRSSI"

@interface DYCoreBluetooth : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate> {
    
    
    
}

+ (id)sharedInstance;

- (BOOL)requireBLEPermissionIfNeed;//require Bluetooth Permission Alert ,If need to return YES and Alert
- (void)startScanning;
- (void)startScanningForUUIDString:(NSString *)uuidString;
- (void)stopScanning;
- (void)connect:(CBPeripheral*)peripheral;
- (void)connectWithUUIDString:(NSString*)uuidString;
- (void)disconnect:(CBPeripheral*)peripheral;
- (void)disconnectCurrentPeripheral;
- (void)reConnect:(NSString*) strUUID;

- (CBCentralManagerState) getState;
- (BOOL)isConnectedCurrentPeripheral;

- (void)writeValue:(CBUUID *) serviceUUID characteristicUUID:(CBUUID *) characteristicUUID peripheral:(CBPeripheral *)p data:(NSData *)data;
- (void)writeValueWithString:(CBUUID *) serviceUUID characteristicUUID:(CBUUID *) characteristicUUID peripheral:(CBPeripheral *)p data:(NSString *)strData;
//
- (void)setWriteUARTEnvironmentServiceUUID:(int)serviceUUID characteristicUUID:(int)characteristicUUID;
- (void)writeUART:(NSString *)stringData;
- (void)writeUARTWithDoubleHexString:(NSString *)stringData;
- (void)writeUARTWithBin:(NSData *)data peripheral:(CBPeripheral *)p;
//
- (void)registerNotification:(CBUUID *) serviceUUID characteristicUUID:(CBUUID *)characteristicUUID peripheral:(CBPeripheral *)p on:(BOOL)on;
- (void)registerNotificationWithIntUUID:(UInt16) serviceUUID characteristicUUID:(UInt16)characteristicUUID peripheral:(CBPeripheral *)p on:(BOOL)on;

@property (strong, nonatomic) id                                delegate;
@property (strong, nonatomic) CBPeripheral                      *connectedPeripheral;
@property BOOL isNeedScanningTimeout;
//@property (atomic, copy) DYDidUpdateValueBlockType didUpdateValueCallback;
//Tools
-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2;

@end

@protocol DYCoreBluetoohDelegate <NSObject>

@required
/*! didUpdateValueWithPeripheral 更新通知
 * @param peripheral 發發的peripheral物件
 * @param cbUUID 觸發的Characteristics UUID
 * @param stringData Hex轉成String顯示
 * @param binaryData Bin RawData
 * @returns void
 */
- (void)didUpdateValueWithPeripheral:(CBPeripheral*)peripheral Characteristics:(CBUUID*)cbUUID stringData:(NSString*)stringData binaryData:(NSData*)binaryData error:(NSError *)error;
- (void)didUpdateState:(BOOL)isAvailable message:(NSString*)msg status:(CBCentralManagerState)status;
- (void)didDiscoverPeripheral:(NSMutableArray*)foundPeripherals;


/*! did connected
 * \param peripheral peripheral
 * \param error error code
 * \returns void
 */
- (void)didConnected:(CBPeripheral *)peripheral error:(NSError *)error;
- (void)didDisconnected:(CBPeripheral *)peripheral error:(NSError *)error;
- (void)didFailToConnect:(CBPeripheral *)peripheral error:(NSError *)error;
//
@optional
- (void)didDiscoverPeripheralNow:(CBPeripheral *)foundPeripheral advertisementData:(NSDictionary*) foundAdvertisementData;
//
- (void)didUpdateValue:(CBUUID*)cbUUID stringData:(NSString*)stringData binaryData:(NSData*)binaryData error:(NSError *)error;
- (void)didRetrievePeripheral:(CBPeripheral *)peripheral;
- (void)didRetrieveConnected:(CBPeripheral*)peripheral;
- (void)didUpdateRSSI:(NSNumber *)RSSI peripheral:(CBPeripheral *)peripheral error:(NSError *)error;

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error;
- (void)didDiscoverPeripheral:(NSMutableArray*)foundPeripherals advertisementData:(NSMutableArray*) foundAdvertisementData;
//
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral;
- (void)peripheralDidInvalidateServices:(CBPeripheral *)peripheral;
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

@end
