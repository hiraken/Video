//
//  ViewController.m
//  Video
//
//  Created by HIRAMATSU KENJIRO on 2013/07/06.
//  Copyright (c) 2013年 HIRAMATSU KENJIRO. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController{
    AVCaptureSession *CaptureSession;
    AVCaptureMovieFileOutput *MovieFileOutput;
    AVCaptureDeviceInput *VideoInputDevice;
    AVCaptureDevice *VideoDevice;

    
    NSURL *outputURL;
    
    IBOutlet UIButton *btn;
    IBOutlet UILabel *time;
    
    BOOL flash;
    
    BOOL full;
    
    BOOL isPause;
    
    BOOL isFlash;
    
    NSString *tempName;
    

    int sec;
}

@synthesize PreviewLayer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //撮影秒数をリセット
    sec = 0;
    //フラッシュ使用。初期設定は使用しない
    flash = FALSE;
    //画像サイズ。初期設定はフルスクリーン
    full = TRUE;
    
    //現時点ではポーズなし
    isPause = FALSE;
    
    //現時点でフラッシュ可能
    isFlash = TRUE;
    
    // AVCaptureSesstionを作る
    CaptureSession = [[AVCaptureSession alloc] init];
    
    // カメラデバイスを取得する
    VideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (VideoDevice)
    {
        NSError *error;
        // カメラからの入力を作成する
        VideoInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:VideoDevice error:&error];
        if (!error)
        {
            if ([CaptureSession canAddInput:VideoInputDevice])
                // Sessionに追加
                [CaptureSession addInput:VideoInputDevice];
            else
                NSLog(@"Couldn't add video input");
        }
        else
        {
            NSLog(@"Couldn't create video input");
        }
    }
    else
    {
        NSLog(@"Couldn't create video capture device");
    }
    
    // 動画録画なのでAudioデバイスも取得する
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (audioInput)
    {
        // 同じように追加
        // 参考ではこんな感じになってたけど、厳密には上のVideoInputDeviceと同じようにやった方がいいと思う。
        [CaptureSession addInput:audioInput];
    }
    
    // PreviewLayerを設定する
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:CaptureSession]];
    
    //PreviewLayer.orientation = AVCaptureVideoOrientationPortrait;
    // 引き伸ばし方とか設定。ここではアスペクト比が維持されるが、必要に応じてトリミングされる設定を適用
    //画像サイズ。初期設定はフルスクリーン
    [[self PreviewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];

    
    // ファイル用のOutputを作成
    MovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    // sessionに追加
    if ([CaptureSession canAddOutput:MovieFileOutput])
        [CaptureSession addOutput:MovieFileOutput];
    
    // CameraDeviceの設定(後述)
    [self CameraSetOutputProperties];
    
    
    // 画像の質を設定。詳しくはドキュメントを読んでください
    [CaptureSession setSessionPreset:AVCaptureSessionPresetHigh];
    //画像のサイズを指定
    if(full == TRUE){
    //フルスクリーン
    if ([CaptureSession canSetSessionPreset:AVCaptureSessionPreset1280x720])
        [CaptureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    } else {
    //画像サイズ小
        
    if ([CaptureSession canSetSessionPreset:AVCaptureSessionPreset352x288])
        [CaptureSession setSessionPreset:AVCaptureSessionPreset352x288];
    }
    
    CGRect layerRect = [[[self view] layer] bounds];
    [PreviewLayer setBounds:layerRect];
    
    [PreviewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),
                                          CGRectGetMidY(layerRect))];
    
    
    
    // さっきLayerを設定したやつをaddSubviewして貼り付ける
    UIView *CameraView = [[UIView alloc] init];
    [[self view] addSubview:CameraView];
    [self.view sendSubviewToBack:CameraView];
    
    [[CameraView layer] addSublayer:PreviewLayer];
    
    // sessionをスタートさせる
    [CaptureSession startRunning];
    
    [btn addTarget:self action:@selector(Start:) forControlEvents:UIControlEventTouchDown];
    
}

// 呼ばれるhogeメソッド
-(void)hoge:(NSTimer*)timer{
    sec++;
    char szStr[256];
    sprintf(szStr,"%d",sec);
    NSString *str1;
    NSString *str2;
    NSString *str3;
    
   str1 = [[NSString alloc] initWithUTF8String:szStr];
   str2 = @".Sec";
   
    str3 = [str1 stringByAppendingString:str2];
    
    time.text = str3;
}

//iPhoneが逆さまの時以外に画面回転のサポートをする
//iOS6以降
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if(full == FALSE){
    // Return YES for supported orientations.
        return ((interfaceOrientation == UIInterfaceOrientationLandscapeRight) || (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation ==UIInterfaceOrientationPortrait));
    } else {
        return FALSE;
    }
    
}
//iOS6前
#else 
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    if(full == FALSE){
    if(interfaceOrientation == UIInterfaceOrientationPortrait){
        // 通常
        return YES;
    }else if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
        // 左に倒した状態
        return YES;
    }else if(interfaceOrientation == UIInterfaceOrientationLandscapeRight){
        // 右に倒した状態
        return YES;
    }else if(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
        // 逆さまの状態
        return YES;
    } else {
        return (interfaceOrientation == UIDeviceOrientationPortrait);
    }
        
    }
}
#endif

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    WeAreRecording = NO;
}



- (void) CameraSetOutputProperties
{
    // ドキュメントには書いてなかったけど、このConnectionっていうのを貼らないとうまく動いてくれないっぽい
    AVCaptureConnection *CaptureConnection = [MovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    // フルスクリーンのときはPortraitに設定。これはあくまでもカメラ側からファイルへの出力。カメラーロールで再生した時にどの向きであって欲しいかを設定
    if(full == TRUE){
      if ([CaptureConnection isVideoOrientationSupported])
            {
                    AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
                    [CaptureConnection setVideoOrientation:orientation];
            }
    } else {
        if ([CaptureConnection isVideoOrientationSupported])
        {
            AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            [CaptureConnection setVideoOrientation:orientation];
        }
    }
    
    //ここから下はお好みで
    CMTimeShow(CaptureConnection.videoMinFrameDuration);
    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
    
    if (CaptureConnection.supportsVideoMinFrameDuration)
        CaptureConnection.videoMinFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
    if (CaptureConnection.supportsVideoMaxFrameDuration)
        CaptureConnection.videoMaxFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
    
    CMTimeShow(CaptureConnection.videoMinFrameDuration);
    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
}


// カメラ切り替えの時に必要
- (AVCaptureDevice *) CameraWithPosition:(AVCaptureDevicePosition) Position
{
    NSArray *Devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *Device in Devices)
    {
        if ([Device position] == Position)
        {
            return Device;
        }
    }
    return nil;
}



// Camera切り替えアクション
- (IBAction)CameraToggleButtonPressed:(id)sender
{
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1)        //Only do if device has multiple cameras
    {
        NSError *error;
        AVCaptureDeviceInput *NewVideoInput;
        AVCaptureDevicePosition position = [[VideoInputDevice device] position];
        // 今が通常カメラなら顔面カメラに
        if (position == AVCaptureDevicePositionBack)
        {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self CameraWithPosition:AVCaptureDevicePositionFront] error:&error];
            isFlash = FALSE;
        }
        // 今が顔面カメラなら通常カメラに
        else if (position == AVCaptureDevicePositionFront)
        {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self CameraWithPosition:AVCaptureDevicePositionBack] error:&error];
            isFlash = TRUE;
        }
        
        if (NewVideoInput != nil)
        {
            // beginConfiguration忘れずに！
            [CaptureSession beginConfiguration];            // 一度削除しないとダメっぽい
            [CaptureSession removeInput:VideoInputDevice];
            if ([CaptureSession canAddInput:NewVideoInput])
            {
                [CaptureSession addInput:NewVideoInput];
                VideoInputDevice = NewVideoInput;
            }
            else
            {
                [CaptureSession addInput:VideoInputDevice];
            }
            
            //Set the connection properties again
            [self CameraSetOutputProperties];
            
            
            [CaptureSession commitConfiguration];
        }
    }
}




- (IBAction)Start:(UIButton *)sender
{
    if(isPause == FALSE){
        [CaptureSession startRunning];
        //保存する先のパスを作成
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:outputPath])
    {
        NSError *error;
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
        {
            //上書きは基本できないので、あったら削除しないとダメ
        }
    }
    
    //if(isPause == FALSE) {
    // タイマーを作成してスタート
    tm =
    [NSTimer scheduledTimerWithTimeInterval:1.0f
                                     target:self
                                   selector:@selector(hoge:)
                                   userInfo:nil
                                    repeats:YES
     ];
        //録画開始
        [MovieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
    //}
    
    //録画再開
    //[MovieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
    isPause = TRUE;
  //[btn addTarget:self action:@selector(stop:) forControlEvents:UIControlEventTouchCancel];
    
    [btn addTarget:self action:@selector(Stop:) forControlEvents:UIControlEventTouchUpInside];
    [btn addTarget:self action:@selector(Stop:) forControlEvents:UIControlEventTouchUpOutside];
    }
}

- (IBAction)Stop:(UIButton *)sender{
    if(isPause == TRUE){
    [CaptureSession stopRunning];
    
        //[tm invalidate];
        [MovieFileOutput stopRecording];
        isPause = TRUE;
    }
    
}

-(void)viewDidDisappear:(BOOL)animated{
   
    //撮影ストップ
    [MovieFileOutput stopRecording];
    
    sec = 0;
    
}

/*
*/

- (IBAction)Flash:(id)sender{
    if(isFlash == TRUE){
    NSError *error = nil;
    //AVCaptureDevice *dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:dev error:&error];
    VideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    VideoInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:VideoDevice error:&error];
    
    AVCaptureMovieFileOutput *movieFileOutput;
    
    [VideoDevice lockForConfiguration:&error];
    
    if(flash == FALSE){
        VideoDevice.torchMode = AVCaptureTorchModeOn;
        [VideoDevice unlockForConfiguration];
        
        AVCaptureSession *captureSession_;
        
        [captureSession_ beginConfiguration];
        if ([captureSession_ canAddInput:VideoInputDevice]) {
            [captureSession_ addInput:VideoInputDevice];
        }
        if ([captureSession_ canAddOutput:movieFileOutput]) {
            [captureSession_ addOutput:movieFileOutput];
        }
        captureSession_.sessionPreset = AVCaptureSessionPresetLow;
        [captureSession_ commitConfiguration];
        flash = TRUE;
    } else {
        VideoDevice.torchMode = AVCaptureTorchModeOff;
        [VideoDevice unlockForConfiguration];
        
        AVCaptureSession *captureSession_;
        
        [captureSession_ beginConfiguration];
        if ([captureSession_ canAddInput:VideoInputDevice]) {
            [captureSession_ addInput:VideoInputDevice];
        }
        if ([captureSession_ canAddOutput:movieFileOutput]) {
            [captureSession_ addOutput:movieFileOutput];
        }
        captureSession_.sessionPreset = AVCaptureSessionPresetLow;
        [captureSession_ commitConfiguration];
        flash = FALSE;
    }
    }
}

- (IBAction)Full:(id)sender{
    if(full == TRUE){
        full = FALSE;
        [[self PreviewLayer] setVideoGravity:AVLayerVideoGravityResizeAspect];
        if ([CaptureSession canSetSessionPreset:AVCaptureSessionPreset352x288])
            [CaptureSession setSessionPreset:AVCaptureSessionPreset352x288];
    } else {
        full = TRUE;
        [[self PreviewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        if ([CaptureSession canSetSessionPreset:AVCaptureSessionPreset1280x720])
            [CaptureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }
}


+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize

{
    
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    
    
    CGSize size = CGSizeZero;
    
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        
        if (viewRatio > apertureRatio) {
            
            size.width = frameSize.width;
            
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
            
        } else {
            
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            
            size.height = frameSize.height;
            
        }
        
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        
        if (viewRatio > apertureRatio) {
            
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
       
            size.height = frameSize.height;
        
        } else {
           
            size.width = frameSize.width;
            
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        
        }
        
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        
        size.width = frameSize.width;
        
        size.height = frameSize.height;
        
    }
    
    
    
    CGRect videoBox;
    
    videoBox.size = size;
    
    if (size.width < frameSize.width)
        
        videoBox.origin.x = (frameSize.width - size.width) / 2;
    
    else
        
        videoBox.origin.x = (size.width - frameSize.width) / 2;
    
    
    
    if ( size.height < frameSize.height )
        
        videoBox.origin.y = (frameSize.height - size.height) / 2;
    
    else
        
        videoBox.origin.y = (size.height - frameSize.height) / 2;
    
    
    
    return videoBox;
    
}

/*
- (BOOL)isRecording
{
	return [[self movieFileOutput] isRecording];
}


- (void)setRecording:(BOOL)record
{
	if (record) {
		// Record to a temporary file, which the user will relocate when recording is finished
		char *tempNameBytes = tempnam([NSTemporaryDirectory() fileSystemRepresentation], "AVRecorder_");
		[tempName initWithBytesNoCopy:tempNameBytes length:strlen(tempNameBytes) encoding:NSUTF8StringEncoding freeWhenDone:YES];
		
		[MovieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[tempName stringByAppendingPathExtension:@"mov"]]
											recordingDelegate:self];
	} else {
		[MovieFileOutput stopRecording];
	}
}
*/

#pragma mark - Delegate methods
/*
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
	NSLog(@"Did start recording to %@", [fileURL description]);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didPauseRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
	[CaptureSession stopRunning];
    NSLog(@"Did pause recording to %@", [fileURL description]);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didResumeRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
	[CaptureSession stopRunning];
    NSLog(@"Did resume recording to %@", [fileURL description]);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput willFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections dueToError:(NSError *)error
{
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self presentError:error];
	});
}
*/

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error
{
    
    BOOL RecordedSuccessfully = YES;
    if ([error code] != noErr)
    {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
        {
            RecordedSuccessfully = [value boolValue];
        }
    }
    if (RecordedSuccessfully)
    {
        //書き込んだのは/tmp以下なのでカメラーロールの下に書き出す
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL])
        {
            [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
                                        completionBlock:^(NSURL *assetURL, NSError *error)
             {
                 if (error)
                 {
                     
                 }
             }];
        }
        
    }
}

- (BOOL)captureOutputShouldProvideSampleAccurateRecordingStart:(AVCaptureOutput *)captureOutput
{
    // We don't require frame accurate start when we start a recording. If we answer YES, the capture output
    // applies outputSettings immediately when the session starts previewing, resulting in higher CPU usage
    // and shorter battery life.
    return NO;
}


@end
