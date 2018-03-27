//
//  SDLtreamDelegate.m
//

#import "SDLStreamDelegate.h"
#import "SDLLogMacros.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDLStreamDelegate () {
    dispatch_queue_t _input_stream_queue;
}

@end


@implementation SDLStreamDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        _streamOpenHandler = defaultStreamOpenHandler;
        _streamHasBytesHandler = defaultStreamHasBytesHandler;
        _streamHasSpaceHandler = defaultStreamHasSpaceHandler;
        _streamErrorHandler = defaultStreamErrorHandler;
        _streamEndHandler = defaultStreamErrorHandler;

        _input_stream_queue = dispatch_queue_create("com.sdl.streamdelegate.input", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            if (_streamOpenHandler) {
                self.streamOpenHandler(stream);
            }
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            if (_streamHasBytesHandler) {
                dispatch_async(_input_stream_queue, ^{
                    self.streamHasBytesHandler((NSInputStream *)stream);
                });
            }
            break;
        }
        case NSStreamEventHasSpaceAvailable: {
            if (_streamHasSpaceHandler) {
                self.streamHasSpaceHandler((NSOutputStream *)stream);
            }
            break;
        }
        case NSStreamEventErrorOccurred: {
            if (_streamErrorHandler) {
                self.streamErrorHandler(stream);
            }
            break;
        }
        case NSStreamEventEndEncountered: {
            if (_streamEndHandler) {
                self.streamEndHandler(stream);
            }
            break;
        }
        case NSStreamEventNone:
        default: {
            break;
        }
    }
}

SDLStreamOpenHandler defaultStreamOpenHandler = ^(NSStream *stream) {
    SDLLogV(@"Transport stream event open");
};

SDLStreamHasBytesHandler defaultStreamHasBytesHandler = ^(NSInputStream *istream) {
    SDLLogV(@"Transport stream event has bytes");
};

SDLStreamHasSpaceHandler defaultStreamHasSpaceHandler = ^(NSOutputStream *ostream) {
    SDLLogV(@"Transport stream event has space");
};

SDLStreamErrorHandler defaultStreamErrorHandler = ^(NSStream *stream) {
    SDLLogV(@"Transport stream event error");
};

SDLStreamEndHandler defaultStreamEndHandler = ^(NSStream *stream) {
    SDLLogV(@"Transport stream event end");
};

@end

NS_ASSUME_NONNULL_END
