//
//  OneMinChallenge.m
//  CC Fitness
//
//  Created by Hongxuan on 18/2/17.
//  Copyright © 2017 Hongxuan. All rights reserved.
//

#import "OneMinChallenge.h"
#import "PushUpLog+CoreDataClass.h"
#import "AppDelegate.h"

@interface OneMinChallenge ()
{
    int timeTick;
    NSTimer *timer;
    BOOL started;
    int pushUpCount;
}

@end

@implementation OneMinChallenge

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    
    //Initialize bool flag for UIAlertController event.
    started = NO;
    //Create back button to handle UIAlertController event.
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Quit" style:UIBarButtonItemStylePlain
                                                                     target:self action:@selector(goBackSegue:)];
    self.navigationItem.leftBarButtonItem= newBackButton;

    //Initialize timer
    timeTick = 5;
    
    //Initialize the pushup counter
    pushUpCount = 0;
    
    /*Invalidate (stop) the timer if it is running, otherwise when this function is called again,
     the timer would run twice as fast each second and so on. */
    [timer invalidate];
    
    //Create timer object
    //set tick interval to 1.0
    //set selector to the method that should be executed on the interval
    //set repeat to yes meaning it should run continiously, not just once
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTickGetReady) userInfo:nil repeats:YES];
    
    //Add observer for app resigning to background and returning to foreground
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseTimer) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeTimer) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)pauseTimer {
    
    [timer invalidate];
    device.proximityMonitoringEnabled = NO;

}

- (void)resumeTimer {
    
    if (![self.navigationController.visibleViewController isKindOfClass:[UIAlertController class]]) {
        
        if (!started)
        {
            timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTickGetReady) userInfo:nil repeats:YES];
            
        }
        else
        {
            device.proximityMonitoringEnabled = YES;
            timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTickStart) userInfo:nil repeats:YES];
        }
    }
}

- (void)goBackSegue:(UIBarButtonItem *)sender
{
    [timer invalidate];
    device.proximityMonitoringEnabled = NO;
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Return to the start menu?"
                                                                   message:@"Your results will not be saved!"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                          
                                                              [self.navigationController popToRootViewControllerAnimated:YES];
                                                              
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                         
                                                             if (!started)
                                                             {
                                                                 timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTickGetReady) userInfo:nil repeats:YES];
                                                             }
                                                             else
                                                             {
                                                                 device.proximityMonitoringEnabled = YES;

                                                                 timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTickStart) userInfo:nil repeats:YES];
                                                             }
                                                         
                                                         }];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)timerTickGetReady
{
    //Each tick decrement by one
    timeTick--;
    
    //Update time each tick
    NSString *timeString =[[NSString alloc] initWithFormat:@"%i", timeTick];
    self.lblCount.text = timeString;
    
    if (timeTick == 0)
    {
        started = YES;
        
        //Stop the timer when it reaches 0
        [timer invalidate];
        
        //reset timer to 1 minute
        timeTick = 60;
        
        self.lblAlertTimer.text = @"60 SECONDS";
        
        self.lblPushUps.alpha = 1.0; //Show lblPushUps
        
        //Enable the proximity sensor to use it
        device = [UIDevice currentDevice];
        device.proximityMonitoringEnabled = YES;
        
        // Proximity Sensor Notification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityChanged:) name:@"UIDeviceProximityStateDidChangeNotification" object:device]; //Create an observer to detect proximity changes
        
        //Begin timer
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTickStart) userInfo:nil repeats:YES];
    }

}

-(void)timerTickStart
{
    timeTick--;
    
    NSString *timeString =[[NSString alloc] initWithFormat:@"%i SECONDS", timeTick];

    self.lblAlertTimer.text = timeString;
    
    if (timeTick == 0)
    {
        [timer invalidate];
        device.proximityMonitoringEnabled = NO;
        
        [self alertFinalScore];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidDisappear:(BOOL)animated
{
    device.proximityMonitoringEnabled = NO;
    [timer invalidate];
    timer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)proximityChanged:(NSNotification *)notification
{
    device = [notification object];
    
    if (device.proximityState == 1) {
        
        pushUpCount++; //Increment as proximity state changes
        self.lblCount.text = [NSString stringWithFormat:@"%i", pushUpCount]; //Output to the label
        
    }
}


- (void)alertFinalScore
{
    NSString *displayScore = [NSString stringWithFormat:@"Score: %i\nWould you like to save the result of your attempt?", pushUpCount];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Challenge complete!"
                                                                   message:displayScore
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              [self alertSaveScore];
                                                              
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                             [self.navigationController popToRootViewControllerAnimated:YES];
                                                             
                                                         }];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)alertSaveScore
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Enter name"
                                                                   message:@"Please enter your name"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        
        textField.placeholder = @"Your name";
        [textField addTarget:self action:@selector(alertControllerTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        
    }];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Submit" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              //Insertion of data here
                                                              UITextField *userName = alert.textFields.firstObject;
                                                              if ([self insertEntryWithName:userName.text andScore:pushUpCount])
                                                              {
                                                                  [self.navigationController popToRootViewControllerAnimated:YES];
                                                              }
                                                              else
                                                              {
                                                                  NSLog(@"Debug: Check text field value %@", userName.text);
                                                              }
                                                              
                                                          }];
    
    defaultAction.enabled = NO;
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             
                                                             [self.navigationController popToRootViewControllerAnimated:YES];
                                                             
                                                         }];

    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (void)alertControllerTextFieldDidChange:(UITextField *)sender {
    
    
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController)
    {
        UITextField *someTextField = alertController.textFields.firstObject;
        UIAlertAction *okAction = alertController.actions.firstObject;
        okAction.enabled = someTextField.text.length >= 2 && someTextField.text.length <= 25;
    }
}


- (BOOL)insertEntryWithName: (NSString *)name andScore:(int)score
{
    //PushUpLog only saves 20 entries. The last entry will be deleted.
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc]initWithEntityName:@"PushUpLog"];
    NSError *requestError = nil;
    
    NSArray *entries = [context executeFetchRequest:fetchRequest error:&requestError];
    PushUpLog *firstEntry = entries.firstObject;
    
    if ([entries count] > 20)
    {
        [context deleteObject:firstEntry];
    }
    
    
    PushUpLog *newEntry = [NSEntityDescription insertNewObjectForEntityForName:@"PushUpLog" inManagedObjectContext:context];
     
    if (newEntry == nil)
    {
        NSLog(@"Failed to create new entry.");
        return NO;
    }
    
    newEntry.userName = name;
    newEntry.numOfReps = score;
    newEntry.attemptCategory = @"One Minute Challenge";
    newEntry.timeElapsed = @"00:01:00";
    newEntry.attemptDate = [NSDate date];
    
    NSError *savingError = nil;
    
    if (![context save:&savingError])
    {
        NSLog(@"Failed to save the new entry. Error: %@", savingError);
        return NO;
    }
    
    return YES;

}


/*
 #pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


@end
