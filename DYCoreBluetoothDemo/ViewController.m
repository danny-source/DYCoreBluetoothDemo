//
//  ViewController.m
//  DYCoreBluetoothDemo
//
//  Created by danny on 13/7/11.
//  Copyright (c) 2013年 danny. All rights reserved.
//

#import "ViewController.h"
#import "DYCoreBluetooth.h"

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
//    [dyble reConnect:@"07304E69-D29B-0409-E51C-455A5F3E6029"];
    [dyble connectWithUUIDString:@"419D6B15-1F6C-EE7B-7751-2748ACA0D7C3"];
//    [dyble reConnect:@"A5CC5A7F-CCD9-F150-8B49-9D49DB356012"];
    //
    //[dyble reConnectWithStringUUIDArray:[NSArray arrayWithObjects:@"07304E69-D29B-0409-E51C-455A5F3E6029",@"A5CC5A7F-CCD9-F150-8B49-9D49DB356012", nil]];
}
- (IBAction)btnBLE_reConnect2:(id)sender {
    //[dyble reConnect:@"A5CC5A7F-CCD9-F150-8B49-9D49DB356012"];
    //[dyble reConnectWithStringUUIDArray:[NSArray arrayWithObjects:@"07304E69-D29B-0409-E51C-455A5F3E6029",@"A5CC5A7F-CCD9-F150-8B49-9D49DB356012", nil]];
    NSLog(@"%@",[dyble connectedPeripheral].name);
    [dyble writeUART:@"1234567890"];
    //Byte inventoryCommand[6]={ 0x01, 0x04, 0x03, 0x26, 0x01, 0x00 };
    //[dyble writeToUARTWithBin:[[NSData alloc] initWithBytes:inventoryCommand length:6] peripheral:[dyble connectedPeripheral]];
    
}
- (IBAction)btnBLE_Disconnect:(id)sender {
    NSLog(@"Disconnect %ld",(unsigned long)connectPeripheralArray.count);
    for (CBPeripheral *p in connectPeripheralArray)
    {
        [dyble disconnect:p];
    }
}


#pragma mark - DYCoreBluetooth delegate

-(void) didUpdateValue:(CBUUID*)cbUUID Data:(NSString*)nsstrdata Data:(NSData*)nsdata error:(NSError *)error
{
    NSLog(@"-%@ %@",[nsdata debugDescription],nsstrdata);
}
-(void) didUpdateState:(BOOL)isWork message:(NSString*)msg getStatus:(CBCentralManagerState)status
{
    
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
    [dyble registerNotificationWithIntUUID:0xffe0 characteristicUUID:0xffe2 peripheral:connectPeripheral on:YES];
    
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
