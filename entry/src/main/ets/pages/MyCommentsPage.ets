import router from '@ohos.router';
import { CommentItem, ReviewStatus } from '../common/models/InteractionModels';
import { interactionStore } from '../common/store/InteractionStore';
import { formatDateTime, formatReviewColor, formatReviewStatus } from '../common/utils/InteractionFormatUtil';

@Entry
@Component
export struct MyCommentsPage {
  @StorageLink('username') username: string = '';
  @State comments: CommentItem[] = [];
  @State isLoading: boolean = true;
  private reviewRefreshTimer: number = -1;

  aboutToAppear() {
    this.clearReviewRefreshTimer();
    this.loadComments();
  }

  aboutToDisappear() {
    this.clearReviewRefreshTimer();
  }

  async loadComments() {
    this.isLoading = true;
    this.comments = await interactionStore.getUserComments(this.username);
    this.isLoading = false;
    if (this.comments.some((item: CommentItem) => item.status === ReviewStatus.Pending)) {
      this.scheduleReviewRefresh();
    } else {
      this.clearReviewRefreshTimer();
    }
  }

  private clearReviewRefreshTimer() {
    if (this.reviewRefreshTimer > -1) {
      clearTimeout(this.reviewRefreshTimer);
      this.reviewRefreshTimer = -1;
    }
  }

  private scheduleReviewRefresh() {
    this.clearReviewRefreshTimer();
    this.reviewRefreshTimer = setTimeout(() => {
      this.reviewRefreshTimer = -1;
      this.loadComments();
    }, 1600);
  }

  build() {
    Column() {
      this.PageHeader('我的评论')

      Text('待审核评论仅自己可见，通过后才会出现在公开评论区。')
        .fontSize(13)
        .fontColor('#666666')
        .width('100%')
        .padding({ left: 16, right: 16, top: 12 })

      if (this.isLoading) {
        LoadingProgress().width(40).height(40).margin({ top: 80 })
      } else if (this.comments.length === 0) {
        this.EmptyHint('还没有发表过评论')
      } else {
        List({ space: 12 }) {
          ForEach(this.comments, (item: CommentItem) => {
            ListItem() {
              this.CommentCard(item)
            }
          }, (item: CommentItem) => item.id)
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 12, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  PageHeader(title: string) {
    Row() {
      Text('<')
        .fontSize(22)
        .fontColor('#007AFF')
        .onClick(() => router.back())
      Text(title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text(' ')
        .width(22)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  EmptyHint(message: string) {
    Column() {
      Text(message)
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  CommentCard(item: CommentItem) {
    Column() {
      Row() {
        Text(item.artifactTitle || '文物评论')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Text(formatReviewStatus(item.status))
          .fontSize(12)
          .fontColor(formatReviewColor(item.status))
      }
      .width('100%')

      if (item.replyTo) {
        Text(`回复 ${item.replyTo}`)
          .fontSize(12)
          .fontColor('#5B6CFF')
          .margin({ top: 8 })
      }

      Text(item.content)
        .fontSize(15)
        .lineHeight(22)
        .margin({ top: 8 })
        .width('100%')

      Row() {
        Text(`评论点赞 ${item.likeCount || 0}`)
          .fontSize(12)
          .fontColor('#666666')
        Blank()
        Text(formatDateTime(item.createdAt))
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .margin({ top: 10 })

      if (item.artifactId) {
        Text('查看文物 >')
          .fontSize(13)
          .fontColor('#007AFF')
          .margin({ top: 8 })
          .alignSelf(ItemAlign.End)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/ArtifactDetailPage',
              params: { id: item.artifactId }
            });
          })
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }
}
