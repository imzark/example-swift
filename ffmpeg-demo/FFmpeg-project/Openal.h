//
//  Openal.h
//  FFmpeg-project
//
//  Created by huizai on 2017/9/22.
//  Copyright © 2017年 huizai. All rights reserved.
//

#ifndef Openal_h
#define Openal_h

#include <stdio.h>
#include <stdlib.h>


int initOpenAL();
int updataQueueBuffer();
void cleanUpOpenAL();
void playSound();
void stopSound();
int openAudioFromQueue(char* data,int dataSize,int aSampleRate,int aBit ,int aChannel);
void SetVolume(float volume);
float GetVolume();

#endif /* Openal_h */

#import<Openal/Openal.h>
