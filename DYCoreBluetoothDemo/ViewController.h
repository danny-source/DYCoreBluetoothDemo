//
//  ViewController.h
//  DYCoreBluetoothDemo
//
//  Created by danny on 13/7/11.
//  Copyright (c) 2013年 danny. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak) IBOutlet UITextField *receiveData;

- (IBAction)btnBLE_Scan:(id)sender;
- (IBAction)btnBLE_reConnect:(id)sender;
- (IBAction)btnBLE_reConnect2:(id)sender;
- (IBAction)btnBLE_Disconnect:(id)sender;

@end
