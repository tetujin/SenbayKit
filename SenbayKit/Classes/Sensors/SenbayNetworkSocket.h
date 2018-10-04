//
//  SenbayNetworkSocket.h
//  FBSnapshotTestCase
//
//  Created by Yuuki Nishiyama on 2018/09/13.
//

#import <Foundation/Foundation.h>
#import "SenbaySensor.h"

@import CocoaAsyncSocket;

#define SENBAY_EVENT_UDP_SOCKET_DID_RECEIVED_DATA @"senbay.event.udp.socket.didreceiveddata"

@interface SenbayNetworkSocket : SenbaySensor <GCDAsyncSocketDelegate, GCDAsyncUdpSocketDelegate>

- (bool) activateUdpScoketWithPort:(int)port;
- (bool) deactivateUdpSocket;

@end
