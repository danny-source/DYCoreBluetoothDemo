//
//  AppDelegate.h
//  DYCoreBluetoothOSXDemo
//
//  Created by danny on 13/10/7.
//  Copyright (c) 2013年 danny. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DYCoreBluetooth.h"


@interface AppDelegate : NSObject <NSApplicationDelegate,DYCoreBluetoohDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *receiveData;
@property (weak) IBOutlet NSTextField *sendData;
@property (weak) IBOutlet NSButton *btnConnect;
@property (weak) IBOutlet NSButton *btnDisconnect;
@property (weak) IBOutlet NSButton *btnSend;
- (IBAction)btnBLEConnect:(id)sender;
- (IBAction)btnBLESend:(id)sender;
- (IBAction)btnBLEDisconnect:(id)sender;
@end
