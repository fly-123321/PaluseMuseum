import { Artifact, mockArtifacts } from '../common/models/Artifact';
import router from '@ohos.router';

interface FilterConfig {
  label: string;
  options: string[];
  value: string;
  onChange: (val: string) => void;
}

@Entry
@Component
export struct HomePage {
  private allArtifacts: Artifact[] = mockArtifacts;

  @State displayList: Artifact[] = [];
  @State searchKeyword: string = '';
  @State sortBy: string = 'hot';
  @State filterPeriod: string = '全部';
  @State filterType: string = '全部';
  @State filterMaterial: string = '全部';
  @State filterMuseum: string = '全部';
  @State viewMode: number = 0;

  @State periods: string[] = [];
  @State types: string[] = [];
  @State materials: string[] = [];
  @State museums: string[] = [];

  @State currentPage: number = 1;
  private pageSize: number = 3;
  @State totalFilteredList: Artifact[] = [];
  @State hasMore: boolean = false;

  @State showMoreFilters: boolean = false; // 是否展开更多筛选

  aboutToAppear() {
    this.searchKeyword = '';
    this.filterPeriod = '全部';
    this.filterType = '全部';
    this.filterMaterial = '全部';
    this.filterMuseum = '全部';
    this.sortBy = 'hot';
    this.currentPage = 1;
    this.initFilterOptions();
    this.refreshList();
  }

  private initFilterOptions() {
    this.periods = this.getUniqueValues('period');
    this.types = this.getUniqueValues('type');
    this.materials = this.getUniqueValues('material');
    this.museums = this.getUniqueValues('museum');
  }

  private getUniqueValues(field: string): string[] {
    const set = new Set<string>();
    for (const item of this.allArtifacts) {
      let value = '';
      switch (field) {
        case 'period': value = item.period; break;
        case 'type': value = item.type; break;
        case 'material': value = item.material; break;
        case 'museum': value = item.museum; break;
      }
      set.add(value);
    }
    return ['全部', ...Array.from(set)];
  }

  private refreshList() {
    let list = [...this.allArtifacts];

    const kw = this.searchKeyword.trim().toLowerCase();
    if (kw) {
      list = list.filter(item =>
      item.title.toLowerCase().includes(kw) ||
        item.museum.toLowerCase().includes(kw) ||
        item.period.toLowerCase().includes(kw) ||
        item.type.toLowerCase().includes(kw) ||
        item.material.toLowerCase().includes(kw)
      );
    }

    if (this.filterPeriod !== '全部') list = list.filter(item => item.period === this.filterPeriod);
    if (this.filterType !== '全部') list = list.filter(item => item.type === this.filterType);
    if (this.filterMaterial !== '全部') list = list.filter(item => item.material === this.filterMaterial);
    if (this.filterMuseum !== '全部') list = list.filter(item => item.museum === this.filterMuseum);

    if (this.sortBy === 'hot') {
      list.sort((a, b) => parseInt(a.id) - parseInt(b.id));
    } else if (this.sortBy === 'name') {
      list.sort((a, b) => a.title.localeCompare(b.title));
    } else if (this.sortBy === 'period') {
      list.sort((a, b) => a.period.localeCompare(b.period));
    }

    this.totalFilteredList = list;
    this.currentPage = 1;
    this.updateDisplayList();
  }

  private updateDisplayList() {
    this.displayList = this.totalFilteredList.slice(0, this.currentPage * this.pageSize);
    this.hasMore = this.currentPage * this.pageSize < this.totalFilteredList.length;
  }

  private loadMore() {
    if (this.hasMore) {
      this.currentPage++;
      this.updateDisplayList();
    }
  }

  build() {
    Column() {
      // 导航栏标题
      Row() {
        Text('掌上博物馆')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Blank()
        Text(this.viewMode === 0 ? '📱' : '📋')
          .fontSize(20)
          .onClick(() => { this.viewMode = (this.viewMode + 1) % 2; })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')

      // 搜索框
      Row() {
        TextInput({ placeholder: '🔍  搜索文物名称、年代、类型、材质' })
          .onChange((value: string) => {
            this.searchKeyword = value;
            this.refreshList();
          })
          .layoutWeight(1)
          .height(36)
          .fontSize(14)
      }
      .width('100%').padding({ left: 12, right: 12, top: 4, bottom: 4 }).backgroundColor('#F5F5F5')

      // ===== 折叠式筛选栏（默认只显示年代，展开后每行一个条件） =====
      Column() {
        // 第一行：可滑动的年代选项 + 固定在末尾的展开按钮
        Row() {
          Scroll() {
            Row() {
              this.FilterBar({ label: '年代', options: this.periods, value: this.filterPeriod,
                onChange: (val: string) => { this.filterPeriod = val; this.refreshList(); } })
            }
            .padding({ left: 8, right: 8 })
            .justifyContent(FlexAlign.Start)
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .layoutWeight(1)   // 让 Scroll 占据剩余空间，按钮固定在右侧

          // 固定在末尾的展开/收起按钮
          Text(this.showMoreFilters ? '收起 ▲' : '展开 ▼')
            .fontSize(12)
            .fontColor('#1A73E8')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#F0F0F0')
            .borderRadius(12)
            .margin({ left: 8, right: 8 })
            .onClick(() => { this.showMoreFilters = !this.showMoreFilters; })
        }
        .height(40)
        .width('100%')
        .backgroundColor('#FFFFFF')

        // 展开时显示其余三行，每行一个筛选条件
        if (this.showMoreFilters) {
          // 类型
          Scroll() {
            Row() {
              this.FilterBar({ label: '类型', options: this.types, value: this.filterType,
                onChange: (val: string) => { this.filterType = val; this.refreshList(); } })
            }
            .padding({ left: 8, right: 8 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .height(40)
          .backgroundColor('#FFFFFF')
          .borderRadius(4)
          .margin({ top: 2 })

          // 材质
          Scroll() {
            Row() {
              this.FilterBar({ label: '材质', options: this.materials, value: this.filterMaterial,
                onChange: (val: string) => { this.filterMaterial = val; this.refreshList(); } })
            }
            .padding({ left: 8, right: 8 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .height(40)
          .backgroundColor('#FFFFFF')
          .borderRadius(4)
          .margin({ top: 2 })

          // 博物馆
          Scroll() {
            Row() {
              this.FilterBar({ label: '博物馆', options: this.museums, value: this.filterMuseum,
                onChange: (val: string) => { this.filterMuseum = val; this.refreshList(); } })
            }
            .padding({ left: 8, right: 8 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .height(40)
          .backgroundColor('#FFFFFF')
          .borderRadius(4)
          .margin({ top: 2 })
        }
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(4)
      .margin({ top: 2 })

      // 排序按钮行
      Row() {
        Text('排序：').fontSize(13).fontColor('#666').margin({ right: 6 })
        Text('热门').fontSize(13).fontColor(this.sortBy === 'hot' ? '#1A73E8' : '#666')
          .fontWeight(this.sortBy === 'hot' ? FontWeight.Bold : FontWeight.Normal).margin({ right: 8 })
          .onClick(() => { this.sortBy = 'hot'; this.refreshList(); })
        Text('名称').fontSize(13).fontColor(this.sortBy === 'name' ? '#1A73E8' : '#666')
          .fontWeight(this.sortBy === 'name' ? FontWeight.Bold : FontWeight.Normal).margin({ right: 8 })
          .onClick(() => { this.sortBy = 'name'; this.refreshList(); })
        Text('年代').fontSize(13).fontColor(this.sortBy === 'period' ? '#1A73E8' : '#666')
          .fontWeight(this.sortBy === 'period' ? FontWeight.Bold : FontWeight.Normal).margin({ right: 8 })
          .onClick(() => { this.sortBy = 'period'; this.refreshList(); })
      }
      .width('100%').padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .backgroundColor('#FFFFFF').border({ width: { bottom: 0.5 }, color: '#E0E0E0' })

      // 内容区域
      if (this.viewMode === 0) {
        Grid() {
          ForEach(this.displayList, (item: Artifact) => {
            GridItem() {
              this.CardView(item)
            }
          }, (item: Artifact) => item.id)
        }
        .columnsTemplate('1fr 1fr').columnsGap(8).rowsGap(8).padding(8)
        .width('100%').layoutWeight(1).backgroundColor('#F0F0F0')
      } else {
        List() {
          ForEach(this.displayList, (item: Artifact) => {
            ListItem() {
              this.ListView(item)
            }
          }, (item: Artifact) => item.id)
        }
        .width('100%').layoutWeight(1).backgroundColor('#F0F0F0').padding(8)
      }

      // 分页按钮
      if (this.hasMore) {
        Button('加载更多')
          .width('100%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#FFFFFF')
          .fontColor('#1A73E8')
          .border({ width: 1, color: '#1A73E8' })
          .borderRadius(20)
          .margin({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => this.loadMore())
      } else if (this.displayList.length > 0) {
        Text('已经到底了')
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 8, bottom: 8 })
      }
    }
    .width('100%').height('100%').backgroundColor(Color.White)
  }

  @Builder CardView(item: Artifact) {
    Column() {
      Image(item.imageUrl)
        .width('100%').aspectRatio(1).objectFit(ImageFit.Cover).borderRadius(8)
      Text(item.title)
        .fontSize(14).fontWeight(FontWeight.Medium).maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 6, bottom: 2 }).width('100%')
      Text(`${item.period} · ${item.museum}`)
        .fontSize(11).fontColor('#888').maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
    }
    .padding(8).backgroundColor(Color.White).borderRadius(8)
    .onClick(() => {
      router.pushUrl({ url: 'pages/ArtifactDetailPage', params: { objectId: item.id } });
    })
  }

  @Builder ListView(item: Artifact) {
    Row() {
      Image(item.imageUrl).width(80).height(80).objectFit(ImageFit.Cover).borderRadius(6)
      Column() {
        Text(item.title)
          .fontSize(16).fontWeight(FontWeight.Medium).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${item.period} | ${item.type} | ${item.material}`)
          .fontSize(12).fontColor('#888').margin({ top: 4 })
        Text(item.museum)
          .fontSize(12).fontColor('#666').margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 10 })
    }
    .width('100%').padding(12).backgroundColor(Color.White).borderRadius(8).margin({ bottom: 4 })
    .onClick(() => {
      router.pushUrl({ url: 'pages/ArtifactDetailPage', params: { objectId: item.id } });
    })
  }

  @Builder FilterBar(config: FilterConfig) {
    Row() {
      Text(config.label).fontSize(12).fontColor('#999').margin({ right: 4 })
      ForEach(config.options, (option: string) => {
        Text(option)
          .fontSize(12)
          .fontColor(config.value === option ? '#FFFFFF' : '#333')
          .backgroundColor(config.value === option ? '#1A73E8' : '#F0F0F0')
          .borderRadius(12)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .margin({ right: 4 })
          .onClick(() => { config.onChange(option); })
      }, (option: string) => option)
    }
  }
}