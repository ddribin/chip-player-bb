//
//  MusicPlayerStateMachine.m
//  RetroPlayer
//
//  Created by Dave Dribin on 4/1/10.
//  Copyright 2010 Bit Maki, Inc.. All rights reserved.
//

#import "MusicPlayerStateMachine.h"

enum State {
    RRStateUninitialized,
    RRStateStopped,
    RRStatePlaying,
    RRStatePaused,
};

@implementation MusicPlayerStateMachine

- (id)initWithActions:(id<MusicPlayerActions>)actions;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _actions = actions;
    _state = RRStateUninitialized;
    
    return self;
}

- (BOOL)isPlaying;
{
    return ((_state == RRStatePlaying) || (_state == RRStatePaused));
}

- (void)setup;
{
    NSAssert(_state == RRStateUninitialized, @"Invalid state");
    
    [_actions clearError];
    NSError * error = nil;
    if (![_actions setupAudio:&error]) {
        [_actions handleError:error];
        return;
    }
    
    _state = RRStateStopped;
}

- (void)teardown;
{
    NSAssert(_state != RRStateUninitialized, @"Invalid state");
    
    [_actions clearError];
    [_actions stopAudio];
    [_actions teardownAudio];
    _state = RRStateUninitialized;
}

- (void)play;
{
    NSAssert(_state != RRStateUninitialized, @"Invalid state");

    if ((_state == RRStatePlaying) || (_state == RRStatePaused)) {
        [_actions stopAudio];
    }

    [_actions setCurrentTrackToSelectedTrack];
    [_actions clearError];
    NSError * error = nil;;
    if (![_actions startAudio:&error]) {
        [_actions handleError:error];
        return;
    }
    
    [_actions didPlay];
    _state = RRStatePlaying;
}

- (void)stop;
{
    NSAssert(_state != RRStateUninitialized, @"Invalid state");
    if (_state == RRStateStopped) {
        return;
    }
    
    [_actions clearError];
    [_actions stopAudio];
    [_actions didStop];
    _state = RRStateStopped;
}

- (void)pause;
{
    NSAssert(_state != RRStateUninitialized, @"Invalid state");
    NSAssert(_state == RRStatePlaying, @"Invalid state");

    [_actions clearError];
    NSError * error = nil;
    if (![_actions pauseAudio:&error]) {
        [_actions handleError:error];
        return;
    }
    
    [_actions didPause];
    _state = RRStatePaused;
}

- (void)unpause;
{
    NSAssert(_state != RRStateUninitialized, @"Invalid state");
    NSAssert(_state == RRStatePaused, @"Invalid state");
    
    [_actions clearError];
    NSError * error = nil;
    if (![_actions unpauseAudio:&error]) {
        [_actions handleError:error];
        return;
    }
    
    [_actions didPlay];
    _state = RRStatePlaying;
}

- (void)togglePause;
{
    NSAssert(_state != RRStateUninitialized, @"Invalid state");
    NSAssert(_state != RRStateStopped, @"Invalid state");
    
    if (_state == RRStatePlaying) {
        [self pause];
    } else {
        [self unpause];
    }
}

- (void)trackDidFinish;
{
    NSAssert(_state == RRStatePlaying, @"Invalid state");
    
    if ([_actions isCurrentTrackTheLastTrack]) {
        [_actions stopAudio];
        [_actions didStop];
    } else {
        [_actions stopAudio];
        [_actions nextTrack];
        [_actions startAudio:NULL];
    }
}

@end
