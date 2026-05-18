
import router from '@ohos.router';
import { Artifact, mockArtifacts } from '../common/models/Artifact';
import promptAction from '@ohos.promptAction';
import { MuseumVoiceService } from '../common/voice/MuseumVoiceService';
import { CommentItem, InteractionSummary } from '../common/models/InteractionModels';
import { interactionStore } from '../common/store/InteractionStore';
import { formatDateTime, formatReviewColor, formatReviewStatus } from '../common/utils/InteractionFormatUtil';
import { pickSingleImageUri } from '../common/utils/PhotoPickerUtil';

// 关联实体接口
interface RelatedEntity {
  title: string;
  id: string;
}

@Entry
@Component
export struct ArtifactDetailPage {
  @StorageLink('isLogin') isLogin: boolean = false;
  @StorageLink('username') username: string = '';
  @State artifact: Artifact | null = null;
  @State likeSummary: InteractionSummary = { active: false, count: 0 };
  @State favoriteSummary: InteractionSummary = { active: false, count: 0 };
  @State comments: CommentItem[] = [];
  @State commentInput: string = '';
  @State isSubmittingComment: boolean = false;
  @State isUploadingPhoto: boolean = false;
  private artifactId: string = '';

  // 手势缩放
  @State scaleValue: number = 1;
  @State offsetX: number = 0;
  @State offsetY: number = 0;

  // 关联实体与推荐
  @State relatedEntities: RelatedEntity[] = [];
  @State relatedList: Artifact[] = [];
  @State currentImageIndex: number = 0;

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    // 兼容两种参数名
    const id = params ? (params['objectId'] || params['id']) : undefined;
    if (id) {
      this.artifactId = id;
      const found = mockArtifacts.find(item => item.id === this.artifactId);
      this.artifact = found || null;
      if (this.artifact) {
        // 同时执行两边的初始化逻辑
        this.loadRelatedData();        // 关联推荐
        this.initInteractionData();    // 交互数据
      }
    }
  }

  // ===== 加载关联数据 =====
  private loadRelatedData() {
    if (!this.artifact) return;

    this.relatedEntities = mockArtifacts
      .filter(a => a.period === this.artifact!.period && a.id !== this.artifact!.id)
      .map(a => ({ title: a.title, id: a.id } as RelatedEntity));

    this.relatedList = mockArtifacts
      .filter(a => a.id !== this.artifact!.id &&
        (a.period === this.artifact!.period || a.type === this.artifact!.type))
      .slice(0, 4);
  }

  // ===== 交互数据初始化 =====
  private resolveActor(): string {
    if (this.isLogin && this.username) {
      return this.username;
    }
    return '访客';
  }

  private async initInteractionData() {
    if (!this.artifact) {
      return;
    }
    const actor = this.resolveActor();
    if (this.isLogin && this.username) {
      await interactionStore.recordHistory(this.artifact, this.username);
    }
    await this.refreshInteractionState(actor);
  }

  private async refreshInteractionState(actor: string = this.resolveActor()) {
    if (!this.artifact) {
      return;
    }
    this.likeSummary = await interactionStore.getLikeSummary(this.artifact.id, actor);
    this.favoriteSummary = await interactionStore.getFavoriteSummary(this.artifact.id, actor);
    this.comments = await interactionStore.getCommentsForArtifact(this.artifact.id);
  }

  build() {
    Column() {
      if (this.artifact) {
        Scroll() {
          Column() {
            // ===== 图片区域（手势缩放功能） =====
            Stack() {
              Image(this.artifact.imageUrl)
                .width('100%')
                .height(400)
                .objectFit(ImageFit.Cover)
                .backgroundColor('#CCCCCC')
                .alt($r('app.media.startIcon'))
                .scale({ x: this.scaleValue, y: this.scaleValue })
                .offset({ x: this.offsetX, y: this.offsetY })
                .gesture(
                  GestureGroup(GestureMode.Parallel,
                    PinchGesture()
                      .onActionUpdate((event: GestureEvent) => {
                        this.scaleValue = event.scale;
                      })
                      .onActionEnd(() => {
                        if (this.scaleValue < 0.5) this.scaleValue = 0.5;
                        if (this.scaleValue > 3) this.scaleValue = 3;
                      }),
                    PanGesture({ fingers: 2 })
                      .onActionUpdate((event: GestureEvent) => {
                        this.offsetX = event.offsetX;
                        this.offsetY = event.offsetY;
                      })
                  )
                )

              Text(`${this.currentImageIndex + 1}/1`)
                .fontSize(12)
                .fontColor('#FFFFFF')
                .backgroundColor('#80000000')
                .borderRadius(10)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .position({ x: '90%', y: '90%' })
            }
            .width('100%')
            .height(400)
            .backgroundColor('#FAFAFA')

            // 基本信息
            Column() {
              Text(this.artifact.title)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 12 })

              Row() {
                this.InfoChip('年代', this.artifact.period)
                this.InfoChip('类型', this.artifact.type)
                this.InfoChip('材质', this.artifact.material)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround)
              .margin({ bottom: 16 })

              Text('收藏机构：' + this.artifact.museum)
                .fontSize(16)
                .fontColor('#666666')
                .margin({ bottom: 24 })

              Text('文物介绍')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 8 })

              Text(this.artifact.description)
                .fontSize(16)
                .lineHeight(24)
                .textAlign(TextAlign.Start)
                .margin({ bottom: 20 })

              // ===== 同朝代关联实体 =====
              if (this.relatedEntities.length > 0) {
                Column() {
                  Text('同朝代文物')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .alignSelf(ItemAlign.Start)
                    .margin({ bottom: 8 })

                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.relatedEntities, (entity: RelatedEntity) => {
                      Text(entity.title)
                        .fontSize(13)
                        .fontColor('#1A73E8')
                        .backgroundColor('#E8F0FE')
                        .borderRadius(12)
                        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                        .margin({ right: 8, bottom: 6 })
                        .onClick(() => {
                          router.replaceUrl({
                            url: 'pages/ArtifactDetailPage',
                            params: { objectId: entity.id }
                          });
                        })
                    }, (entity: RelatedEntity) => entity.id)
                  }
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .margin({ bottom: 20 })
              }

              // ===== 相关推荐 =====
              if (this.relatedList.length > 0) {
                Column() {
                  Text('相关推荐')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .alignSelf(ItemAlign.Start)
                    .margin({ bottom: 8 })

                  Scroll() {
                    Row() {
                      ForEach(this.relatedList, (item: Artifact) => {
                        Column() {
                          Image(item.imageUrl)
                            .width(120)
                            .height(120)
                            .objectFit(ImageFit.Cover)
                            .borderRadius(8)
                            .alt($r('app.media.startIcon'))

                          Text(item.title)
                            .fontSize(12)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .width(120)
                            .margin({ top: 4 })

                          Text(item.period)
                            .fontSize(11)
                            .fontColor('#888')
                        }
                        .margin({ right: 8 })
                        .onClick(() => {
                          router.replaceUrl({
                            url: 'pages/ArtifactDetailPage',
                            params: { objectId: item.id }
                          });
                        })
                      }, (item: Artifact) => item.id)
                    }
                    .padding({ left: 0, right: 0, top: 8, bottom: 16 })
                  }
                  .scrollable(ScrollDirection.Horizontal)
                  .scrollBar(BarState.Off)
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .margin({ bottom: 20 })
              }

              // ===== 交互按钮（语音、点赞、收藏、上传照片） =====
              Column({ space: 12 }) {
                Row({ space: 12 }) {
                  Button('🎧 语音讲解', { type: ButtonType.Capsule })
                    .layoutWeight(1)
                    .height(44)
                    .fontSize(15)
                    .backgroundColor('#1677FF')
                    .fontColor(Color.White)
                    .onClick(() => {
                      if (this.artifact !== null) {
                        try {
                          const text = MuseumVoiceService.buildArtifactGuide(this.artifact);
                          MuseumVoiceService.speak(text);
                          this.showToast('正在播放语音讲解');
                        } catch (e) {
                          this.showToast('语音服务暂不可用');
                        }
                      }
                    })

                  Button('🎤 语音问答', { type: ButtonType.Capsule })
                    .layoutWeight(1)
                    .height(44)
                    .fontSize(15)
                    .backgroundColor('#8E44AD')
                    .fontColor(Color.White)
                    .onClick(() => {
                      if (this.artifact !== null) {
                        try {
                          const question = '这个文物在哪个博物馆';
                          const answer = MuseumVoiceService.answerQuestion(this.artifact, question);
                          MuseumVoiceService.speak(answer);
                          this.showToast(answer);
                        } catch (e) {
                          this.showToast('语音问答暂不可用');
                        }
                      }
                    })
                }
                .width('100%')

                Row({ space: 12 }) {
                  Button(this.likeSummary.active ? `❤️ 已赞 ${this.likeSummary.count}` : `❤️ 点赞 ${this.likeSummary.count}`,
                    { type: ButtonType.Capsule })
                    .layoutWeight(1)
                    .height(44)
                    .fontSize(15)
                    .backgroundColor(this.likeSummary.active ? '#FF4D4F' : '#FF7A00')
                    .fontColor(Color.White)
                    .onClick(() => {
                      this.handleToggleLike();
                    })

                  Button(this.favoriteSummary.active ? `⭐ 已藏 ${this.favoriteSummary.count}` : `⭐ 收藏 ${this.favoriteSummary.count}`,
                    { type: ButtonType.Capsule })
                    .layoutWeight(1)
                    .height(44)
                    .fontSize(15)
                    .backgroundColor(this.favoriteSummary.active ? '#0E7A3E' : '#18A058')
                    .fontColor(Color.White)
                    .onClick(() => {
                      this.handleToggleFavorite();
                    })
                }
                .width('100%')

                Button('📷 上传参观照片', { type: ButtonType.Capsule })
                  .width('100%')
                  .height(44)
                  .fontSize(15)
                  .backgroundColor('#5B6CFF')
                  .fontColor(Color.White)
                  .enabled(!this.isUploadingPhoto)
                  .onClick(() => {
                    this.handleUploadPhoto();
                  })
              }
              .width('100%')
              .margin({ top: 20 })

              this.CommentSection()
            }
            .padding(16)
            .alignItems(HorizontalAlign.Center)
          }
        }
        .scrollBar(BarState.Auto)
      } else {
        Column() {
          Text('未找到该文物')
            .fontSize(20)
            .fontColor('#FF0000')
          Button('返回首页')
            .margin({ top: 20 })
            .onClick(() => router.back())
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  CommentSection() {
    Column() {
      Text(`评论区（${this.comments.length}）`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      if (this.comments.length === 0) {
        Text('暂无评论，快来抢沙发')
          .fontSize(14)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 12 })
      } else {
        Column({ space: 10 }) {
          ForEach(this.comments, (item: CommentItem) => {
            this.CommentItemView(item)
          }, (item: CommentItem) => item.id)
        }
        .width('100%')
        .margin({ bottom: 16 })
      }

      Row({ space: 8 }) {
        TextInput({ placeholder: '写下你的看法…', text: this.commentInput })
          .layoutWeight(1)
          .height(44)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .onChange((value: string) => {
            this.commentInput = value;
          })

        Button('发表')
          .height(44)
          .fontSize(14)
          .backgroundColor('#007AFF')
          .fontColor(Color.White)
          .enabled(!this.isSubmittingComment)
          .onClick(() => {
            this.handleSubmitComment();
          })
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 24, bottom: 20 })
  }

  @Builder
  CommentItemView(item: CommentItem) {
    Column() {
      Row() {
        Text(item.username)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(formatReviewStatus(item.status))
          .fontSize(12)
          .fontColor(formatReviewColor(item.status))
      }
      .width('100%')

      Text(item.content)
        .fontSize(15)
        .lineHeight(22)
        .margin({ top: 6 })
        .width('100%')

      Text(formatDateTime(item.createdAt))
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 6 })
        .alignSelf(ItemAlign.End)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  InfoChip(label: string, value: string) {
    Column() {
      Text(label).fontSize(12).fontColor('#999999')
      Text(value).fontSize(16).fontWeight(FontWeight.Medium).margin({ top: 4 })
    }
  }

  private async handleToggleLike() {
    if (!this.artifact) {
      return;
    }
    if (!this.isLogin || !this.username) {
      this.showToast('请先登录后再点赞');
      router.pushUrl({ url: 'pages/LoginPage' });
      return;
    }
    const actor = this.resolveActor();
    this.likeSummary = await interactionStore.toggleLike(this.artifact.id, actor);
    this.showToast(this.likeSummary.active ? '已点赞' : '已取消点赞');
  }

  private async handleToggleFavorite() {
    if (!this.artifact) {
      return;
    }
    if (!this.isLogin || !this.username) {
      this.showToast('请先登录后再收藏');
      router.pushUrl({ url: 'pages/LoginPage' });
      return;
    }
    const actor = this.resolveActor();
    this.favoriteSummary = await interactionStore.toggleFavorite(this.artifact, actor);
    this.showToast(this.favoriteSummary.active ? '已加入收藏夹' : '已取消收藏');
  }

  private async handleSubmitComment() {
    if (!this.artifact) {
      return;
    }
    if (!this.isLogin || !this.username) {
      this.showToast('请先登录后再评论');
      router.pushUrl({ url: 'pages/LoginPage' });
      return;
    }
    if (this.isSubmittingComment) {
      return;
    }
    this.isSubmittingComment = true;
    const result = await interactionStore.addComment(this.artifact, this.username, this.commentInput);
    this.isSubmittingComment = false;
    if (result.ok) {
      this.commentInput = '';
      this.comments = await interactionStore.getCommentsForArtifact(this.artifact.id);
    }
    this.showToast(result.message);
  }

  private async handleUploadPhoto() {
    if (!this.artifact) {
      return;
    }
    if (!this.isLogin || !this.username) {
      this.showToast('请先登录后再上传照片');
      router.pushUrl({ url: 'pages/LoginPage' });
      return;
    }
    if (this.isUploadingPhoto) {
      return;
    }
    this.isUploadingPhoto = true;
    const imageUri = await pickSingleImageUri();
    this.isUploadingPhoto = false;
    if (!imageUri) {
      return;
    }
    await interactionStore.addUpload({
      artifactId: this.artifact.id,
      artifactTitle: this.artifact.title,
      username: this.username,
      imageUri: imageUri,
      location: this.artifact.museum,
      description: '参观打卡'
    });
    this.showToast('照片已上传，等待审核');
  }

  private showToast(message: string) {
    try {
      promptAction.showToast({ message: message });
    } catch (error) {
      console.error('Toast显示失败: ' + JSON.stringify(error));
    }
  }
}