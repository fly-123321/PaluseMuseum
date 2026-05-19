// ShowPage.ets（首页展览轮播 - 可滚动、可点击跳转）
import { Artifact, mockArtifacts } from '../common/models/Artifact';
import router from '@ohos.router';                // ★ 新增路由导入

@Entry
@Component
export struct ShowPage {
  private showcaseList: Artifact[] = mockArtifacts.sort(() => Math.random() - 0.5).slice(0, 6);
  private featuredList: Artifact[] = mockArtifacts.slice(0, 3);
  @State currentImageIndex: number = 0;

  build() {
    Scroll() {
      Column() {
        // ===== 品牌标题区 =====
        Column() {
          Text('掌上博物馆')
            .fontSize(50)
            .fontWeight(FontWeight.Bold)
            .fontColor('#3A3A3A')
            .fontFamily('myCustomFont')
            .margin({ top: 40, bottom: 4 })

          Text('触摸历史 · 感受匠心')
            .fontSize(28)
            .fontColor('#8B7355')
            .fontFamily('myCustomFont')
            .margin({ bottom: 24 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        // ===== 轮播卡片容器 =====
        Column() {
          Swiper() {
            ForEach(this.showcaseList, (item: Artifact) => {
              Column() {
                Image(item.imageUrl)
                  .width('100%')
                  .height(220)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                  .alt($r('app.media.startIcon'))

                Text(item.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#3A3A3A')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 10, bottom: 4 })

                Text(item.period)
                  .fontSize(13)
                  .fontColor('#8B7355')
              }
              .padding(16)
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .onClick(() => {                           // ★ 轮播图点击跳转
                router.pushUrl({
                  url: 'pages/ArtifactDetailPage',
                  params: { objectId: item.id }
                });
              })
            }, (item: Artifact) => item.id)
          }
          .index(this.currentImageIndex)
          .autoPlay(true)
          .interval(3000)
          .indicator(true)
          .indicatorStyle({
            left: 16,
            bottom: 12,
            size: 8,
            mask: false,
            color: '#C05040',
            selectedColor: '#FFFFFF'
          })
          .onChange((index: number) => {
            this.currentImageIndex = index;
          })
          .width('100%')
          .height(320)
        }
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 10, color: '#18000000', offsetY: 4 })
        .margin({ top: 12 })

        // ===== 古典分隔线 =====
        Row() {
          Divider().strokeWidth(1).color('#C05040').width('20%')
          Text('  ✦  ').fontSize(18).fontColor('#C05040')
          Divider().strokeWidth(1).color('#C05040').width('20%')
        }
        .width('80%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 24, bottom: 16 })

        // ===== 文化标语 =====
        Text('汇集千年瑰宝，开启掌上文化之旅')
          .fontSize(22)
          .fontColor('#8B7355')
          .fontFamily('myCustomFont')
          .margin({ bottom: 20 })

        // ===== 精选馆藏横排（可点击跳转） =====
        Column() {
          Text('—— 精选馆藏 ——')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#3A3A3A')
            .margin({ bottom: 12 })

          Row() {
            ForEach(this.featuredList, (item: Artifact) => {
              Column() {
                Image(item.imageUrl)
                  .width(80).height(80)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                  .alt($r('app.media.startIcon'))

                Text(item.title)
                  .fontSize(12)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .fontColor('#3A3A3A')
                  .width(80)
                  .margin({ top: 6 })

                Text(item.period)
                  .fontSize(11)
                  .fontColor('#8B7355')
              }
              .padding(8)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .shadow({ radius: 4, color: '#15000000', offsetY: 2 })
              .margin({ left: 4, right: 4 })
              .onClick(() => {                           // ★ 精选馆藏点击跳转
                router.pushUrl({
                  url: 'pages/ArtifactDetailPage',
                  params: { objectId: item.id }
                });
              })
            }, (item: Artifact) => item.id)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .width('90%')
        .margin({ top: 8 })

        // 底部留白
        Column().height(20)
      }
      .width('100%')
      .backgroundColor('#F5F0E8')
      .padding({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F0E8')
    .scrollBar(BarState.Auto)
  }
}