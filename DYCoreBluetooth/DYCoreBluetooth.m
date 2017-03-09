//
//  DYCoreBluetooth.m
//
//
//  Created by Danny Lin on 12/12/19.
//  Copyright (c) 2012年 danny. All rights reserved.
//

#import "DYCoreBluetooth.h"
#import "DYSystem.h"
//
#define kSCAN_TIMEOUT 3.0f                  // Timeout value for scanning
#define kRECONNECT_TIMEOUT 5.0f              // Timeout value for scanning

@interface DYCoreBluetooth()

@property (strong, nonatomic) NSMutableArray                    *foundPeripherals;
@property (strong, nonatomic) CBCentralManager                  *CM;
@property (strong, nonatomic) NSMutableArray                    *foundAdvertisementData;

@end

@implementation DYCoreBluetooth
{
    CBPeripheral *_connectionTempPeripheral;
    NSTimer *_scanTimer;
    NSTimer *_reConnectTimer;
    int _writeUartServiceUUID;
    int _writeUartCharacteristicUUID;
    CBUUID *_writeUartServiceUUID128;
    CBUUID *_writeUartCharacteristicUUID128;
    id delegate;
    CBCentralManager *_requireBLEPermission;
    BOOL    _isReConnectTimeout;
    
}
//
@synthesize delegate;
@synthesize CM;
@synthesize connectedPeripheral;
@synthesize isNeedScanningTimeout;
//
//@synthesize scanTimer;


#pragma mark - init

+ (id)sharedInstance {
    static DYCoreBluetooth *this = nil;
    static dispatch_once_t p;
    dispatch_once(&p, ^{
        this = [[self alloc] init];
    });
    return this;
}

- (id)init {
    self = [super init];
    if (self) {
        CM = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        
        _foundPeripherals = [[NSMutableArray alloc] init];
        _foundAdvertisementData = [[NSMutableArray alloc] init];
        _writeUartServiceUUID=SERIAL_UART_TX_SERVICE_UUID;
        _writeUartCharacteristicUUID=SERIAL_UART_TX_CHARACTERISTIC;
        _writeUartServiceUUID128 = nil;
        _writeUartCharacteristicUUID128 = nil;
        isNeedScanningTimeout = NO;
    }
    return self;
}

- (BOOL)requireBLEPermissionIfNeed {
    if (CM.state == CBCentralManagerStatePoweredOn) {
        return NO;
    }
    _requireBLEPermission = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    return YES;
}

#pragma mark - Connection

- (void)connect:(CBPeripheral*)peripheral {
    _isReConnectTimeout = NO;
#if MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_9 || __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
    
    if ([peripheral state] == CBPeripheralStateDisconnected) {
        [CM connectPeripheral:peripheral options:nil];
        connectedPeripheral=peripheral;
    }
    
#else
    if (![peripheral isConnected]) {
        [CM connectPeripheral:peripheral options:nil];
        connectedPeripheral=peripheral;
    }
#endif
    
}

- (void)connectWithUUIDString:(NSString*)uuidString {
    _isReConnectTimeout = NO;
    [self reConnect:uuidString];
}


- (void)disconnect:(CBPeripheral*)peripheral {
    [_reConnectTimer invalidate];
    if (peripheral!=NULL){
        DYCBDEBUG(@"disconnect by %@",peripheral.name);
        [CM cancelPeripheralConnection:peripheral];
    }
}
- (void)disconnectCurrentPeripheral {
    if (connectedPeripheral!=NULL)
    {
        DYCBDEBUG(@"disconnect by %@",connectedPeripheral.name);
        [CM cancelPeripheralConnection:connectedPeripheral];
    }
}


- (void)reConnect:(NSString*) strUUID {
    _isReConnectTimeout = NO;
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_9 || __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
    NSUUID *uuid = [[NSUUID UUID] initWithUUIDString:strUUID];
    NSArray *peripheralArray = [CM retrievePeripheralsWithIdentifiers:[NSArray arrayWithObject:uuid]];
    
    if (peripheralArray.count>0) {
        DYCBDEBUG(@"reConnect by %@",[peripheralArray objectAtIndex:0]);
        [self connect:[peripheralArray objectAtIndex:0]];
    }else {
        DYCBDEBUG(@"reConnect fail by");
    }
    
#else
    CFUUIDRef uuid = CFUUIDCreateFromString(nil, (CFStringRef) strUUID);
    [CM retrievePeripherals:[NSArray arrayWithObject:(__bridge id)(uuid) ]];
#endif
    [_reConnectTimer invalidate];
    _reConnectTimer = [NSTimer scheduledTimerWithTimeInterval:kRECONNECT_TIMEOUT target:self selector:@selector(reConnectTimeout:) userInfo:nil repeats:NO];
    DYCBDEBUG(@"reConnect timer started ,Interval by %zd",kRECONNECT_TIMEOUT);
}

- (void)reConnectWithStringUUIDArray:(NSArray*) uuidStringArray {
    _isReConnectTimeout = NO;
    NSMutableArray *strCFUUUIDArray=[NSMutableArray array];
    for (NSString *deviceUUIDString in uuidStringArray)
    {
        
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_9 || __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
        NSUUID *uuid = [[NSUUID UUID] initWithUUIDString:deviceUUIDString];
        [strCFUUUIDArray arrayByAddingObject:uuid];
        [CM retrievePeripheralsWithIdentifiers:[NSArray arrayWithObject:uuid]];
#else
        CFUUIDRef uuid = CFUUIDCreateFromString(NULL, (CFStringRef)(deviceUUIDString));
        [strCFUUUIDArray arrayByAddingObject:(__bridge id)(uuid)];
        [CM retrievePeripherals:[NSArray arrayWithObject:(__bridge id)(uuid) ]];
        CFRelease(uuid);
#endif
    }
    
    DYCBDEBUG(@"reConnectWithStringUUIDArray %lu",(unsigned long)uuidStringArray.count);
    _reConnectTimer = [NSTimer scheduledTimerWithTimeInterval:kRECONNECT_TIMEOUT target:self selector:@selector(reConnectTimeout:) userInfo:nil repeats:NO];
}

- (void)reConnectTimeout:(NSTimer*)timer {
    DYCBDEBUG(@"reConnectTimeout");
    _isReConnectTimeout = YES;
    _reConnectTimer=timer;
    [self disconnect:connectedPeripheral];
}


- (DYCBCentralManagerState)getState {
    return (DYCBCentralManagerState)CM.state;
}

- (BOOL)isConnectedCurrentPeripheral {
    if (connectedPeripheral.state == CBPeripheralStateConnected) {
        return YES;
    }
    return NO;
}

#pragma mark scanning and stop
- (void)startScanning {
    [self startScanningForUUIDString:nil];
}

- (void)startScanningForUUIDString:(NSString *)uuidString {
    NSDictionary *options =@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO };
    _foundPeripherals = [NSMutableArray array];
    _foundAdvertisementData = [NSMutableArray array];
    if (uuidString==nil){
        [CM scanForPeripheralsWithServices:nil options:options];
    }else{
        NSArray *uuidArray  = @[[CBUUID UUIDWithString:uuidString]];
        [CM scanForPeripheralsWithServices:uuidArray options:options];
    }
    DYCBDEBUG(@"scanning is started");
    if (!isNeedScanningTimeout) {
        _scanTimer=[NSTimer scheduledTimerWithTimeInterval:kSCAN_TIMEOUT target:self selector:@selector(scanTimeout:) userInfo:nil repeats:NO];
        DYCBDEBUG(@"scanning timmer started,Interval by  %zd",kSCAN_TIMEOUT);
    }else {
        [_scanTimer invalidate];
    }

    
    
}

- (void)stopScanning {
    if (CM!=NULL){
        [CM stopScan];
    }else{
//        DYCBDEBUG(@"CM is Null!");
    }
    [_scanTimer invalidate];
    DYCBDEBUG(@"scanning is stop");
}


- (void)scanTimeout:(NSTimer*)timer {
    DYCBDEBUG(@"scanning is timeout");
    _scanTimer=timer;
    [self stopScanning];
    if ([[self delegate] respondsToSelector:@selector(didDiscoverPeripheral:)])
    {
        [[self delegate] didDiscoverPeripheral:_foundPeripherals];
    }
    if ([[self delegate] respondsToSelector:@selector(didDiscoverPeripheral:advertisementData:)])
    {
        [[self delegate] didDiscoverPeripheral:_foundPeripherals advertisementData:_foundAdvertisementData];
    }
}


#pragma mark - Central Manager Delegate
/*
 
 */

- (void)centralManagerDidUpdateState:(CBCentralManager*)cManager {
    NSMutableString* statusMessage= [NSMutableString string];
    BOOL isAvailable=FALSE;
    switch (cManager.state) {
        case CBCentralManagerStateUnknown:
            [statusMessage appendString:@"Unknown"];
            break;
        case CBCentralManagerStateUnsupported:
            [statusMessage appendString:@"Unsupported"];
            break;
        case CBCentralManagerStateUnauthorized:
            [statusMessage appendString:@"Unauthorized"];
            break;
        case CBCentralManagerStateResetting:
            [statusMessage appendString:@"Resetting"];
            break;
        case CBCentralManagerStatePoweredOff:
            [statusMessage appendString:@"PoweredOff"];
            if (connectedPeripheral!=NULL){
                [CM cancelPeripheralConnection:connectedPeripheral];
            }
            break;
        case CBCentralManagerStatePoweredOn:
            [statusMessage appendString:@"PoweredOn"];
            isAvailable=TRUE;
            break;
        default:
            [statusMessage appendString:@"Unknown"];
            break;
    }
    DYCBDEBUG(@"state string:%@",statusMessage);
    if ([[self delegate] respondsToSelector:@selector(didUpdateState:message:status:)])
    {
        [[self delegate] didUpdateState:isAvailable message:statusMessage status:(DYCBCentralManagerState)cManager.state];
    }
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSMutableString* discoverPeripheralStatus=[NSMutableString stringWithString:@"=====DiscoverPeripheral start=====\n"];
    //
    NSMutableDictionary *mAdvertisementData = [NSMutableDictionary dictionaryWithDictionary:advertisementData];
    [mAdvertisementData setValue:RSSI forKey:CBAdvDataRSSI];
    [discoverPeripheralStatus appendString:@"Peripheral Info:\n"];
    [discoverPeripheralStatus appendFormat:@"NAME: %@\n",peripheral.name];
    [discoverPeripheralStatus appendFormat:@"UUID:%@\n",peripheral.identifier.UUIDString];
    [discoverPeripheralStatus appendFormat:@"RSSI: %@\n",RSSI];
    [discoverPeripheralStatus appendFormat:@"LocalNameKey:%@\n",[mAdvertisementData objectForKey:CBAdvertisementDataLocalNameKey]];
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_9  || __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
    (peripheral.state==CBPeripheralStateConnected?[discoverPeripheralStatus appendString:@"isConnected: connected"]:[discoverPeripheralStatus appendString:@"isConnected: disconnected"]);
#else
    (peripheral.isConnected==TRUE?[discoverPeripheralStatus appendString:@"isConnected: connected"]:[discoverPeripheralStatus appendString:@"isConnected: disconnected"]);
#endif
    [discoverPeripheralStatus appendFormat:@"adverisement:%@",mAdvertisementData];
    
    //add peripheral and replace duplicate
    if (peripheral.identifier==NULL)
    {
        DYCBDEBUG(@"%@",@"pheripheral identifier is NULL\n");
        DYCBDEBUG(@"%@",discoverPeripheralStatus);
        return;
    }
    if ((!_foundPeripherals)) {
        _foundPeripherals = [[NSMutableArray alloc] initWithObjects:peripheral,nil];
        _foundAdvertisementData = [[NSMutableArray alloc] initWithObjects:mAdvertisementData,nil];
        [discoverPeripheralStatus appendFormat:@"first add UUID=%@\n",peripheral.identifier.UUIDString];
    }
    else {
        //檢查是否有重覆
        for(int i = 0; i < _foundPeripherals.count; i++) {
            CBPeripheral *p = [_foundPeripherals objectAtIndex:i];
            if(p.identifier == NULL || peripheral.identifier == NULL) {
                continue;
            }
            
            if ([self UUIDSAreEqual:p.identifier u2:peripheral.identifier]) {
                [_foundPeripherals replaceObjectAtIndex:i withObject:peripheral];
                [_foundAdvertisementData replaceObjectAtIndex:i withObject:mAdvertisementData];
                [discoverPeripheralStatus appendString:@"duplicate UUID found and updating\n"];
                return;
            }
        }
        //無重覆新增至陣列
        [_foundPeripherals addObject:peripheral];
        [_foundAdvertisementData addObject:mAdvertisementData];
        [discoverPeripheralStatus appendFormat:@"add UUID=%@\n",peripheral.identifier.UUIDString];
        //
        if ([[self delegate] respondsToSelector:@selector(didDiscoverPeripheralNow:advertisementData:)])
        {
            [[self delegate] didDiscoverPeripheralNow:[peripheral copy] advertisementData:[mAdvertisementData copy]];
        }
    }
    
    [discoverPeripheralStatus appendString:@"====DiscoverPeripheral end====\n"];
    DYCBDEBUG(@"%@",discoverPeripheralStatus);
    
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    DYCBDEBUG(@"====connected====");
    DYCBDEBUG(@"peripheral : %@\nUUID:%@\n",peripheral.name, peripheral.identifier.UUIDString);
    
    [_reConnectTimer invalidate];
    peripheral.delegate=self;
    connectedPeripheral=peripheral;
    connectedPeripheral.delegate=self;
    
    //一定要執行"discoverService"功能去尋找可用的Service
    [peripheral discoverServices:nil];
    
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    // iOS code here
    //關閉idleTimer
    [UIApplication sharedApplication].idleTimerDisabled=YES;
#endif
    DYCBDEBUG(@"================");
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    DYCBDEBUG(@"fail to connect\n");
    
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    //開啟idleTimer
    [UIApplication sharedApplication].idleTimerDisabled=NO;
#endif
    [_reConnectTimer invalidate];
    if ([[self delegate] respondsToSelector:@selector(didFailToConnect:error:)])
    {
        [delegate didFailToConnect:peripheral error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    DYCBDEBUG(@"disconnect:%@\n",peripheral.name);
    //if (!(peripheral.state == CBPeripheralStateConnected)) {
    if (_isReConnectTimeout) {
        //連線中或是已斷線的話都將通知傳至FailToConnect，讓重新連線Timeout能夠轉到這
        _isReConnectTimeout = NO;
        [self centralManager:central didFailToConnectPeripheral:peripheral error:error];
        return;
    }
    if ([[self delegate] respondsToSelector:@selector(didDisconnected:error:)])
    {
        [delegate didDisconnected:peripheral error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    
    if (peripherals.count>0){
        _connectionTempPeripheral=[peripherals objectAtIndex:0];
        [CM connectPeripheral:_connectionTempPeripheral options:nil];
        DYCBDEBUG(@"====reconnect====");
        DYCBDEBUG(@"name:%@\n",_connectionTempPeripheral.name);
        DYCBDEBUG(@"UUID:%@\n",_connectionTempPeripheral.identifier.UUIDString);
        connectedPeripheral=_connectionTempPeripheral;
    }
    if ([[self delegate] respondsToSelector:@selector(didRetrieveConnected:)])
    {
        [delegate didRetrieveConnected:connectedPeripheral];
    }
}
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    
    if (peripherals.count>0){
        connectedPeripheral=[peripherals objectAtIndex:0];
        [CM connectPeripheral:connectedPeripheral options:nil];
        DYCBDEBUG(@"Reconnect Device Name\n%@",connectedPeripheral.name);
        DYCBDEBUG(@"UUID %@",connectedPeripheral.identifier.UUIDString);
        
        if ([[self delegate] respondsToSelector:@selector(didRetrievePeripheral:)])
        {
            [delegate didRetrievePeripheral:connectedPeripheral];
        }
    }
}

/*
 [centralManager scanForPeripheralsWithServices:nil options:nil];
 發現裝置後的delegate
 */
#pragma mark Peripheral updated
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
    if ([[self delegate] respondsToSelector:@selector(peripheralDidUpdateName:)])
    {
        [delegate peripheralDidUpdateName:peripheral];
    }
    DYCBDEBUG(@"update peripheral name:%@ \n%@\n",peripheral.identifier.UUIDString ,peripheral.name);
}

- (void)peripheralDidInvalidateServices:(CBPeripheral *)peripheral {
    if ([[self delegate] respondsToSelector:@selector(peripheralDidInvalidateServices:)])
    {
        [delegate peripheralDidInvalidateServices:peripheral];
    }
}


#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0) || TARGET_OS_OSX
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error {
    if ([[self delegate] respondsToSelector:@selector(didUpdateRSSI:peripheral:error:)])
    {
        [delegate didUpdateRSSI:RSSI peripheral:peripheral error:error];
    }
    DYCBDEBUG(@"didUpdateRSSI(>iOS8):%@ \n%@\n",peripheral.identifier.UUIDString ,RSSI);
}

#else
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    if ([[self delegate] respondsToSelector:@selector(didUpdateRSSI:peripheral:error:)])
    {
        [delegate didUpdateRSSI:peripheral.RSSI peripheral:peripheral error:error];
    }
    DYCBDEBUG(@"didUpdateRSSI:%@ \n%@\n",peripheral.identifier.UUIDString ,peripheral.RSSI);
}
#endif

#pragma mark - peripheral Delegate
/*
 *  @method didDiscoverServices
 *
 *  @param peripheral Pheripheral that got updated
 *  @error error Error message if something went wrong
 *
 *  @discussion didDiscoverServices is called when CoreBluetooth has discovered services on a
 *  peripheral after the discoverServices routine has been called on the peripheral
 *  這裡已經取得已有的Service數量及內容，但還是會pass至discoverCharacteristics
 */

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    if( peripheral.identifier == NULL  ) return;
    
    if (!error) {
        //DYCBDEBUG(@"Services of peripheral with UUID : %@ found\n",CFUUIDCreateString(NULL,peripheral.UUID));
        //didDiscoverServices->for loop discoverCharacteristics
        DYCBDEBUG(@"+=%@\n",peripheral.name);
        DYCBDEBUG(@" +== %zd of service for UUID %@ \n",peripheral.services.count,peripheral.identifier.UUIDString);
        [self getAllCharacteristicsFromPeripheral:peripheral];
        
    }else {
        DYCBDEBUG(@"Service discovery was unsuccessfull\n");
    }
    
}

- (void)getAllCharacteristicsFromPeripheral:(CBPeripheral *)p {
    for (CBService *service in p.services){
        DYCBDEBUG(@"  +==Characteristics UUID: %@\n", service.UUID.UUIDString);
        //利用尋找到的service再去執行discoverCharacteristics
        [p discoverCharacteristics:nil forService:service];
    }
}
/*
 from didDiscoverService for loop.
 */
- (void)printCharactersticInfo:(CBCharacteristic *)characteristic {
    DYCBDEBUG(@"===characterstic info====");
    DYCBDEBUG(@"SERVICE UUID:%@",characteristic.service.UUID);
    DYCBDEBUG(@"Characteristic UUID:%@",characteristic.UUID);    
    DYCBDEBUG(@"Properties:%03lx",(unsigned long)characteristic.properties);
    [self printProperties:characteristic.properties];
}

- (void)printProperties:(CBCharacteristicProperties)characteristicProperties {
    DYCBDEBUG(@"====Properties====");
    if (characteristicProperties & CBCharacteristicPropertyBroadcast ) {
        DYCBDEBUG(@"CBCharacteristicPropertyBroadcast");
    }
    if (characteristicProperties & CBCharacteristicPropertyRead ) {
        DYCBDEBUG(@"CBCharacteristicPropertyRead");
    }
    if (characteristicProperties & CBCharacteristicPropertyWriteWithoutResponse ) {
        DYCBDEBUG(@"CBCharacteristicPropertyWriteWithoutResponse");
    }
    if (characteristicProperties & CBCharacteristicPropertyWrite ) {
        DYCBDEBUG(@"CBCharacteristicPropertyWrite");
    }
    if (characteristicProperties & CBCharacteristicPropertyNotify ) {
        DYCBDEBUG(@"CBCharacteristicPropertyNotify");
    }
    if (characteristicProperties & CBCharacteristicPropertyIndicate ) {
        DYCBDEBUG(@"CBCharacteristicPropertyIndicate");
    }
    if (characteristicProperties & CBCharacteristicPropertyAuthenticatedSignedWrites ) {
        DYCBDEBUG(@"CBCharacteristicPropertyAuthenticatedSignedWrites");
    }
    if (characteristicProperties & CBCharacteristicPropertyExtendedProperties ) {
        DYCBDEBUG(@"CBCharacteristicPropertyExtendedProperties");
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_6_0 || MAC_OS_X_VERSION_MAX_REQUIRED >= __MAC_10_9
    if (characteristicProperties & CBCharacteristicPropertyNotifyEncryptionRequired ) {
        DYCBDEBUG(@"CBCharacteristicPropertyNotifyEncryptionRequired");
    }
    if (characteristicProperties & CBCharacteristicPropertyIndicateEncryptionRequired ) {
        DYCBDEBUG(@"CBCharacteristicPropertyIndicateEncryptionRequired");
    }
#endif
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    CBService *s = [peripheral.services objectAtIndex:(peripheral.services.count - 1)];
    DYCBDEBUG(@"==== Service UUID %s ====\n",[self CBUUIDToChar:service.UUID]);
    if (!error) {
        DYCBDEBUG(@"====%lu Characteristics of service====",(unsigned long)service.characteristics.count);
        for(CBCharacteristic *c in service.characteristics){
            [self printCharactersticInfo:c];
        }
        //DYCBDEBUG(@"=== Finished set notification ===\n");
        
        if ([[self delegate] respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)])
        {
            [[self delegate] peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error];
        }
    }else {
        DYCBDEBUG(@"Characteristic discorvery unsuccessfull !\n");
        
    }
    if([self compareCBUUID:service.UUID UUID2:s.UUID]) {//利用此來確定整個流程都結束後才能設定通知
        if ([[self delegate] respondsToSelector:@selector(didConnected:error:)])
        {
            [[self delegate] didConnected:peripheral error:error];
        }else {
            DYCBDEBUG(@"delegate can't run method didConnected");
        }
        DYCBDEBUG(@"=== Finished discovering characteristics ===\n");
        //全部服務都讀取完畢時才能使用！
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ([[self delegate] respondsToSelector:@selector(didUpdateValueWithPeripheral:Characteristics:stringData:binaryData:error:)])
    {
        [[self delegate] didUpdateValueWithPeripheral:peripheral Characteristics:characteristic.UUID stringData:[self binaryAsciiDataToString:characteristic.value] binaryData:characteristic.value error:error];
    }else {
        DYCBDEBUG(@"delegate can't run method didUpdateValueWithPeripheral");
    }
    if ([[self delegate] respondsToSelector:@selector(didUpdateValue:stringData:binaryData:error:)])
    {
        [[self delegate] didUpdateValue:characteristic.UUID stringData:[self binaryAsciiDataToString:characteristic.value] binaryData:characteristic.value error:error];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ([[self delegate] respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)])
    {
        [[self delegate] peripheral:peripheral didWriteValueForCharacteristic:characteristic error:error];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        DYCBDEBUG(@"Error in setting notification state for characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",characteristic.UUID,characteristic.service.UUID,
                           peripheral.identifier.UUIDString);
        
        DYCBDEBUG(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    }
    if ([[self delegate] respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)])
    {
        [[self delegate] peripheral:peripheral didUpdateNotificationStateForCharacteristic:characteristic error:error];
    }
    DYCBDEBUG(@"didUpdateNotificationStateForCharacteristic = %@ ",characteristic.UUID);
}




#pragma mark - Private Function

- (NSString*)binaryAsciiDataToString:(NSData*)data {
    
    //配合BLE最長不超過20(大部分都是16)來當做Buffer，低於長度時後面接0才會讓轉換正常
    //[00000000000]
    //
    //[12300000000]
    //char chardata[BLE_RX_BUFFER_LEN + 1];
    //memset(chardata, 0, sizeof(char)*(BLE_RX_BUFFER_LEN + 1));
    
    //[data getBytes:&chardata length:data.length];
    //DYCBDEBUG(@"len=%lu",(unsigned long)data.length);
    
    //NSString *marketPacket = [NSString stringWithCString:chardata encoding:NSASCIIStringEncoding];
    //先前使用方法會造成資料中間有hex:00時成為null而造成轉換資料不正確
    NSString *marketPacket = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    return marketPacket;
}



- (CBUUID*)intUUIDToCBUUID:(int)intUUID {
    UInt16 s = [self swap:intUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    return su;
}

//for iOS 8 and OSX 10.10 getBytes
- (UInt16)CBUUIDToIntUUID:(CBUUID *) UUID {
    char b1[16];
    [UUID.data getBytes:b1 length:16];
    return ((b1[0] << 8) | b1[1]);
}

- (int)compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2 {
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1 length:16];
    [UUID2.data getBytes:b2 length:16];
    if (memcmp(b1, b2, UUID1.data.length) == 0) {
        return 1;
    }else {
        return 0;
    }
}

- (BOOL)UUIDSAreEqual:(NSUUID *)UUID1 u2:(NSUUID *)UUID2 {
    return [UUID1.UUIDString isEqualToString:UUID2.UUIDString];
}

- (const char *)CBUUIDToChar:(CBUUID *) UUID {
    //if (!UUID) return "NULL";
    if (UUID == NULL) return "NULL"; // zach ios6 added
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}

- (NSString *)CBUUIDToString:(CBUUID *) cbuuid {
    NSData *data = cbuuid.data;
    
    if ([data length] == 2)
    {
        const unsigned char *tokenBytes = [data bytes];
        return [NSString stringWithFormat:@"%02x%02x", tokenBytes[0], tokenBytes[1]];
    }
    else if ([data length] == 16)
    {
        NSUUID* nsuuid = [[NSUUID alloc] initWithUUIDBytes:[data bytes]];
        return [nsuuid UUIDString];
    }
    
    return [cbuuid description];
}

- (CBService *)getServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p {
    
    for (CBService* s in p.services){
        if ([self compareCBUUID:s.UUID UUID2:UUID]) return s;
    }
    return nil; //Service not found on this peripheral
}


- (CBCharacteristic *)getCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service {
    
    for (CBCharacteristic* c in service.characteristics){
        if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
    }
    return nil; //Characteristic not found on this service
}

- (UInt16)swap:(UInt16)s {
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

- (NSData*)dobuleHexStringToHexData:(NSString*)string {
    Byte byteData[[string length]];
    [[string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] getBytes:&byteData length:string.length];
    //[data getBytes:&byteData length:data.length];
    NSMutableData *nsmData=[NSMutableData new];
    for (int i=0 ; i < string.length ; i= i+2)
    {
        NSString *c1=[NSString stringWithFormat:@"#%c%c",byteData[i],byteData[i+1]];
        unsigned result = 0;
        NSScanner *scanner = [NSScanner scannerWithString:c1];
        [scanner setScanLocation:1]; // bypass '#' character
        [scanner scanHexInt:&result];
        Byte b1[1]={result};
        [nsmData appendBytes:b1 length:1];
        
    }
    DYCBDEBUG(@"convHexStringToHex:%@",[nsmData description]);
    return nsmData;
}

#pragma mark Public method

- (void)writeValue:(CBUUID *) serviceUUID characteristicUUID:(CBUUID *) characteristicUUID peripheral:(CBPeripheral *)p data:(NSData *)data {
    CBService *service = [self getServiceFromUUID:serviceUUID p:p];
    if (!service) {
        DYCBDEBUG(@"Could not find service with UUID %@ on peripheral with UUID %@",serviceUUID,
                           p.identifier.UUIDString);
        return;
    }
    CBCharacteristic *characteristic = [self getCharacteristicFromUUID:characteristicUUID service:service];
    if (!characteristic) {
        DYCBDEBUG(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",characteristicUUID,serviceUUID,
                           p.identifier.UUIDString);
        return;
    }else{
        DYCBDEBUG(@"write to characteristic value:%@",characteristic.UUID);
    }
    //Marked
    if ((characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) == 0) {
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//        NSLog(@"CBCharacteristicWriteWithResponse");
    }
    else {
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
//        NSLog(@"CBCharacteristicWriteWithoutResponse");
    }
    
}

- (void)writeValueWithString:(CBUUID *) serviceUUID characteristicUUID:(CBUUID *) characteristicUUID peripheral:(CBPeripheral *)p data:(NSString *)strData {
    NSData* data = [strData dataUsingEncoding:NSUTF8StringEncoding];
    data = [data subdataWithRange:NSMakeRange(0, [data length])];
    CBService *service = [self getServiceFromUUID:serviceUUID p:p];
    if (!service) {
        DYCBDEBUG(@"Could not find service with UUID %@ on peripheral with UUID %@",serviceUUID,
                           p.identifier.UUIDString);
        return;
    }
    CBCharacteristic *characteristic = [self getCharacteristicFromUUID:characteristicUUID service:service];
    if (!characteristic) {
        DYCBDEBUG(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",characteristicUUID,serviceUUID,
                           p.identifier.UUIDString);
        return;
    }
    //Marked
    if ((characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) == 0) {
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//        NSLog(@"CBCharacteristicWriteWithResponse");
    }
    else {
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
//        NSLog(@"CBCharacteristicWriteWithoutResponse");
    }
}

#pragma mark registerNotification

- (void)registerNotification:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID peripheral:(CBPeripheral *)p on:(BOOL)on {
    
    CBService *service = [self getServiceFromUUID:serviceUUID p:p];
    if (!service) {
        if (p.identifier == NULL) return; // zach ios6 added
        DYCBDEBUG(@"Could not find service with UUID on peripheral with UUID \n");
        return;
    }
    CBCharacteristic *characteristic = [self getCharacteristicFromUUID:characteristicUUID service:service];
    if (!characteristic) {
        if (p.identifier == NULL) return; // zach ios6 added
        DYCBDEBUG(@"Could not find characteristic with UUID  on service with UUID  on peripheral with UUID\n");
        return;
    }
    
    [p setNotifyValue:on forCharacteristic:characteristic];
    DYCBDEBUG(@"registerNotification ok - service:%@ characterstic:%@",service.UUID ,characteristic.UUID);
}

- (void)registerNotificationWithIntUUID:(UInt16)serviceUUID characteristicUUID:(UInt16)characteristicUUID peripheral:(CBPeripheral *)p on:(BOOL)on {
    
    [self registerNotification:[self intUUIDToCBUUID:serviceUUID] characteristicUUID:[self intUUIDToCBUUID:characteristicUUID] peripheral:p on:(BOOL)on];
}

#pragma mark for UART Special Function

- (void)setWriteUARTEnvironmentServiceUUID:(int)serviceUUID characteristicUUID:(int)characteristicUUID
{
    _writeUartServiceUUID=serviceUUID;
    _writeUartCharacteristicUUID=characteristicUUID;
    _writeUartServiceUUID128 = nil;
    _writeUartCharacteristicUUID128 = nil;
    
}

- (void)setWriteUARTEnvironmentServiceUUID128:(CBUUID *)serviceUUID128 characteristicUUID:(CBUUID *)characteristicUUID128
{
    _writeUartServiceUUID128 = serviceUUID128;
    _writeUartCharacteristicUUID128 = characteristicUUID128;
    //
}

- (void)writeUART:(NSString *)stringData {
    
    NSData* data = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    data = [data subdataWithRange:NSMakeRange(0, [data length])];
    [self writeUARTWithBin:data peripheral:connectedPeripheral];
    DYCBDEBUG(@"write string= (%@)\n",stringData);
    
}

- (void)writeUARTWithDoubleHexString:(NSString *)stringData {
    [self writeUARTWithBin:[self dobuleHexStringToHexData:stringData] peripheral:connectedPeripheral];
    DYCBDEBUG(@"write string= (%@)\n",stringData);
    
}

- (void)writeUARTWithBin:(NSData *)data peripheral:(CBPeripheral *)p {
    
    if ((_writeUartCharacteristicUUID128 == nil) && (_writeUartServiceUUID128 ==nil)) {
        [self writeValue:[self intUUIDToCBUUID:_writeUartServiceUUID] characteristicUUID:[self intUUIDToCBUUID:_writeUartCharacteristicUUID] peripheral:p data: data];
        DYCBDEBUG(@"write bin SUUID= (%04x) CUUID=(%04x)\n",_writeUartServiceUUID,_writeUartCharacteristicUUID);
    }else {
        [self writeValue:_writeUartServiceUUID128 characteristicUUID:_writeUartCharacteristicUUID128 peripheral:p data: data];
        DYCBDEBUG(@"write bin SUUID= (%@)   CUUID=(%@)\n",[_writeUartServiceUUID128 UUIDString],[_writeUartCharacteristicUUID128 UUIDString]);
        
    }

}

#pragma mark heart rate data convert
/*
 Update UI with heart rate data received from device
 */
- (uint16_t)convertToHRMData:(NSData *)data {
    const uint8_t *reportData = [data bytes];
    uint16_t bpm = 0;
    
    if ((reportData[0] & 0x01) == 0)
    {
        /* uint8 bpm */
        bpm = reportData[1];
    }
    else
    {
        /* uint16 bpm */
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));
    }
    //DYCBDEBUG(@"bpm is %hu",bpm);
    return bpm;
}
//


#pragma mark Restoring
/****************************************************************************/
/*                              Settings                                    */
/****************************************************************************/
/* Reload from file. */
- (void)loadSavedDevices {
    NSArray *storedDevices  = [[NSUserDefaults standardUserDefaults] arrayForKey:@"DYStoredDevices"];
    
    if (![storedDevices isKindOfClass:[NSArray class]]) {
        DYCBDEBUG(@"No stored array to load");
        return;
    }
    
    for (id deviceUUIDString in storedDevices) {
        
        if (![deviceUUIDString isKindOfClass:[NSString class]])
            continue;
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_9 || __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
        NSUUID *uuid = [[NSUUID UUID] initWithUUIDString:deviceUUIDString];
        [CM retrievePeripheralsWithIdentifiers:[NSArray arrayWithObject:uuid]];
#else
        CFUUIDRef uuid = CFUUIDCreateFromString(NULL, (CFStringRef)deviceUUIDString);
        if (!uuid)
            continue;
        [CM retrievePeripherals:[NSArray arrayWithObject:(__bridge id)(uuid)]];
        CFRelease(uuid);
#endif
    }
    
}


- (void)addSavedDevice:(CFUUIDRef) uuid {
    NSArray         *storedDevices  = [[NSUserDefaults standardUserDefaults] arrayForKey:@"DYCoreBluetoothStoredDevices"];
    NSMutableArray  *newDevices     = nil;
    CFStringRef     uuidString      = NULL;
    
    if (![storedDevices isKindOfClass:[NSArray class]]) {
        DYCBDEBUG(@"Can't find/create an array to store the uuid");
        return;
    }
    
    newDevices = [NSMutableArray arrayWithArray:storedDevices];
    
    uuidString = CFUUIDCreateString(NULL, uuid);
    if (uuidString) {
        [newDevices addObject:(__bridge NSString*)uuidString];
        CFRelease(uuidString);
    }
    /* Store */
    [[NSUserDefaults standardUserDefaults] setObject:newDevices forKey:@"DYCoreBluetoothStoredDevices"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)removeSavedDevice:(CFUUIDRef) uuid {
    NSArray         *storedDevices  = [[NSUserDefaults standardUserDefaults] arrayForKey:@"DYCoreBluetoothStoredDevices"];
    NSMutableArray  *newDevices     = nil;
    CFStringRef     uuidString      = NULL;
    
    if ([storedDevices isKindOfClass:[NSArray class]]) {
        newDevices = [NSMutableArray arrayWithArray:storedDevices];
        
        uuidString = CFUUIDCreateString(NULL, uuid);
        if (uuidString) {
            [newDevices removeObject:(__bridge NSString*)uuidString];
            CFRelease(uuidString);
        }
        /* Store */
        [[NSUserDefaults standardUserDefaults] setObject:newDevices forKey:@"DYCoreBluetoothStoredDevices"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
//

@end
