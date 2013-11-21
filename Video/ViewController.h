//
//  ViewController.h
//  Video
//
//  Created by HIRAMATSU KENJIRO on 2013/07/06.
//  Copyright (c) 2013年 HIRAMATSU KENJIRO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

#import <AssetsLibrary/AssetsLibrary.h>
#define CAPTURE_FRAMES_PER_SECOND       20

@interface ViewController : UIViewController
<AVCaptureFileOutputRecordingDelegate>
{
    BOOL WeAreRecording;
    
    NSTimer *tm;
    
}

@property (retain) AVCaptureVideoPreviewLayer *PreviewLayer;



- (void) CameraSetOutputProperties;
- (AVCaptureDevice *) CameraWithPosition:(AVCaptureDevicePosition) Position;

// 録画を始めるイベント
- (IBAction)Start:(UIButton *)sender;
//録画をストップするイベント
- (IBAction)Stop:(UIButton *)sender;

// Back CameraとFront Cameraを切り替えるイベント
- (IBAction)CameraToggleButtonPressed:(id)sender;
//フラッシュを操作するイベント
- (IBAction)Flash:(id)sender;
//画像サイズを操作するイベント
- (IBAction)Full:(id)sender;

@end