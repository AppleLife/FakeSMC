//
//  AppDelegate.m
//  HWMonitor
//
//  Created by mozo on 20.10.11.
//  Copyright (c) 2011 mozo. All rights reserved.
//

#import "AppDelegate.h"
#import "NSString+TruncateToWidth.h"
#include "FakeSMCDefinitions.h"

@implementation AppDelegate


#define SMART_UPDATE_INTERVAL 5*60

- (void)updateTitles
{
    io_service_t service = IOServiceGetMatchingService(0, IOServiceMatching(kFakeSMCDeviceService));
    
    if (service) {
        
        NSEnumerator * enumerator = nil;
        HWMonitorSensor * sensor = nil;
        int count = 0;
        

        CFMutableArrayRef favorites = (CFMutableArrayRef)CFArrayCreateMutable(kCFAllocatorDefault, 0, nil);
        
        enumerator = [sensorsList  objectEnumerator];
        
        while (sensor = (HWMonitorSensor *)[enumerator nextObject]) {
            if (isMenuVisible || [sensor favorite]) {
                CFTypeRef name = (CFTypeRef) CFStringCreateWithCString(kCFAllocatorDefault, [[sensor key] cStringUsingEncoding:NSUTF8StringEncoding], kCFStringEncodingUTF8);
                
                CFArrayAppendValue(favorites, name);
            }
        }
        
        NSMutableString * statusString = [[NSMutableString alloc] init];
        
        if (kIOReturnSuccess == IORegistryEntrySetCFProperty(service, CFSTR(kFakeSMCDevicePopulateList), favorites)) 
        {           
          NSMutableDictionary * values = (__bridge_transfer NSMutableDictionary *)IORegistryEntryCreateCFProperty(service, CFSTR(kFakeSMCDeviceValues), kCFAllocatorDefault, 0);
            
            if(smart)
            {
                if (fabs([lastcall timeIntervalSinceNow]) > SMART_UPDATE_INTERVAL) 
                {
                    lastcall = [NSDate date];
                    [smartController update];
                }
                [values addEntriesFromDictionary:[smartController getDataSet:1]];
            }
            if (values) {
                
                enumerator = [sensorsList  objectEnumerator];
                
                while (sensor = (HWMonitorSensor *)[enumerator nextObject]) {
                    
                    if (isMenuVisible) {
                        NSString * value =[[NSString alloc] initWithString:[sensor formateValue:[values objectForKey:[sensor key]]]];
                        
                        NSMutableAttributedString * title = [[NSMutableAttributedString alloc] initWithString:[[NSString alloc] initWithFormat:@"%S\t%S",[[sensor caption] cStringUsingEncoding:NSUTF16StringEncoding],[value cStringUsingEncoding:NSUTF16StringEncoding]] attributes:statusMenuAttributes];
                        
                        [title addAttribute:NSFontAttributeName value:statusMenuFont range:NSMakeRange(0, [title length])];
                        
                        // Update menu item title
                        [(NSMenuItem *)[sensor object] setAttributedTitle:title];
                    }
                    
                    if ([sensor favorite]) {
                        NSString * value =[[NSString alloc] initWithString:[sensor formateValue:[values objectForKey:[sensor key]]]];
                        
                        [statusString appendString:@" "];
                        [statusString appendString:value];
                        
                        count++;
                    }
                }
            }
        }
        
        CFArrayRemoveAllValues(favorites);
        CFRelease(favorites);
        
        IOObjectRelease(service);
        
        if (count > 0) {
            // Update status bar title
            NSMutableAttributedString * title = [[NSMutableAttributedString alloc] initWithString:statusString attributes:statusItemAttributes];
            [title addAttribute:NSFontAttributeName value:statusItemFont range:NSMakeRange(0, [title length])];
            [statusItem setAttributedTitle:title];
        }
        else [statusItem setTitle:@""];
    }

}

- (HWMonitorSensor *)addSensorWithKey:(NSString *)key andType:(NSString *) aType andCaption:(NSString *)caption intoGroup:(SensorGroup)group 
{
    if(group==HDSmartTempSensorGroup || [HWMonitorSensor populateValueForKey:key])
    {
        caption = [caption stringByTruncatingToWidth:145.0f withFont:statusItemFont]; 
        HWMonitorSensor * sensor = [[HWMonitorSensor alloc] initWithKey:key andType: aType andGroup:group withCaption:caption];
        
        [sensor setFavorite:[[NSUserDefaults standardUserDefaults] boolForKey:key]];
        
        NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:caption action:nil keyEquivalent:@""];
        
        [menuItem setRepresentedObject:sensor];
        [menuItem setAction:@selector(menuItemClicked:)];
        
        if ([sensor favorite]) [menuItem setState:TRUE];
        
        [statusMenu insertItem:menuItem atIndex:menusCount++];
        
        [sensor setObject:menuItem];
        
        [sensorsList addObject:sensor];
        
        return sensor;

    }
      return NULL;
}

- (void)insertFooterAndTitle:(NSString *)title
{
    if (lastMenusCount < menusCount) {
        NSMenuItem * titleItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
        
        [titleItem setEnabled:FALSE];
        //[titleItem setIndentationLevel:1];
        
        [statusMenu insertItem:titleItem atIndex:lastMenusCount]; menusCount++;       
        [statusMenu insertItem:[NSMenuItem separatorItem] atIndex:menusCount++];
        
        lastMenusCount = menusCount;
    }
}

// Events

- (void)menuWillOpen:(NSMenu *)menu {
    isMenuVisible = YES;
    
    [self updateTitles];
}

- (void)menuDidClose:(NSMenu *)menu {
    isMenuVisible = NO;
}

- (void)menuItemClicked:(id)sender {
    NSMenuItem * menuItem = (NSMenuItem *)sender;
    
    [menuItem setState:![menuItem state]];
    
    HWMonitorSensor * sensor = (HWMonitorSensor *)[menuItem representedObject];
    
    [sensor setFavorite:[menuItem state]];
    
    [self updateTitles];
    
    [[NSUserDefaults standardUserDefaults] setBool:[menuItem state] forKey:[sensor key]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                [self methodSignatureForSelector:@selector(updateTitles)]];
    [invocation setTarget:self];
    [invocation setSelector:@selector(updateTitles)];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:2 invocation:invocation repeats:YES] forMode:NSRunLoopCommonModes];
    
    [self updateTitles];
}

- (void)awakeFromNib
{
    menusCount = 0;
    lastcall = [NSDate date];
    smartController = [[ISPSmartController alloc] init];
	if (smartController) {
        smart = YES;
        [smartController getPartitions];
        [smartController update];
        DisksList = [smartController getDataSet:1];
    }
	
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:YES];
    [statusItem setImage:[NSImage imageNamed:@"thermo"]];
    [statusItem setAlternateImage:[NSImage imageNamed:@"thermotemplate"]];
    
    statusItemFont = [NSFont fontWithName:@"Lucida Grande Bold" size:9.0];
    
    NSMutableParagraphStyle * style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:0];

    statusItemAttributes = [NSDictionary dictionaryWithObject:style forKey:NSParagraphStyleAttributeName];
    
    statusMenuFont = [NSFont fontWithName:@"Lucida Grande Bold" size:10];
    [statusMenu setFont:statusMenuFont];
    
    style = [[NSMutableParagraphStyle alloc] init];
    [style setTabStops:[NSArray array]];
    [style addTabStop:[[NSTextTab alloc] initWithType:NSRightTabStopType location:190.0]];
    //[style setDefaultTabInterval:390.0];
    statusMenuAttributes = [NSDictionary dictionaryWithObject:style forKey:NSParagraphStyleAttributeName];
    
    // Init sensors
    sensorsList = [[NSMutableArray alloc] init];
    lastMenusCount = menusCount;
    
    //Temperatures
    
    for (int i=0; i<0xA; i++)
        [self addSensorWithKey:[[NSString alloc] initWithFormat:@"TC%XD",i] andType: @TYPE_SP78 andCaption:[[NSString alloc] initWithFormat:@"CPU %X",i] intoGroup:TemperatureSensorGroup ];
    
    [self addSensorWithKey:@"Th0H" andType: @TYPE_SP78 andCaption:@"CPU Heatsink" intoGroup:TemperatureSensorGroup ];
    [self addSensorWithKey:@"TN0P" andType: @TYPE_SP78 andCaption:@"Motherboard" intoGroup:TemperatureSensorGroup ];
    [self addSensorWithKey:@"Tm0P" andType: @TYPE_SP78 andCaption:@"Memory" intoGroup:TemperatureSensorGroup ];
    [self addSensorWithKey:@"TA0P" andType: @TYPE_SP78 andCaption:@"Ambient" intoGroup:TemperatureSensorGroup ];
    
    for (int i=0; i<0xA; i++) {
        [self addSensorWithKey:[[NSString alloc] initWithFormat:@"TG%XD",i] andType: @TYPE_SP78 andCaption:[[NSString alloc] initWithFormat:@"GPU %X Core",i] intoGroup:TemperatureSensorGroup ];
        [self addSensorWithKey:[[NSString alloc] initWithFormat:@"TG%XH",i] andType: @TYPE_SP78 andCaption:[[NSString alloc] initWithFormat:@"GPU %X Board",i] intoGroup:TemperatureSensorGroup ];
        [self addSensorWithKey:[[NSString alloc] initWithFormat:@"TG%XP",i] andType: @TYPE_SP78 andCaption:[[NSString alloc] initWithFormat:@"GPU %X Proximity",i] intoGroup:TemperatureSensorGroup ];
    }
    
    [self insertFooterAndTitle:@"TEMPERATURES"];  
    
    for (int i=0; i<16; i++)
        [self addSensorWithKey:[[NSString alloc] initWithFormat:@"FRC%X",i] andType: @TYPE_FREQ andCaption:[[NSString alloc] initWithFormat:@"CPU %X",i] intoGroup:FrequencySensorGroup ];
    
    //
//    [self addSensorWithKey:@"FGC0" andCaption:@"GPU" intoGroup:FrequencySensorGroup];
    [self insertFooterAndTitle:@"FREQUENCIES"];
    
    //Multipliers
    
    for (int i=0; i<0xA; i++)
        [self addSensorWithKey:[[NSString alloc] initWithFormat:@"MC%XC",i] andType: @TYPE_FP4C andCaption:[[NSString alloc] initWithFormat:@"CPU %X Multiplier",i] intoGroup:MultiplierSensorGroup ];
    
    [self addSensorWithKey:@"MPkC" andType: @TYPE_FP4C andCaption:@"CPU Package Multiplier" intoGroup:MultiplierSensorGroup ];

    [self insertFooterAndTitle:@"MULTIPLIERS"];
    
    // Voltages

    [self addSensorWithKey:@"VC0C" andType: @TYPE_FP2E andCaption:@"CPU Voltage" intoGroup:VoltageSensorGroup ];
    [self addSensorWithKey:@"VM0R" andType: @TYPE_FP2E andCaption:@"DIMM Voltage" intoGroup:VoltageSensorGroup ];
    [self addSensorWithKey:@KEY_12V_VOLTAGE andType: @TYPE_FP4C andCaption:@"12V Bus Voltage" intoGroup:VoltageSensorGroup ];
    [self addSensorWithKey:@KEY_AVCC_VOLTAGE andType: @TYPE_FP2E andCaption:@"VCC Bus Voltage" intoGroup:VoltageSensorGroup ];
    [self addSensorWithKey:@KEY_3VCC_VOLTAGE andType: @TYPE_FP2E andCaption:@"3.3 VCC Voltage" intoGroup:VoltageSensorGroup ];
    [self addSensorWithKey:@KEY_3VSB_VOLTAGE andType: @TYPE_FP2E andCaption:@"3.3 VSB Voltage" intoGroup:VoltageSensorGroup ];
    [self addSensorWithKey:@KEY_VBAT_VOLTAGE andType: @TYPE_FP2E andCaption:@"Battery Voltage" intoGroup:VoltageSensorGroup ];
    [self addSensorWithKey:@KEY_CPU_VRM_SUPPLY0 andType: @TYPE_FP2E andCaption:@"VRM Supply 0 Voltage" intoGroup:VoltageSensorGroup ];
    [self addSensorWithKey:@KEY_CPU_VRM_SUPPLY1 andType: @TYPE_FP2E andCaption:@"VRM Supply 1 Voltage" intoGroup:VoltageSensorGroup ];
    [self addSensorWithKey:@KEY_CPU_VRM_SUPPLY2 andType: @TYPE_FP2E andCaption:@"VRM Supply 2 Voltage" intoGroup:VoltageSensorGroup ];


    [self insertFooterAndTitle:@"VOLTAGES"];
    
    // Fans
    
    for (int i=0; i<10; i++)
    {
        NSString * caption = [[NSString alloc] initWithData:[HWMonitorSensor populateValueForKey:[[NSString alloc] initWithFormat:@"F%XID",i] ]encoding: NSUTF8StringEncoding];
        if([caption length]<=0) caption = [[NSString alloc] initWithFormat:@"Fan %d",i];
        
        [self addSensorWithKey:[[NSString alloc] initWithFormat:@"F%XAc",i] andType: @TYPE_FPE2 andCaption:caption intoGroup:TachometerSensorGroup ];
    }
    [self insertFooterAndTitle:@"FANS"];
    // Disks
    NSEnumerator * DisksEnumerator = [DisksList keyEnumerator]; 
    id nextDisk;
    while (nextDisk = [DisksEnumerator nextObject]) 
        [self addSensorWithKey:nextDisk andType: @TYPE_FPE2 andCaption:nextDisk intoGroup:HDSmartTempSensorGroup];
    
    
     [self insertFooterAndTitle:@"HARD DRIVES TEMPERATURES"];
    if (![sensorsList count]) {
        NSMenuItem * item = [[NSMenuItem alloc]initWithTitle:@"No sensors found or FakeSMCDevice unavailable" action:nil keyEquivalent:@""];
        
        [item setEnabled:FALSE];
        
        [statusMenu insertItem:item atIndex:0];
    }
}

@end
