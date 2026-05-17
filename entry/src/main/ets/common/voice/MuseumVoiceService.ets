import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { textToSpeech } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Artifact, mockArtifacts } from '../models/Artifact';

export class MuseumVoiceService {
  private static ttsEngine: textToSpeech.TextToSpeechEngine | null = null;
  private static creatingEngine: Promise<textToSpeech.TextToSpeechEngine> | null = null;

  /**
   * 创建 / 获取 TTS 引擎
   */
  private static async getTtsEngine(): Promise<textToSpeech.TextToSpeechEngine> {
    if (!canIUse('SystemCapability.AI.TextToSpeech')) {
      promptAction.showToast({
        message: '当前设备不支持语音播报'
      });
      throw new Error('当前设备不支持 SystemCapability.AI.TextToSpeech');
    }

    if (MuseumVoiceService.ttsEngine !== null) {
      return MuseumVoiceService.ttsEngine;
    }

    if (MuseumVoiceService.creatingEngine !== null) {
      return MuseumVoiceService.creatingEngine;
    }

    MuseumVoiceService.creatingEngine = new Promise((resolve, reject) => {
      let initParams: textToSpeech.CreateEngineParams = {
        language: 'zh-CN',
        person: 0,
        online: 1,
        extraParams: {
          'style': 'interaction-broadcast',
          'locate': 'CN',
          'name': 'MuseumTtsEngine'
        }
      };

      textToSpeech.createEngine(initParams, (err: BusinessError, engine: textToSpeech.TextToSpeechEngine) => {
        MuseumVoiceService.creatingEngine = null;

        if (err) {
          console.error('[MuseumVoiceService] 创建TTS引擎失败：' + JSON.stringify(err));
          reject(err);
          return;
        }

        MuseumVoiceService.ttsEngine = engine;

        let speakListener: textToSpeech.SpeakListener = {
          onStart(requestId: string, response: textToSpeech.StartResponse) {
            console.info('[MuseumVoiceService] 开始播报：' + requestId + ', ' + JSON.stringify(response));
          },

          onComplete(requestId: string, response: textToSpeech.CompleteResponse) {
            console.info('[MuseumVoiceService] 播报完成：' + requestId + ', ' + JSON.stringify(response));
          },

          onStop(requestId: string, response: textToSpeech.StopResponse) {
            console.info('[MuseumVoiceService] 停止播报：' + requestId + ', ' + JSON.stringify(response));
          },

          onData(requestId: string, audio: ArrayBuffer, response: textToSpeech.SynthesisResponse) {
            console.info('[MuseumVoiceService] 收到音频流：' + requestId + ', ' + JSON.stringify(response));
          },

          onError(requestId: string, errorCode: number, errorMessage: string) {
            console.error('[MuseumVoiceService] 播报错误：' + requestId + ', ' + errorCode + ', ' + errorMessage);
          }
        };

        engine.setListener(speakListener);
        resolve(engine);
      });
    });

    return MuseumVoiceService.creatingEngine;
  }

  /**
   * 真正的语音播报入口
   */
  static async speak(text: string): Promise<void> {
    if (!text || text.trim().length === 0) {
      promptAction.showToast({
        message: '没有可播报的内容'
      });
      return;
    }

    try {
      let engine = await MuseumVoiceService.getTtsEngine();

      // 如果正在播报，先停掉上一段，避免叠音
      try {
        if (engine.isBusy()) {
          engine.stop();
        }
      } catch (error) {
        console.info('[MuseumVoiceService] 停止上一段播报失败，可忽略：' + JSON.stringify(error));
      }

      let finalText = text;
      if (finalText.length > 10000) {
        finalText = finalText.substring(0, 10000);
      }

      let speakParams: textToSpeech.SpeakParams = {
        requestId: 'museum-' + Date.now().toString(),
        extraParams: {
          'queueMode': 0,
          'speed': 1,
          'volume': 2,
          'pitch': 1,
          'languageContext': 'zh-CN',
          'audioType': 'pcm',
          'soundChannel': 3,
          'playType': 1
        }
      };

      engine.speak(finalText, speakParams);

      promptAction.showToast({
        message: '正在播放语音讲解'
      });
    } catch (error) {
      let err = error as BusinessError;
      console.error('[MuseumVoiceService] 语音播放失败：' + JSON.stringify(error));

      promptAction.showToast({
        message: '语音播放失败：' + (err.message || '请检查真机环境')
      });
    }
  }

  /**
   * 停止播放
   */
  static stop(): void {
    try {
      MuseumVoiceService.ttsEngine?.stop();
      promptAction.showToast({
        message: '已停止语音播放'
      });
    } catch (error) {
      console.error('[MuseumVoiceService] 停止播放失败：' + JSON.stringify(error));
    }
  }

  /**
   * 根据文物信息生成讲解词
   */
  static buildArtifactGuide(artifact: Artifact): string {
    return `正在为你讲解${artifact.title}。
它的年代是${artifact.period}，类型是${artifact.type}，材质是${artifact.material}。
当前收藏机构是${artifact.museum}。
${artifact.description}`;
  }

  /**
   * 根据文字搜索文物
   * 这里的 text 后面可以替换成真实语音识别出来的文本
   */
  static searchArtifactByText(text: string): Artifact | null {
    let keyword = text.trim();
    if (keyword.length === 0) {
      return null;
    }

    for (let item of mockArtifacts) {
      if (
        item.title.includes(keyword) ||
          item.period.includes(keyword) ||
          item.type.includes(keyword) ||
          item.material.includes(keyword) ||
          item.museum.includes(keyword) ||
          item.description.includes(keyword)
      ) {
        return item;
      }
    }

    return null;
  }

  /**
   * 处理语音搜索
   */
  static handleVoiceSearch(text: string): void {
    let artifact = MuseumVoiceService.searchArtifactByText(text);

    if (artifact) {
      MuseumVoiceService.speak(`已为你找到${artifact.title}`);

      router.pushUrl({
        url: 'pages/ArtifactDetailPage',
        params: {
          id: artifact.id
        }
      });
    } else {
      MuseumVoiceService.speak('没有找到相关文物，请换一个关键词试试');
    }
  }

  /**
   * 简单语音问答
   */
  static answerQuestion(artifact: Artifact, question: string): string {
    if (question.includes('哪里') || question.includes('在哪') || question.includes('博物馆') || question.includes('收藏')) {
      return `${artifact.title}目前收藏于${artifact.museum}。`;
    }

    if (question.includes('年代') || question.includes('什么时候') || question.includes('朝代')) {
      return `${artifact.title}的年代是${artifact.period}。`;
    }

    if (question.includes('材质') || question.includes('什么做')) {
      return `${artifact.title}的材质是${artifact.material}。`;
    }

    if (question.includes('类型') || question.includes('种类')) {
      return `${artifact.title}属于${artifact.type}。`;
    }

    if (question.includes('介绍') || question.includes('讲讲') || question.includes('是什么')) {
      return MuseumVoiceService.buildArtifactGuide(artifact);
    }

    return `关于${artifact.title}，我可以回答它的年代、类型、材质、收藏博物馆和文物介绍。`;
  }
}