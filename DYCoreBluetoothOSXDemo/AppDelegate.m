//
//  AppDelegate.m
//  DYCoreBluetoothOSXDemo
//
//  Created by danny on 13/10/7.
//  Copyright (c) 2013年 danny. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate
{
    DYCoreBluetooth *dcb1;
    CBPeripheral* activePeripheral;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    _btnConnect.hidden = NO;
    _btnDisconnect.hidden = YES;
    _btnSend.enabled = NO;

}


- (IBAction)btnBLEConnect:(id)sender
{
    _btnConnect.enabled = NO;
    _btnSend.enabled = NO;
    _btnDisconnect.hidden = YES;
    dcb1=[DYCoreBluetooth sharedInstance];
    dcb1.delegate=self;
    [dcb1 startScanningForUUIDString:Nil];
    NSLog(@"Connect");
}

- (IBAction)btnBLESend:(id)sender {
    [dcb1 writeUART:_sendData.stringValue];
    _sendData.stringValue = @"";
}

- (IBAction)btnBLEDisconnect:(id)sender {
    [dcb1 disconnect:activePeripheral];
    _btnDisconnect.enabled = NO;
    _btnConnect.hidden = YES;
    _btnSend.enabled = NO;
}
//
- (void)didUpdateValueWithPeripheral:(CBPeripheral*)peripheral Characteristics:(CBUUID*)cbUUID stringData:(NSString*)stringData binaryData:(NSData*)binaryData error:(NSError *)error {
    NSLog(@"get1===%@",stringData);
    _receiveData.stringValue = [NSString stringWithFormat:@"%@%@",_receiveData.stringValue,stringData];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)aNotification {
    return YES;
}


- (void)didUpdateState:(BOOL)isAvailable message:(NSString*)msg status:(CBCentralManagerState)status {
    if (!isAvailable) {
        _btnDisconnect.enabled = NO;
        _btnConnect.enabled = NO;
        //
        NSAlert *alert = [[NSAlert alloc] init];//右邊開始算起
        [alert addButtonWithTitle:@"OK"];//右一
        
        [alert setMessageText:@"Your device can't support Bluetooth Low Energy"];//標頭
        [alert setInformativeText:@"Error"];//內容
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert runModal];
        //
    } else {
        _btnDisconnect.enabled = YES;
        _btnConnect.enabled = YES;
    }
}

-(void) didDiscoverPeripheral:(NSMutableArray*)foundPeripherals{

    for (CBPeripheral* p in foundPeripherals) {
        NSLog(@"----%@",p.name);
        
    }
    activePeripheral = (CBPeripheral*)[foundPeripherals objectAtIndex:0];;
    [dcb1 connect:activePeripheral];
}

-(void) didConnected:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"didConnected");
//    [dcb1 setWriteUARTEnvironmentServiceUUID:0xffe0 characteristicUUID:0xffe2];
    [dcb1 setWriteUARTEnvironmentServiceUUID128:[CBUUID UUIDWithString:@"FFE0"] characteristicUUID:[CBUUID UUIDWithString:@"FFE2"]];
    _btnConnect.hidden = YES;
    _btnDisconnect.enabled = YES;
    _btnDisconnect.hidden = NO;
    _btnSend.enabled = YES;
}

-(void) didDisconnected:(CBPeripheral *)peripheral error:(NSError *)error{
    _btnConnect.hidden = NO;
    _btnDisconnect.hidden = YES;
    _btnConnect.enabled = YES;
    _btnSend.enabled = NO;
}

-(void) didFailToConnect:(CBPeripheral *)peripheral error:(NSError *)error{
    _btnConnect.hidden = NO;
    _btnConnect.enabled = YES;
    _btnDisconnect.hidden = YES;
    _btnSend.enabled = NO;
    
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
}



@end
