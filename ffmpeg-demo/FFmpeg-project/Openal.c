//
//  Openal.c
//  FFmpeg-project
//
//  Created by huizai on 2017/9/22.
//  Copyright © 2017年 huizai. All rights reserved.
//

#include "Openal.h"


int m_numprocessed;             //队列中已经播放过的数量
int m_numqueued;                //队列中缓冲队列数量
long long m_IsplayBufferSize;   //已经播放了多少个音频缓存数目
double m_oneframeduration;      //一帧音频数据持续时间(ms)
float m_volume;                 //当前音量volume取值范围(0~1)
int m_samplerate;               //采样率
int m_bit;                      //样本值
int m_channel;                  //声道数
int m_datasize;                 //一帧音频数据量
ALCdevice * m_Devicde;          //device句柄
ALCcontext * m_Context;         //device context
ALuint m_outSourceId;           //source id 负责播放

int initOpenAL(){
    
    
    int ret = 0;
    
    printf("=======initOpenAl===\n");
    m_Devicde = alcOpenDevice(NULL);
    if (m_Devicde)
    {
        //建立声音文本描述
        m_Context = alcCreateContext(m_Devicde, NULL);
        
        //设置行为文本描述
        alcMakeContextCurrent(m_Context);
    }else
        ret = -1;
    
    //创建一个source并设置一些属性
    alGenSources(1, &m_outSourceId);
    alSpeedOfSound(1.0);
    alDopplerVelocity(1.0);
    alDopplerFactor(1.0);
    alSourcef(m_outSourceId, AL_PITCH, 1.0f);
    alSourcef(m_outSourceId, AL_GAIN, 1.0f);
    alSourcei(m_outSourceId, AL_LOOPING, AL_FALSE);
    alSourcef(m_outSourceId, AL_SOURCE_TYPE, AL_STREAMING);
    
    return ret;
}

int openAudioFromQueue(char* data,int dataSize,int aSampleRate,int aBit ,int aChannel)
{
    int ret = 0;
    //样本数openal的表示方法
    ALenum format = 0;
    //buffer id 负责缓存,要用局部变量每次数据都是新的地址
    ALuint bufferID = 0;
    
    if (m_datasize == 0 &&
        m_samplerate == 0 &&
        m_bit == 0 &&
        m_channel == 0)
    {
        if (dataSize != 0 &&
            aSampleRate != 0 &&
            aBit != 0 &&
            aChannel != 0)
        {
            m_datasize = dataSize;
            m_samplerate = aSampleRate;
            m_bit = aBit;
            m_channel = aChannel;
            m_oneframeduration = m_datasize * 1.0 /(m_bit/8) /m_channel /m_samplerate * 1000 ;   //计算一帧数据持续时间
        }
    }
    
    //创建一个buffer
    alGenBuffers(1, &bufferID);
    if((ret = alGetError()) != AL_NO_ERROR)
    {
        printf("error alGenBuffers %x \n", ret);
        // printf("error alGenBuffers %x : %s\n", ret,alutGetErrorString (ret));
        //AL_ILLEGAL_ENUM
        //AL_INVALID_VALUE
        //#define AL_ILLEGAL_COMMAND                        0xA004
        //#define AL_INVALID_OPERATION                      0xA004
    }
    
    if (aBit == 8)
    {
        if (aChannel == 1)
        {
            format = AL_FORMAT_MONO8;
        }
        else if(aChannel == 2)
        {
            format = AL_FORMAT_STEREO8;
        }
    }
    
    if( aBit == 16 )
    {
        if( aChannel == 1 )
        {
            format = AL_FORMAT_MONO16;
        }
        if( aChannel == 2 )
        {
            format = AL_FORMAT_STEREO16;
        }
    }
    //指定要将数据复制到缓冲区中的数据
    alBufferData(bufferID, format, data, dataSize,aSampleRate);
    if((ret = alGetError()) != AL_NO_ERROR)
    {
        printf("error alBufferData %x\n", ret);
        //AL_ILLEGAL_ENUM
        //AL_INVALID_VALUE
        //#define AL_ILLEGAL_COMMAND                        0xA004
        //#define AL_INVALID_OPERATION                      0xA004
    }
    //附加一个或一组buffer到一个source上
    alSourceQueueBuffers(m_outSourceId, 1, &bufferID);
    if((ret = alGetError()) != AL_NO_ERROR)
    {
        printf("error alSourceQueueBuffers %x\n", ret);
    }
    
    //更新队列数据
    ret = updataQueueBuffer();
    
    //删除一个缓冲 这里不应该删除缓冲，在source里面播放完毕删除
    //alDeleteBuffers(1, &bufferID);
    bufferID = 0;
    
    return 1;
}

void cleanUpOpenAL(){
    
    printf("=======cleanUpOpenAL===\n");
    alDeleteSources(1, &m_outSourceId);
    
    ALCcontext * Context = alcGetCurrentContext();
    // ALCdevice * Devicde = alcGetContextsDevice(Context);
    
    if (Context)
    {
        alcMakeContextCurrent(NULL);
        alcDestroyContext(Context);
        m_Context = NULL;
    }
    alcCloseDevice(m_Devicde);
    m_Devicde = NULL;
}


void playSound()
{
    int ret = 0;
    alSourcePlay(m_outSourceId);
    if((ret = alGetError()) != AL_NO_ERROR)
    {
        printf("error alcMakeContextCurrent %x\n", ret);
    }
}

void stopSound()
{
    alSourceStop(m_outSourceId);
}

void SetVolume(float volume)//volume取值范围(0~1)
{
    m_volume = volume;
    alSourcef(m_outSourceId,AL_GAIN,volume);
}

float GetVolume()
{
    return m_volume;
}

int updataQueueBuffer()
{
    //播放状态字段
    ALint stateVaue = 0;
    
    //获取处理队列，得出已经播放过的缓冲器的数量
    alGetSourcei(m_outSourceId, AL_BUFFERS_PROCESSED, &m_numprocessed);
    //获取缓存队列，缓存的队列数量
    alGetSourcei(m_outSourceId, AL_BUFFERS_QUEUED, &m_numqueued);
    
    //获取播放状态，是不是正在播放
    alGetSourcei(m_outSourceId, AL_SOURCE_STATE, &stateVaue);
    
    //printf("===statevaue ========================%x\n",stateVaue);
    
    if (stateVaue == AL_STOPPED ||
        stateVaue == AL_PAUSED ||
        stateVaue == AL_INITIAL)
    {
        //如果没有数据,或数据播放完了
        if (m_numqueued < m_numprocessed || m_numqueued == 0 ||(m_numqueued == 1 && m_numprocessed ==1))
        {
            //停止播放
            printf("...Audio Stop\n");
            stopSound();
            cleanUpOpenAL();
            return 0;
        }
        
        if (stateVaue != AL_PLAYING)
        {
            playSound();
        }
    }
    
    //将已经播放过的的数据删除掉
    while(m_numprocessed --)
    {
        ALuint buff;
        //更新缓存buffer中的数据到source中
        alSourceUnqueueBuffers(m_outSourceId, 1, &buff);
        //删除缓存buff中的数据
        alDeleteBuffers(1, &buff);
        
        //得到已经播放的音频队列多少块
        m_IsplayBufferSize ++;
    }
    long long time = (long long )((m_IsplayBufferSize * m_oneframeduration) + 0.5);
    //printf("*****m_IsplayBufferSize : %ld",m_IsplayBufferSize);
    //printf("****************time : %ld(ms)\n",time);
    return 1;
}
