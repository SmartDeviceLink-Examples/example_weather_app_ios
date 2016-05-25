//  SDLSmartDeviceLinkV2ProtocolHeader.m
//


#import "SDLV2ProtocolHeader.h"

const int V2PROTOCOL_HEADERSIZE = 12;


@interface SDLV2ProtocolHeader ()

@end


@implementation SDLV2ProtocolHeader

- (instancetype)init {
    // TODO: Should this be changed to whatever the current version is from SDLGlobals
    return [self initWithVersion:2];
}

- (instancetype)initWithVersion:(UInt8)version {
    if (self = [super init]) {
        _version = version;
        _size = V2PROTOCOL_HEADERSIZE;
    }
    return self;
}

- (NSData *)data {
    // Assembles the properties in the binary header format
    Byte headerBytes[V2PROTOCOL_HEADERSIZE] = {0};

    Byte version = (self.version & 0xF) << 4; // first 4 bits
    Byte compressed = (self.compressed ? 1 : 0) << 3; // next 1 bit
    Byte frameType = (self.frameType & 0x7); // last 3 bits

    headerBytes[0] = version | compressed | frameType;
    headerBytes[1] = self.serviceType;
    headerBytes[2] = self.frameData;
    headerBytes[3] = self.sessionID;

    // Need to write these ints as big-endian.
    UInt32 *p = (UInt32 *)&headerBytes[4];
    *p = CFSwapInt32HostToBig(self.bytesInPayload);

    p = (UInt32 *)&headerBytes[8];
    *p = CFSwapInt32HostToBig(self.messageID);

    // Now put it all in an NSData object.
    NSData *dataOut = [NSData dataWithBytes:headerBytes length:V2PROTOCOL_HEADERSIZE];

    return dataOut;
}

- (id)copyWithZone:(NSZone *)zone {
    SDLV2ProtocolHeader *newHeader = [[SDLV2ProtocolHeader allocWithZone:zone] init];
    newHeader->_version = self.version;
    newHeader.compressed = self.compressed;
    newHeader.frameType = self.frameType;
    newHeader.serviceType = self.serviceType;
    newHeader.frameData = self.frameData;
    newHeader.bytesInPayload = self.bytesInPayload;
    newHeader.sessionID = self.sessionID;
    newHeader.messageID = self.messageID;

    return newHeader;
}

- (void)parse:(NSData *)data {
    NSParameterAssert(data != nil);
    NSAssert(data.length >= _size, @"Error: insufficient data available to parse V2 header.");

    Byte *bytePointer = (Byte *)data.bytes;
    Byte firstByte = bytePointer[0];
    self.compressed = ((firstByte & 8) != 0);
    self.frameType = (firstByte & 7);
    self.serviceType = bytePointer[1];
    self.frameData = bytePointer[2];
    self.sessionID = bytePointer[3];

    UInt32 *uintPointer = (UInt32 *)data.bytes;
    self.bytesInPayload = CFSwapInt32BigToHost(uintPointer[1]); // Data is coming in in big-endian, so swap it.
    self.messageID = CFSwapInt32BigToHost(uintPointer[2]); // Data is coming in in big-endian, so swap it.
}

- (NSString *)description {
    NSString *frameTypeString = nil;
    if (self.frameType >= 0 && self.frameType <= 3) {
        NSArray *frameTypeNames = @[ @"Control", @"Single", @"First", @"Consecutive" ];
        frameTypeString = frameTypeNames[self.frameType];
    }


    NSString *frameDataString = nil;
    if (self.frameType == SDLFrameType_Control) {
        if (self.frameData >= 0 && self.frameData <= 5) {
            NSArray *controlFrameDataNames = @[ @"Heartbeat", @"StartSession", @"StartSessionACK", @"StartSessionNACK", @"EndSession", @"EndSessionNACK" ];
            frameDataString = controlFrameDataNames[self.frameData];
        } else {
            frameDataString = @"Reserved";
        }
    } else if (self.frameType == SDLFrameType_Single || self.frameType == SDLFrameType_First) {
        frameDataString = @"Reserved";
    } else if (self.frameType == SDLFrameType_Consecutive) {
        frameDataString = @"Frame#";
    }

    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"Version:%i, compressed:%i, frameType:%@(%i), serviceType:%i, frameData:%@(%i), sessionID:%i, dataSize:%i, messageID:%i ",
                              self.version,
                              self.compressed,
                              frameTypeString,
                              self.frameType,
                              self.serviceType,
                              frameDataString,
                              self.frameData,
                              self.sessionID,
                              (unsigned int)self.bytesInPayload,
                              (unsigned int)self.messageID];
    return description;
}

@end
