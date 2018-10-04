//
//  SenbayNetworkSocket.m
//  FBSnapshotTestCase
//
//  Created by Yuuki Nishiyama on 2018/09/13.
//

#import "SenbayNetworkSocket.h"

@implementation SenbayNetworkSocket{
    BOOL isUdpActive;
    BOOL isTcpActive;
    GCDAsyncUdpSocket * udpSocket;
    // GCDAsyncSocket    * tcpSocekt;
    NSString * udpString;
    NSString * tcpString;
}

- (instancetype) init
{
    self = [super init];
    if (self != nil) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        // tcpSocekt = [[GCDAsyncSocket alloc]    initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

// SOCK
- (NSString *)getData
{
    if (isUdpActive) {
        if (udpString != nil) {
            return [NSString stringWithFormat:@"NTAG:'%@'",udpString];
        }
    }
    return nil;
}

///////////////////////////////////////////////////////////////////////

- (bool) activateUdpScoketWithPort:(int)port
{
    NSError *error = nil;

    isUdpActive = YES;
    
    if (![udpSocket bindToPort:port error:&error]) {
        isUdpActive = NO;
        return NO;
    }
    
    if (![udpSocket beginReceiving:&error]) {
        [udpSocket close];
        isUdpActive = NO;
        return NO;
    }
    
    return YES;
}

- (bool) deactivateUdpSocket
{
    isUdpActive = NO;
    if(udpSocket != nil){
        [udpSocket closeAfterSending];
    }
    return NO;
    
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock
   didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    if (!isUdpActive) return;
    
    udpString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (udpString) {
        /* If you want to get a display friendly version of the IPv4 or IPv6 address, you could do this:
         
         NSString *host = nil;
         uint16_t port = 0;
         [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
         */
        // NSLog(@"%@",_socketRawData);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SENBAY_EVENT_UDP_SOCKET_DID_RECEIVED_DATA object:udpString];
        
    } else {
        // [self logError:@"Error converting received data into UTF-8 String"];
    }
    
    // [udpSocket sendData:data toAddress:address withTimeout:-1 tag:0];
}

@end
