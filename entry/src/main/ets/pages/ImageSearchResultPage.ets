import router from '@ohos.router';

interface ArtifactItem {
  id: number;
  name: string;
  era: string;
  image: string;
  similarity: number;
}

@Entry
@Component
export struct ImageSearchResultPage {
  private image: string = '';
  @State results: ArtifactItem[] = [];

  aboutToAppear() {
    let params = router.getParams() as Record<string, string>;

    this.image = params.image;

    if (params.results) {
      this.results = JSON.parse(params.results);
    }
  }

  build() {
    Column() {
      Text('以图搜图结果')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 })

      List() {
        ForEach(this.results, (item: ArtifactItem) => {
          ListItem() {
            Row() {
              Image(item.image)
                .width(120)
                .height(120)
                .borderRadius(12)
                .objectFit(ImageFit.Cover)

              Column() {
                Text(item.name)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 10 })

                Text('年代：' + item.era)
                  .fontSize(16)
                  .fontColor('#666666')
                  .margin({ bottom: 10 })

                Text('相似度：' + item.similarity + '%')
                  .fontSize(18)
                  .fontColor('#FF3B30')
                  .fontWeight(FontWeight.Bold)
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 16 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(18)
          }
          .margin({ bottom: 16 })
        })
      }
      .width('92%')

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .alignItems(HorizontalAlign.Center)
  }
}