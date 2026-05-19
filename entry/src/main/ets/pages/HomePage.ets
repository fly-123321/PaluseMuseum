// HomePage.ets（敦煌色系 + 优化）
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
  private pageSize: number = 10;
  @State totalFilteredList: Artifact[] = [];
  @State hasMore: boolean = false;

  @State showMoreFilters: boolean = false;
  private searchTimer: number = -1;

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

  aboutToDisappear() {
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
      this.searchTimer = -1;
    }
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
  private chunkArray(arr: Artifact[], size: number): Artifact[][] {
    const result: Artifact[][] = [];
    for (let i = 0; i < arr.length; i += size) {
      result.push(arr.slice(i, i + size));
    }
    return result;
  }

  private readonly periodOrderMap: Map<string, number> = new Map([
    ['良渚文化', 1], ['新石器时代', 1], ['仰韶文化', 1],
    ['夏', 2], ['商', 3], ['西周', 4], ['春秋', 5], ['战国', 6],
    ['秦', 7], ['西汉', 8], ['东汉', 9], ['三国', 10],
    ['西晋', 11], ['东晋', 12], ['南北朝', 13], ['隋', 14],
    ['唐', 15], ['五代十国', 16], ['北宋', 17], ['南宋', 18],
    ['辽', 19], ['金', 20], ['元', 21], ['明', 22], ['清', 23],
    ['民国', 24]
  ]);

  private periodOrder(period: string): number {
    return this.periodOrderMap.get(period) ?? 99; // 未定义朝代排最后
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
      list.sort((a, b) => (b.popularity ?? 0) - (a.popularity ?? 0));
    } else if (this.sortBy === 'name') {
      list.sort((a, b) => {
        try {
          return a.title.localeCompare(b.title, 'zh-CN');
        } catch (e) {
          return a.title.localeCompare(b.title);
        }
      });
    } else if (this.sortBy === 'period') {
      list.sort((a, b) => this.periodOrder(a.period) - this.periodOrder(b.period));
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
      // ===== 导航栏标题 =====
      Row() {
        Text('🏛️')                          // 博物馆图标
          .fontSize(24)
          .margin({ right: 6 })
        Text('掌上博物馆')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#3A3A3A')
          .fontFamily('myCustomFont')   // 更换字体
        Blank()
        Text(this.viewMode === 0 ? '📱' : '📋')
          .fontSize(20)
          .fontColor('#3A3A3A')
          .onClick(() => { this.viewMode = (this.viewMode + 1) % 2; })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#F5F0E8')

      // ===== 搜索框 =====
      // ===== 搜索框（图标固定在前端） =====
      Row() {
        // 1. 固定搜索图标
        Text('🔍')
          .fontSize(18)
          .fontColor('#8B7355')
          .margin({ left: 12, right: 4 })

        // 2. 输入框（去掉图标，绑定 text）
        TextInput({ placeholder: '  搜索文物名称、年代、类型、材质...', text: this.searchKeyword })
          .placeholderFont({ size: 14 })          // 占位符文字大小
          .placeholderColor('#999999')            // 占位符文字颜色
          .onChange((value: string) => {
            this.searchKeyword = value;
            if (this.searchTimer !== -1) {
              clearTimeout(this.searchTimer);
            }
            this.searchTimer = setTimeout(() => {
              this.refreshList();
            }, 300);
          })
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .backgroundColor(Color.Transparent)    // 改为透明，由外层 Row 提供背景
          .borderRadius(0)                       // 去掉独立圆角
          .padding({ left: 0 })

        // 3. 清除按钮
        if (this.searchKeyword.trim()) {
          Text('✕')
            .fontSize(16)
            .fontColor('#8B7355')
            .margin({ left: 8, right: 12 })
            .onClick(() => {
              this.searchKeyword = '';
              if (this.searchTimer !== -1) {
                clearTimeout(this.searchTimer);
                this.searchTimer = -1;
              }
              this.refreshList();
            })
        }
      }
      .width('100%')
      .height(44)                    // 整行高度
      .backgroundColor('#FFFFFF')    // 外层统一白色背景
      .borderRadius(20)              // 外层统一圆角
      .padding({ left: 0, right: 0, top: 0, bottom: 0 })
      .margin({ left: 12, right: 12, top: 4, bottom: 4 })

      // ===== 折叠式筛选栏 =====
      Column() {
        // ===== 年代筛选行（默认显示） =====
        Row() {
          // 年代 FilterBar 放在 Row 里，占用剩余空间
          Row() {
            this.FilterBar({ label: '年代', options: this.periods, value: this.filterPeriod,
              onChange: (val: string) => { this.filterPeriod = val; this.refreshList(); } })
          }
          .layoutWeight(1)                          // 原来设置给 FilterBar 的属性移到这里
          .padding({ left: 8, right: 0 })

          Text(this.showMoreFilters ? '收起 ▲' : '展开 ▼')
            .fontSize(12)
            .fontColor('#C05040')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#F5E8E2')
            .borderRadius(12)
            .margin({ left: 4, right: 8 })
            .onClick(() => { this.showMoreFilters = !this.showMoreFilters; })
        }
        .height(40)
        .width('100%')
        .backgroundColor('#FFFFFF')

        // ===== 展开的筛选行 =====
        if (this.showMoreFilters) {
          // 类型
          Row() {
            this.FilterBar({ label: '类型', options: this.types, value: this.filterType,
              onChange: (val: string) => { this.filterType = val; this.refreshList(); } })
          }
          .width('100%')          // 设置给外层 Row
          .height(40)
          .padding({ left: 8, right: 8 })
          .backgroundColor('#FFFFFF')
          .borderRadius(4)
          .margin({ top: 2 })

          // 材质
          Row() {
            this.FilterBar({ label: '材质', options: this.materials, value: this.filterMaterial,
              onChange: (val: string) => { this.filterMaterial = val; this.refreshList(); } })
          }
          .width('100%')
          .height(40)
          .padding({ left: 8, right: 8 })
          .backgroundColor('#FFFFFF')
          .borderRadius(4)
          .margin({ top: 2 })

          // 博物馆
          Row() {
            this.FilterBar({ label: '博物馆', options: this.museums, value: this.filterMuseum,
              onChange: (val: string) => { this.filterMuseum = val; this.refreshList(); } })
          }
          .width('100%')
          .height(40)
          .padding({ left: 8, right: 8 })
          .backgroundColor('#FFFFFF')
          .borderRadius(4)
          .margin({ top: 2 })
        }
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(4)
      .margin({ top: 2 })

      // ===== 排序按钮行 =====
      Row() {
        Text('排序：').fontSize(13).fontColor('#8B7355').margin({ right: 6 })
        Text('热门').fontSize(13)
          .fontColor(this.sortBy === 'hot' ? '#C05040' : '#8B7355')
          .fontWeight(this.sortBy === 'hot' ? FontWeight.Bold : FontWeight.Normal)
          .margin({ right: 8 })
          .onClick(() => { this.sortBy = 'hot'; this.refreshList(); })
        Text('名称').fontSize(13)
          .fontColor(this.sortBy === 'name' ? '#C05040' : '#8B7355')
          .fontWeight(this.sortBy === 'name' ? FontWeight.Bold : FontWeight.Normal)
          .margin({ right: 8 })
          .onClick(() => { this.sortBy = 'name'; this.refreshList(); })
        Text('年代').fontSize(13)
          .fontColor(this.sortBy === 'period' ? '#C05040' : '#8B7355')
          .fontWeight(this.sortBy === 'period' ? FontWeight.Bold : FontWeight.Normal)
          .margin({ right: 8 })
          .onClick(() => { this.sortBy = 'period'; this.refreshList(); })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 0.5 }, color: '#E0D5C6' })

      // ===== 内容区域（含空状态）+ 列表末尾加载按钮 =====
      if (this.displayList.length === 0) {
        // 空状态提示
        Column() {
          Text('🏺')
            .fontSize(56)
            .margin({ bottom: 12 })
          Text('暂无匹配文物')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#8B7355')
          Text('试试调整筛选条件或搜索关键词')
            .fontSize(14)
            .fontColor('#8B7355')
            .margin({ top: 6 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F5F0E8')
      } else if (this.viewMode === 0) {
        // ===== 网格模式（List 内自定义两列） =====
        List() {
          ForEach(this.chunkArray(this.displayList, 2), (row: Artifact[]) => {
            ListItem() {
              Row() {
                ForEach(row, (item: Artifact) => {
                  Column() {
                    this.CardView(item)
                  }
                  .layoutWeight(1)   // 每个卡片等分宽度
                  .margin(4)         // 卡片之间及四周的间距
                }, (item: Artifact) => item.id)
                // 如果此行只有一个卡片，右侧留空占位
                if (row.length < 2) {
                  Column().layoutWeight(1).margin(4)
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
            .width('100%')
            .margin({ left: 0, right: 0 })  // 去掉水平外边距，改用 Row 内部 margin 控制
          }, (row: Artifact[]) => `${row[0].id}_${row.length}`)

          // 列表末尾：加载更多 / 已经到底（独占一行）
          if (this.hasMore) {
            ListItem() {
              Row() {
                Button('加载更多 ▼')
                  .width('60%')
                  .height(40)
                  .fontSize(14)
                  .backgroundColor('#FFFFFF')
                  .fontColor('#C05040')
                  .border({ width: 1, color: '#C05040' })
                  .borderRadius(20)
                  .onClick(() => this.loadMore())
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
            }
            .width('100%')
            .margin({ top: 8, bottom: 8 })
          } else if (this.displayList.length > 0) {
            ListItem() {
              Text('已经到底了')
                .fontSize(12)
                .fontColor('#8B7355')
                .width('100%')
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .margin({ top: 8, bottom: 8 })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F0E8')
        .padding(4)   // 四周留白，与卡片的 margin 配合形成 8px 间距
        .divider(null)
      } else {
        // ===== 列表模式（原有单列布局） =====
        List() {
          ForEach(this.displayList, (item: Artifact) => {
            ListItem() {
              this.ListView(item)
            }
            .margin({ top: 2, bottom: 2 })
          }, (item: Artifact) => item.id)

          if (this.hasMore) {
            ListItem() {
              Row() {
                Button('加载更多 ▼')
                  .width('60%')
                  .height(40)
                  .fontSize(14)
                  .backgroundColor('#FFFFFF')
                  .fontColor('#C05040')
                  .border({ width: 1, color: '#C05040' })
                  .borderRadius(20)
                  .onClick(() => this.loadMore())
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
            }
            .width('100%')
            .margin({ top: 8, bottom: 8 })
          } else if (this.displayList.length > 0) {
            ListItem() {
              Text('已经到底了')
                .fontSize(12)
                .fontColor('#8B7355')
                .width('100%')
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .margin({ top: 8, bottom: 8 })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F0E8')
        .padding({ left: 8, right: 8, top: 0, bottom: 0 })
        .divider(null)
      }


    }
    .width('100%').height('100%')
    .backgroundColor('#F5F0E8')
  }

  @Builder CardView(item: Artifact) {
    Column() {
      Image(item.imageUrl)
        .width('100%')
        .aspectRatio(1)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)

      Text(item.title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#3A3A3A')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6, bottom: 2 })
        .width('100%')

      Text(`${item.period} · ${item.museum}`)
        .fontSize(11)
        .fontColor('#8B7355')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .padding(8)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 6, color: '#18000000', offsetY: 2 })
    .onClick(() => {
      router.pushUrl({ url: 'pages/ArtifactDetailPage', params: { objectId: item.id } });
    })
  }

  @Builder ListView(item: Artifact) {
    Row() {
      Image(item.imageUrl)
        .width(80).height(80)
        .objectFit(ImageFit.Cover)
        .borderRadius(6)

      Column() {
        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#3A3A3A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${item.period} | ${item.type} | ${item.material}`)
          .fontSize(12)
          .fontColor('#8B7355')
          .margin({ top: 4 })
        Text(item.museum)
          .fontSize(12)
          .fontColor('#8B7355')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 10 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 4, color: '#15000000', offsetY: 2 })
    .onClick(() => {
      router.pushUrl({ url: 'pages/ArtifactDetailPage', params: { objectId: item.id } });
    })
  }

  @Builder FilterBar(config: FilterConfig) {
    Row() {
      // ===== 固定标签（不参与滚动） =====
      Text(config.label)
        .fontSize(12)
        .fontColor('#8B7355')
        .width(40)
        .textAlign(TextAlign.Start)
        .margin({ right: 8 })

      // ===== 可滚动的选项区 =====
      Scroll() {
        Row() {
          ForEach(config.options, (option: string) => {
            Text(option)
              .fontSize(12)
              .fontColor(config.value === option ? '#FFFFFF' : '#3A3A3A')
              .backgroundColor(config.value === option ? '#C05040' : '#F2EDE8')
              .borderRadius(12)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .margin({ right: 4 })
              .onClick(() => { config.onChange(option); })
          }, (option: string) => option)
        }
        .padding({ left: 0, right: 8 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)      // 关闭滚动条
      .layoutWeight(1)                // 占满剩余空间
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}