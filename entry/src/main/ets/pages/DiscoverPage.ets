import promptAction from '@ohos.promptAction';
import { MuseumVoiceService } from '../common/voice/MuseumVoiceService';
import picker from '@ohos.file.picker';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import router from '@ohos.router';

/**
 * 文物条目类型定义
 */
interface ArtifactItem {
  id: number;
  name: string;
  era: string;
  image: string;
  similarity: number;
}

/**
 * 路由参数类型
 */
interface RouterParams {
  image: string;
  results: string;
}

/**
 * 路由配置类型
 */
interface RouterOptions {
  url: string;
  params: RouterParams;
}

@Entry
@Component
export struct DiscoverPage {
  // 搜索输入
  @State searchInput: string = '';
  // 语音识别文本
  @State voiceText: string = '';
  // 选中的图片
  @State selectedImage: string = '';

  // 模拟文物数据
  private readonly mockArtifacts: ArtifactItem[] = [
    {
      id: 1,
      name: '青花瓷瓶',
      era: '明代',
      image: 'https://img2.baidu.com/it/u=3871232861,3188699794&fm=253&fmt=auto',
      similarity: 0
    },
    {
      id: 2,
      name: '唐三彩马',
      era: '唐代',
      image: 'https://img2.baidu.com/it/u=3103356365,1527751139&fm=253&fmt=auto',
      similarity: 0
    },
    {
      id: 3,
      name: '玉琮',
      era: '良渚文化',
      image: 'https://img1.baidu.com/it/u=1679148656,2910535149&fm=253&fmt=auto',
      similarity: 0
    },
    {
      id: 4,
      name: '青铜鼎',
      era: '商代',
      image: 'https://img0.baidu.com/it/u=4119932281,1072797093&fm=253&fmt=auto',
      similarity: 0
    }
  ];

  /**
   * 统一申请权限
   */
  async requestPermissions(): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    const permissions: Array<Permissions> = ['ohos.permission.CAMERA', 'ohos.permission.READ_MEDIA'];
    const context = getContext(this) as common.UIAbilityContext;

    try {
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      const isAllGranted = result.authResults.every(item => item === 0);

      if (!isAllGranted) {
        promptAction.showToast({ message: '权限被拒绝' });
      }
      return isAllGranted;
    } catch (err) {
      promptAction.showToast({ message: '权限申请失败' });
      return false;
    }
  }

  /**
   * 拍照搜索
   */
  async openCamera() {
    if (!await this.requestPermissions()) return;

    try {
      this.selectedImage = 'camera_mock_image';
      promptAction.showToast({ message: '拍照成功' });
      this.startImageSearch();
    } catch (err) {
      promptAction.showToast({ message: '打开相机失败' });
    }
  }

  /**
   * 相册选择图片
   */
  async openAlbum() {
    if (!await this.requestPermissions()) return;

    try {
      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });

      if (result.photoUris.length > 0) {
        this.selectedImage = result.photoUris[0];
        promptAction.showToast({ message: '图片选择成功' });
        this.startImageSearch();
      }
    } catch (err) {
      promptAction.showToast({ message: '选择图片失败' });
    }
  }

  /**
   * 模拟以图搜图逻辑
   */
  startImageSearch() {
    const resultList: ArtifactItem[] = [];

    for (let i = 0; i < 3; i++) {
      const item = this.mockArtifacts[i];
      const resultItem: ArtifactItem = {
        id: item.id,
        name: item.name,
        era: item.era,
        image: item.image,
        similarity: Math.floor(Math.random() * 36) + 60
      };
      resultList.push(resultItem);
    }

    const routerOptions: RouterOptions = {
      url: 'pages/ImageSearchResultPage',
      params: {
        image: this.selectedImage,
        results: JSON.stringify(resultList)
      }
    };

    router.pushUrl(routerOptions);
  }

  build() {
    Column() {
      // 页面标题（整体上移）
      Column({ space: 4 }) {
        Text('发现')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827');


      }
      .margin({ top: 20, bottom: 16 });

      // 语音搜索卡片
      this.voiceSearchCard();

      // 以图搜图卡片
      this.imageSearchCard();

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
    .alignItems(HorizontalAlign.Center);
  }

  /**
   * 语音搜索模块（标题与按钮同行，与以图搜图严格对齐）
   */
  @Builder
  voiceSearchCard() {
    Column({ space: 16 }) {
      // 标题行：语音搜索 + 语音提示（与以图搜图标题完全对齐）
      Row() {
        Text('语音搜索')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827');

        Button('🎧 语音提示')
          .width(92)
          .height(32)
          .fontSize(12)
          .backgroundColor('#E5E7EB')
          .fontColor('#374151')
          .borderRadius(16)
          .margin({ left: 12 })
          .onClick(() => {
            MuseumVoiceService.speak('欢迎使用掌上博物馆语音搜索，请说出你想查找的文物名称、年代、类型或博物馆名称。');
          });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      Text('支持关键词：青花、唐三彩、玉琮、青铜、大英博物馆')
        .fontSize(13)
        .fontColor('#9CA3AF')
        .alignSelf(ItemAlign.Start);

      TextInput({ placeholder: '请输入或说出文物名称、年代、博物馆...' })
        .width('100%')
        .height(50)
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#D1D5DB' })
        .borderRadius(12)
        .padding({ left: 16 })
        .onChange(value => this.searchInput = value);

      Button('🎙️ 开始语音搜索')
        .width('100%')
        .height(50)
        .backgroundColor('#007AFF')
        .borderRadius(12)
        .onClick(() => {
          if (!this.searchInput.trim()) {
            promptAction.showToast({ message: '请输入或说出搜索内容' });
            return;
          }
          this.voiceText = this.searchInput;
          MuseumVoiceService.handleVoiceSearch(this.voiceText);
        });

      if (this.voiceText) {
        Text(`✅ 识别结果：${this.voiceText}`)
          .fontSize(15)
          .fontColor('#059669')
          .alignSelf(ItemAlign.Start)
          .margin({ top: 4 });
      }
    }
    .width('92%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .shadow({ radius: 6, color: '#0000000A', offsetX: 0, offsetY: 2 });
  }

  /**
   * 以图搜图模块（与语音搜索严格左对齐）
   */
  @Builder
  imageSearchCard() {
    Column({ space: 16 }) {
      // 标题行：与上方语音搜索标题完全对齐
      Text('以图搜图')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')
        .alignSelf(ItemAlign.Start);

      Button('📷 拍照搜索文物')
        .width('100%')
        .height(54)
        .backgroundColor('#F97316')
        .borderRadius(12)
        .onClick(async () => await this.openCamera());

      Button('🖼️ 从相册选择图片')
        .width('100%')
        .height(54)
        .backgroundColor('#8B5CF6')
        .borderRadius(12)
        .onClick(async () => await this.openAlbum());

      if (this.selectedImage) {
        Text('✅ 已选择图片')
          .fontSize(14)
          .fontColor('#059669')
          .alignSelf(ItemAlign.Start);
      }
    }
    .width('92%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .margin({ top: 16 })
    .shadow({ radius: 6, color: '#0000000A', offsetX: 0, offsetY: 2 });
  }
}