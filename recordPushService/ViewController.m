//
//  ViewController.m
//  recordPushService
//
//  Created by apple on 2019/5/8.
//  Copyright © 2019年 apple. All rights reserved.
//  AudioRecordDemo

#import "ViewController.h"

#import "CDPAudioRecorder.h"//引入.h文件

#import "LameTool.h"

#import "AFNetworking/AFNetworking.h"



@interface ViewController ()<CDPAudioRecorderDelegate> {
    
    
    UIImageView *_imageView;//音量图片
    UIButton *_recordBt;//录音bt
    UIButton *_playBt;//播放bt
    
    UIButton *_uploadBt;//上传bt
    
}

@property (nonatomic, strong)CDPAudioRecorder *recorder;//recorder对象

@property (nonatomic, strong) NSString *audioString;

@end

@implementation ViewController

- (void)dealloc{
    //结束播放
    [_recorder stopPlaying];
    //结束录音
    [_recorder stopRecording];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor= [UIColor whiteColor];

    
    //详情请看CDPAudioRecorder.h文件
    //初始化录音recorder
    _recorder = [CDPAudioRecorder shareRecorder];
    _recorder.delegate = self;
    
    //创建UI
    [self createUI];
    
    ///api/mobile/wodedayiban/uploadmp3.php
}

- (void)createUI {
    //音量图片
    _imageView=[[UIImageView alloc] initWithFrame:CGRectMake(80,150,64,64)];
    _imageView.image=[UIImage imageNamed:@"mic_0"];
    [self.view addSubview:_imageView];
    
    //录音bt
    _recordBt=[[UIButton alloc] initWithFrame:CGRectMake(52,230,120,40)];
    [_recordBt setTitle:@"按住 说话" forState:UIControlStateNormal];
    [_recordBt setTitle:@"松开 结束" forState:UIControlStateHighlighted];
    [_recordBt setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_recordBt setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    _recordBt.backgroundColor=[UIColor cyanColor];
    [_recordBt addTarget:self action:@selector(startRecord:) forControlEvents:UIControlEventTouchDown];
    [_recordBt addTarget:self action:@selector(endRecord:) forControlEvents:UIControlEventTouchUpInside];
    [_recordBt addTarget:self action:@selector(cancelRecord:) forControlEvents:UIControlEventTouchDragExit];
    _recordBt.layer.cornerRadius = 10;
    [self.view addSubview:_recordBt];
    
    //播放bt
    _playBt=[[UIButton alloc] initWithFrame:CGRectMake(190,230,80,40)];
    _playBt.adjustsImageWhenHighlighted=NO;
    [_playBt setTitle:@"播 放" forState:UIControlStateNormal];
    [_playBt setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    _playBt.layer.cornerRadius = 10;
    _playBt.backgroundColor=[UIColor yellowColor];
    [_playBt addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_playBt];
    
    
    _uploadBt = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(_recordBt.frame), CGRectGetMaxY(_recordBt.frame) + 30, 200, 40)];
    [_uploadBt setTitle:@"上传" forState:UIControlStateNormal];
    [_uploadBt setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [_uploadBt addTarget:self action:@selector(uploadButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_uploadBt setBackgroundColor:[UIColor orangeColor]];
    [self.view addSubview:_uploadBt];
    
}

#pragma mark--上传mp3
- (void)uploadButtonAction:(id)sender {
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    
    NSMutableArray* result = [NSMutableArray array];
    
    NSData *audioData = [NSData dataWithContentsOfFile:self.audioString];
 
        dispatch_group_enter(group);
        NSURLSessionUploadTask* uploadTask = [self uploadTaskWithAudioData:audioData AndTag:1 completion:^(NSURLResponse *response, id responseObject, NSError *error) {
            if (error) {
                
                @synchronized (result) { // NSMutableArray 是线程不安全的，所以加个同步锁
                    result[0] = @{@"code":@"1500"};
                }
                NSLog(@"图片上传失败: %@", error);
                dispatch_group_leave(group);
            } else {
                //                NSLog(@"第 %d 张图片上传成功: %@", (int)i + 1, responseObject);
                @synchronized (result) { // NSMutableArray 是线程不安全的，所以加个同步锁
                    NSString *jsonS = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
                    
//                    NSString *decryptionStr = [NSString decrypt:jsonS];
//                    DLog(@"decryptionStr == %@",decryptionStr);
//                    WXLoginList *model = [WXLoginList mj_objectWithKeyValues:decryptionStr];
//                    NSString *imageNames = [model.data objectForKey:@"picname"];
//                    //                    WXLoginList *list = [];
//                    [self.imageNamesArray addObject:imageNames];
//                    result[i] = imageNames;
                    
                    
                }
                dispatch_group_leave(group);
            }
        }];
    
        [uploadTask resume];
    


    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"上传完成!result:%@", result);
        
        // 如果最后一个元素请求过后，就不会为null
        if (![[result lastObject] isKindOfClass:[NSNull class]]) {
           
            
        }
        
    });
    
}

- (NSURLSessionUploadTask*)uploadTaskWithAudioData:(NSData*)audioData AndTag:(NSInteger)tag completion:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionBlock {
    // 构造 NSURLRequest
    NSError* error = NULL;
    
    // 这里是上传音频的接口地址，这里已被我删除，请用你们公司自己的接口地址
    NSString *requetString = [NSString stringWithFormat:@"%@/uploadmp3.php",@"http://www.dujiaoshou.com"];
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:requetString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
//        NSData* imageData = UIImageJPEGRepresentation(image, 1.0);
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmm";
        NSString *str = [formatter stringFromDate:[NSDate date]];
        NSString *fileName = [NSString stringWithFormat:@"%@%ld.mp3", str,tag];
        NSLog(@"fileName == %@",fileName);
        [formData appendPartWithFileData:audioData name:@"file" fileName:fileName mimeType:@"mp3/amr/wav/wmr"];//
        
    } error:&error];
    // 可在此处配置验证信息
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json",@"text/html",@"text/javascript", nil];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } completionHandler:completionBlock];
    
    return uploadTask;
    
}


//alertView提示
-(void)alertWithMessage:(NSString *)message{
    UIAlertView *alertView=[[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alertView show];
}



#pragma mark - CDPAudioRecorderDelegate代理事件
//更新音量分贝数峰值(0~1)
-(void)updateVolumeMeters:(CGFloat)value{
    NSInteger no=0;
    
    if (value>0&&value<=0.14) {
        no = 1;
    } else if (value<= 0.28) {
        no = 2;
    } else if (value<= 0.42) {
        no = 3;
    } else if (value<= 0.56) {
        no = 4;
    } else if (value<= 0.7) {
        no = 5;
    } else if (value<= 0.84) {
        no = 6;
    } else{
        no = 7;
    }
    
    NSString *imageName = [NSString stringWithFormat:@"mic_%ld",(long)no];
    _imageView.image = [UIImage imageNamed:imageName];
}

//录音结束(url为录音文件地址,isSuccess是否录音成功)
- (void)recordFinishWithUrl:(NSString *)url isSuccess:(BOOL)isSuccess{
    //url为得到的caf录音文件地址,可直接进行播放,也可进行转码为amr上传服务器
    NSLog(@"录音完成,文件地址:%@",url);
    
    // 在此处转化为mp3文件
    
    
    //return;
    
    
    [NSThread detachNewThreadSelector:@selector(audio_PCMtoMP3) toTarget:self withObject:nil];
    
    
    // 沙盒文件路径
    //如果需要将得到的caf录音文件进行转码为amr格式,可按照以下步骤转码
    //生成amr文件将要保存的路径
//    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//    NSString *filePath = [path stringByAppendingPathComponent:@"CDPAudioFiles/CDPAudioRecord.amr"];
//
//    //caf转码为amr格式
//    [CDPAudioRecorder convertCAFtoAMR:[NSURL URLWithString:url].path savePath:filePath];
    

    
}

- (void)audio_PCMtoMP3 {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [path stringByAppendingPathComponent:@"CDPAudioFiles/CDPAudioRecord.caf"];
    NSString *audioPath = [LameTool audioToMP3:filePath isDeleteSourchFile:NO];
    if ([audioPath isEqualToString:@"fail"]) {
        NSLog(@"上传失败");
    } else {
        self.audioString = audioPath;
        [_recorder setRecordURL:[NSURL URLWithString:audioPath]];
    }
    NSLog(@"转码amr格式成功----文件地址为:%@",filePath);
}

#pragma mark - 各录音点击事件
//按下开始录音
-(void)startRecord:(UIButton *)recordBtn {
    [_recorder startRecording];
}

//点击松开结束录音
-(void)endRecord:(UIButton *)recordBtn {
    double currentTime=_recorder.recorder.currentTime;
    NSLog(@"本次录音时长%lf",currentTime);
    if (currentTime<1) {
        //时间太短
        _imageView.image = [UIImage imageNamed:@"mic_0"];
        [self alertWithMessage:@"说话时间太短"];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self->_recorder stopRecording];
            [self->_recorder deleteAudioFile];
        });
    }
    else{
        //成功录音
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self->_recorder stopRecording];
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_imageView.image=[UIImage imageNamed:@"mic_0"];
            });
        });
        NSLog(@"已成功录音");
    }
}


//手指从按钮上移除,取消录音
-(void)cancelRecord:(UIButton *)recordBtn{
    _imageView.image = [UIImage imageNamed:@"mic_0"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self->_recorder stopRecording];
        [self->_recorder deleteAudioFile];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertWithMessage:@"已取消录音"];
        });
    });
    
}

#pragma mark - 播放点击事件
//播放录音
- (void)play{
    //播放内部默认地址刚才生成的本地录音文件,不需要转码
    [_recorder playAudioFile];
    
    return;
    
    //如果需要播放amr文件,按照以下步骤转码保存播放
    //获取转换后的amr文件路径
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [path stringByAppendingPathComponent:@"CDPAudioFiles/CDPAudioRecord.amr"];
    
    //amr转码为caf可播放格式
    NSString *savefilePath = [path stringByAppendingPathComponent:@"CDPAudioFiles/CDPAudioRecord222.caf"];
    
    //转换格式
    [CDPAudioRecorder convertAMRtoWAV:filePath savePath:savefilePath];
    
    //播放
    [[CDPAudioRecorder shareRecorder] playAudioWithUrl:[NSURL fileURLWithPath:savefilePath].absoluteString];
    
}


@end
