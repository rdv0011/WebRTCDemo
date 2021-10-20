/*
 *  Copyright 2016 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ARDSettingsModel+Private.h"
#import "ARDSettingsStore.h"

#if !BRODCAST_EXTENSION
#import <WebRTC/RTCCameraVideoCapturer.h>
#endif
#import <WebRTC/RTCDefaultVideoEncoderFactory.h>
#import <WebRTC/RTCMediaConstraints.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARDSettingsModel () {
  ARDSettingsStore *_settingsStore;
}
@end

@implementation ARDSettingsModel

- (NSArray<NSString *> *)availableVideoResolutions {
#if !BRODCAST_EXTENSION
  NSMutableSet<NSArray<NSNumber *> *> *resolutions =
      [[NSMutableSet<NSArray<NSNumber *> *> alloc] init];
  for (AVCaptureDevice *device in [RTCCameraVideoCapturer captureDevices]) {
    for (AVCaptureDeviceFormat *format in
         [RTCCameraVideoCapturer supportedFormatsForDevice:device]) {
      CMVideoDimensions resolution =
          CMVideoFormatDescriptionGetDimensions(format.formatDescription);
      NSArray<NSNumber *> *resolutionObject = @[ @(resolution.width), @(resolution.height) ];
      [resolutions addObject:resolutionObject];
    }
  }

  NSArray<NSArray<NSNumber *> *> *sortedResolutions =
      [[resolutions allObjects] sortedArrayUsingComparator:^NSComparisonResult(
                                    NSArray<NSNumber *> *obj1, NSArray<NSNumber *> *obj2) {
        NSComparisonResult cmp = [obj1.firstObject compare:obj2.firstObject];
        if (cmp != NSOrderedSame) {
          return cmp;
        }
        return [obj1.lastObject compare:obj2.lastObject];
      }];

  NSMutableArray<NSString *> *resolutionStrings = [[NSMutableArray<NSString *> alloc] init];
  for (NSArray<NSNumber *> *resolution in sortedResolutions) {
    NSString *resolutionString =
        [NSString stringWithFormat:@"%@x%@", resolution.firstObject, resolution.lastObject];
    [resolutionStrings addObject:resolutionString];
  }

  return [resolutionStrings copy];
#else
    return nil;
#endif
}

- (NSString *)currentVideoResolutionSettingFromStore {
  [self registerStoreDefaults];
  return [[self settingsStore] videoResolution];
}

- (BOOL)storeVideoResolutionSetting:(NSString *)resolution {
  if (![[self availableVideoResolutions] containsObject:resolution]) {
    return NO;
  }
  [[self settingsStore] setVideoResolution:resolution];
  return YES;
}

- (NSArray<RTCVideoCodecInfo *> *)availableVideoCodecs {
  return [RTCDefaultVideoEncoderFactory supportedCodecs];
}

- (RTCVideoCodecInfo *)currentVideoCodecSettingFromStore {
  [self registerStoreDefaults];
  NSData *codecData = [[self settingsStore] videoCodec];
  NSError *error = nil;
  id object = [NSKeyedUnarchiver unarchivedObjectOfClass:[ARDSettingsStore class] fromData:codecData error:&error];
  if (error) {
    NSLog(@"%@", error);
  }
  return object;
}

- (BOOL)storeVideoCodecSetting:(RTCVideoCodecInfo *)videoCodec {
  if (![[self availableVideoCodecs] containsObject:videoCodec]) {
    return NO;
  }
  NSError *error = nil;
  NSData *codecData = [NSKeyedArchiver archivedDataWithRootObject:videoCodec requiringSecureCoding:YES error:&error];
  if (error) {
    NSLog(@"%@", error);
  }
  [[self settingsStore] setVideoCodec:codecData];
  return YES;
}

- (nullable NSNumber *)currentMaxBitrateSettingFromStore {
  [self registerStoreDefaults];
  return [[self settingsStore] maxBitrate];
}

- (void)storeMaxBitrateSetting:(nullable NSNumber *)bitrate {
  [[self settingsStore] setMaxBitrate:bitrate];
}

- (BOOL)currentAudioOnlySettingFromStore {
  return [[self settingsStore] audioOnly];
}

- (void)storeAudioOnlySetting:(BOOL)audioOnly {
  [[self settingsStore] setAudioOnly:audioOnly];
}

- (BOOL)currentCreateAecDumpSettingFromStore {
  return [[self settingsStore] createAecDump];
}

- (void)storeCreateAecDumpSetting:(BOOL)createAecDump {
  [[self settingsStore] setCreateAecDump:createAecDump];
}

- (BOOL)currentUseManualAudioConfigSettingFromStore {
  return [[self settingsStore] useManualAudioConfig];
}

- (void)storeUseManualAudioConfigSetting:(BOOL)useManualAudioConfig {
  [[self settingsStore] setUseManualAudioConfig:useManualAudioConfig];
}

#pragma mark - Testable

- (ARDSettingsStore *)settingsStore {
  if (!_settingsStore) {
    _settingsStore = [[ARDSettingsStore alloc] init];
    [self registerStoreDefaults];
  }
  return _settingsStore;
}

- (int)currentVideoResolutionWidthFromStore {
  NSString *resolution = [self currentVideoResolutionSettingFromStore];

  return [self videoResolutionComponentAtIndex:0 inString:resolution];
}

- (int)currentVideoResolutionHeightFromStore {
  NSString *resolution = [self currentVideoResolutionSettingFromStore];
  return [self videoResolutionComponentAtIndex:1 inString:resolution];
}

#pragma mark -

- (NSString *)defaultVideoResolutionSetting {
  return [self availableVideoResolutions].firstObject;
}

- (RTCVideoCodecInfo *)defaultVideoCodecSetting {
    // For iOS platform there is a hardware accelerated implementation of H264
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", @"H264"];
    RTCVideoCodecInfo * h264Сodec = [[self availableVideoCodecs] filteredArrayUsingPredicate:predicate].firstObject;

    if (h264Сodec != nil) {
        return h264Сodec;
    } else {
        return [self availableVideoCodecs].lastObject;
    }
}

- (int)videoResolutionComponentAtIndex:(int)index inString:(NSString *)resolution {
  if (index != 0 && index != 1) {
    return 0;
  }
  NSArray<NSString *> *components = [resolution componentsSeparatedByString:@"x"];
  if (components.count != 2) {
    return 0;
  }
  return components[index].intValue;
}

- (void)registerStoreDefaults {
  NSError *error = nil;
  NSData *codecData = [NSKeyedArchiver archivedDataWithRootObject:[self defaultVideoCodecSetting] requiringSecureCoding:YES error:&error];
  if (error) {
    NSLog(@"%@", error);
  }
  [ARDSettingsStore setDefaultsForVideoResolution:[self defaultVideoResolutionSetting]
                                       videoCodec:codecData
                                          bitrate:nil
                                        audioOnly:NO
                                    createAecDump:NO
                             useManualAudioConfig:YES];
}

@end
NS_ASSUME_NONNULL_END
