//
//  PLYPlaybackView.m
//  Playoff
//
//  Created by Arie Lakeman on 04/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYPlaybackView.h"
#import <AVFoundation/AVFoundation.h>

/* ---------------------------------------------------------
 **  To play the visual component of an asset, you need a view
 **  containing an AVPlayerLayer layer to which the output of an
 **  AVPlayer object can be directed. You can create a simple
 **  subclass of UIView to accommodate this. Use the view’s Core
 **  Animation layer (see the 'layer' property) for rendering.
 **  This class, AVPlayerDemoPlaybackView, is a subclass of UIView
 **  that is used for this purpose.
 ** ------------------------------------------------------- */

@implementation PLYPlaybackView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    return self;
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end
