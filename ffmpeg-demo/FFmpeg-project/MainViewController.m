//
//  MainViewController.m
//  FFmpeg-project
//
//  Created by huizai on 2017/10/26.
//  Copyright © 2017年 huizai. All rights reserved.
//

#import "MainViewController.h"
#import "XPlayer.h"

#define WIDTH_SCREEN [[UIScreen mainScreen]bounds].size.width
#define HEIGHT_SCREEN [[UIScreen mainScreen]bounds].size.height

@interface MainViewController (){

    NSArray * arrBtnTitles;
    UIView  * playView;
    XPlayer * player;
    float     playRate;
    float     differ;
    NSString* path;
    int       urlIndex;
    NSArray * arrUrls;
}

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    arrBtnTitles = @[@"播放",@"暂停",@"慢放0.1",@"快放0.1",@"音频提前0.1s",@"视频提前0.1s",@"停止",@"切换视频源"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notiAction:) name:@"EnterBackground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notiAction:) name:@"EnterForeground" object:nil];
    [self initUI];
    char* realPath = "video.mp4";
    NSString * path0 = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:realPath] ofType:nil];
    NSString * path2 = @"http://127.0.0.1/Drop%20Box/1.mkv";
    NSString * path4 = @"rtsp://184.72.239.149/vod/mp4://BigBuckBunny_175k.mov";
    NSString * path5 = @"rtmp://pull-g.kktv8.com/livekktv/100987038";
    NSString * path6 = @"http://221.228.226.5/14/z/w/y/y/zwyyobhyqvmwslabxyoaixvyubmekc/sh.yinyuetai.com/4599015ED06F94848EBF877EAAE13886.mp4";
    arrUrls = @[path0,path2,path4,path6];
    player = [XPlayer sharedPlayer];
   
    playRate = 1.0;
    differ = 0;
    urlIndex = 0;
}


- (void)initUI{
    
    playView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, WIDTH_SCREEN, 230)];
    // playView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:playView];
    
    
    int w=120,h=40;
    int p =(WIDTH_SCREEN-2*w)/3;
    int x= p ,y=260;
    for (int i = 0; i < arrBtnTitles.count; i++) {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(x+ i%2 * (w+p), y + i/2 * (h+p), w, h);
        [btn setTitle:arrBtnTitles[i] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor colorWithRed:0.1 green:0.4 blue:0.6 alpha:1];
        [btn setBackgroundImage:[UIImage imageNamed:@"icon_btn_back"] forState:UIControlStateHighlighted];
        btn.tag = i + 1000;
        [btn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
    
}
- (void)btnAction:(UIButton*)btn{
    int index = (int)(btn.tag - 1000);
    switch (index) {
        case 0:
        { //播放
            [player openUrl:arrUrls[urlIndex%4] andWithPlayView:playView];
            if (![player isStop]) {
                [player play];
            }else{
                [player openUrl:arrUrls[urlIndex%4] andWithPlayView:playView];
                [player play];
            }
        }
            break;
        case 1:
        {//暂停
        
        }
            break;
        case 2:
        {//减速0.1
            playRate -= 0.1;
            player.playRate = playRate;
        }
            break;
        case 3:
        {//加速0.1
            playRate += 0.1;
            player.playRate = playRate;
        }
            break;
        case 4:
        {//音频提前0.1s
            differ += 0.1;
            player.syncRate = differ;
        }
            break;
        case 5:
        {//视频提前0.1s
            differ -= 0.1;
            player.syncRate = differ;
        }
            break;
        case 6:
        {//停止
            [player stop];
        }
            break;
        case 7:
        {//切换
            [player stop];
            urlIndex ++;
            [player openUrl:arrUrls[urlIndex%4] andWithPlayView:playView];
            [player play];
        }
            break;
        default:
            break;
    }
}

- (void)notiAction:(NSNotification*)noti{
    NSString * name = noti.name;
    if ([name isEqualToString:@"EnterBackground"]) {
        [player pause];
    }else
        [player play];
}



@end
