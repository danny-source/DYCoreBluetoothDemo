//
//  ViewController.m
//  DYCoreBluetoothDemo
//
//  Created by danny on 13/7/11.
//  Copyright (c) 2013年 danny. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    DYCoreBluetooth *dyble;
    NSMutableArray *connectPeripheralArray;
    CBPeripheral *connectPeripheral;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    dyble=[DYCoreBluetooth sharedInstance];
    dyble.delegate=self;
    connectPeripheralArray=[NSMutableArray array];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnBLE_Scan:(id)sender {
    [dyble startScanningForUUIDString:nil];
}

- (IBAction)btnBLE_reConnect:(id)sender {
    connectPeripheralArray=[NSMutableArray array];
    [dyble connectWithUUIDString:@"EBBA38B0-5222-4D47-A85F-054427E0E952"];
    //BLESERIAL-0
//    [dyble connectWithUUIDString:@"20F6921C-0986-40A9-9335-20F82919A98F"];
}
- (IBAction)btnBLE_reConnect2:(id)sender {
    NSLog(@"%@",[dyble connectedPeripheral].name);
    [dyble writeUART:@"1234567890"];
    
}
- (IBAction)btnBLE_Disconnect:(id)sender {
    NSLog(@"Disconnect %ld",(unsigned long)connectPeripheralArray.count);
    for (CBPeripheral *p in connectPeripheralArray)
    {
        [dyble disconnect:p];
    }
}


#pragma mark - DYCoreBluetooth delegate

- (void)didUpdateState:(BOOL)isAvailable message:(NSString*)msg status:(DYCBCentralManagerState)status
{
    NSLog(@"state:%@",msg);
}

- (void)didUpdateValueWithPeripheral:(CBPeripheral*)peripheral Characteristics:(CBUUID*)cbUUID stringData:(NSString*)stringData binaryData:(NSData*)binaryData error:(NSError *)error
{
    
}

-(void) didUpdateValue:(CBUUID*)cbUUID Data:(NSString*)nsstrdata Data:(NSData*)nsdata error:(NSError *)error
{
    NSLog(@"-%@ %@",[nsdata debugDescription],nsstrdata);
}
//李HMD   07304E69-D29B-0409-E51C-455A5F3E6029
//久邦    07304E69-D29B-0409-E51C-455A5F3E6029
//微程    A5CC5A7F-CCD9-F150-8B49-9D49DB356012
//Danny  9D027D39-5A77-3B6B-BC45-5A1E00115269
//Danny  419D6B15-1F6C-EE7B-7751-2748ACA0D7C3
-(void) didDiscoverPeripheral:(NSMutableArray*)foundPeripherals
{
    for (CBPeripheral *p in foundPeripherals) {
        //CBUUID *cID=[CBUUID UUIDWithCFUUID:p.UUID];
        NSLog(@"===%@",p.identifier.UUIDString);
        if ([p.identifier.UUIDString isEqualToString:@"4CD91ED3-09BE-D7CB-9FE6-47F46CEA2F0C"])
        {
            NSLog(@"INFOS 4091v35.05  matched");
            [dyble connect:p];
            connectPeripheral=p;
        }
        
    }
}
-(void) didConnected:(CBPeripheral *)peripheral error:(NSError *)error
{
    [connectPeripheralArray addObject:peripheral];
    NSLog(@"%@ didConnected",peripheral.identifier.UUIDString);
    NSLog(@"didConnected");
//    [dyble registerNotificationWithIntUUID:0xffe0 characteristicUUID:0xffe2 peripheral:connectPeripheral on:YES];
    [dyble registerNotification:[CBUUID UUIDWithString:@"FFE0"] characteristicUUID:[CBUUID UUIDWithString:@"FFE2"] peripheral:connectPeripheral on:YES];
    
}
-(void) didDisconnected:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%@ didDisconnected",peripheral.name);
}
-(void) didFailToConnect:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didFailToConnect");    
}

-(void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{

}
-(void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{

}
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
}

-(void) didUpdateValueWithPeripheral:(CBPeripheral*)peripheral Characteristics:(CBUUID*)cbUUID Data:(NSString*)nsstrdata Data:(NSData*)nsdata error:(NSError *)error{
    NSLog(@"get1===%@",nsstrdata);
    _receiveData.text = [NSString stringWithFormat:@"%@%@",_receiveData.text,nsstrdata];
}

@end
