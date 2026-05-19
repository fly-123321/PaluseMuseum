// Index.ets
import { HomePage } from './HomePage';
import { ProfilePage } from './ProfilePage';
import { DiscoverPage } from './DiscoverPage';
import { ShowPage } from './ShowPage';         // ★ 新增引入
import font from '@ohos.font';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  aboutToAppear() {
    font.registerFont({
      familyName: 'myCustomFont',                     // 自定义字体别名
      familySrc: $rawfile('fahuawenkai.ttf')       // 文件名与实际一致
    });
  }

  @Builder
  TabBarItem(index: number, selectedIndex: number, label: string, icon: string, selectedIcon: string) {
    Column() {
      Text(index === selectedIndex ? selectedIcon : icon)
        .fontSize(24)
        .fontColor(index === selectedIndex ? '#C05040' : '#8B7355')
      Text(label)
        .fontSize(12)
        .fontColor(index === selectedIndex ? '#C05040' : '#8B7355')
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = index;
    })
  }

  build() {
    Tabs({ index: this.currentIndex }) {

      TabContent() {
        ShowPage()
      }
      .tabBar(this.TabBarItem(0, this.currentIndex, '首页', '🏛️', '🏛️'))


      TabContent() {
        HomePage()
      }
      .tabBar(this.TabBarItem(1, this.currentIndex, '文物', '🏺', '🏺'))


      TabContent() {
        DiscoverPage()
      }
      .tabBar(this.TabBarItem(2, this.currentIndex, '发现', '🔍', '🔍'))


      TabContent() {
        ProfilePage()
      }
      .tabBar(this.TabBarItem(3, this.currentIndex, '我的', '📜', '📜'))
    }
    .barMode(BarMode.Fixed)
    .barPosition(BarPosition.End)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .scrollable(false)
    .animationDuration(0)
    .barBackgroundColor('#FFFFFF')
    .divider({
      strokeWidth: 0.5,
      color: '#E0D5C6'
    })
  }
}