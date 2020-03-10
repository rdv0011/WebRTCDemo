/*
 *  Copyright 2018 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ARDExternalSampleCapturer.h"

#import "ARDUtilities.h"
#import <WebRTC/WebRTC.h>

const CGFloat kMaximumSupportedResolution = 640;

@implementation ARDExternalSampleCapturer

- (instancetype)initWithDelegate:(__weak id<RTCVideoCapturerDelegate>)delegate {
  return [super initWithDelegate:delegate];
}

#pragma mark - ARDExternalSampleDelegate

- (void)didCaptureSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  if (CMSampleBufferGetNumSamples(sampleBuffer) != 1 || !CMSampleBufferIsValid(sampleBuffer) ||
      !CMSampleBufferDataIsReady(sampleBuffer)) {
    return;
  }

  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  if (pixelBuffer == nil) {
    return;
  }

  RTCCVPixelBuffer * rtcPixelBuffer = nil;
  CGFloat originalWidth = (CGFloat)CVPixelBufferGetWidth(pixelBuffer);
  CGFloat originalHeight = (CGFloat)CVPixelBufferGetHeight(pixelBuffer);
  // Downscale the buffer due to the big memory footprint (> 50MB) for bigger then 720p resolutions
  if (originalWidth > kMaximumSupportedResolution || originalHeight > kMaximumSupportedResolution) {
    rtcPixelBuffer = [[RTCCVPixelBuffer alloc] initWithPixelBuffer: pixelBuffer];
    int width = originalWidth * kMaximumSupportedResolution / originalHeight;
    int height = kMaximumSupportedResolution;
    if (originalWidth > originalHeight) {
      width = kMaximumSupportedResolution;
      height = originalHeight * kMaximumSupportedResolution / originalWidth;
    }
    CVPixelBufferRef outputPixelBuffer = nil;
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width,
                                            height, pixelFormat, nil,
                                            &outputPixelBuffer);
    if (status!=kCVReturnSuccess) {
        RTCLog(@"Failed to create pixel buffer %d", status);
        return;
    }

    int tmpBufferSize = [rtcPixelBuffer bufferSizeForCroppingAndScalingToWidth:width height:height];

    uint8_t* tmpBuffer = malloc(tmpBufferSize);
    if ([rtcPixelBuffer cropAndScaleTo:outputPixelBuffer withTempBuffer:tmpBuffer]) {
        rtcPixelBuffer = [[RTCCVPixelBuffer alloc] initWithPixelBuffer: outputPixelBuffer];
    } else {
        CVPixelBufferRelease(outputPixelBuffer);
        free(tmpBuffer);
        RTCLog(@"Failed to scale and crop pixel buffer");
        return;
    }
    CVPixelBufferRelease(outputPixelBuffer);
    free(tmpBuffer);
  }
  int64_t timeStampSec = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer));
  RTCVideoFrame *videoFrame = [[RTCVideoFrame alloc] initWithBuffer:rtcPixelBuffer
                                                           rotation:RTCVideoRotation_0
                                                        timeStampNs:timeStampSec * NSEC_PER_SEC];
  [self.delegate capturer:self didCaptureVideoFrame:videoFrame];
}

@end
