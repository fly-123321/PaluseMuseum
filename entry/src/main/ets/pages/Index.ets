import { HomePage } from './HomePage';
import { ProfilePage } from './ProfilePage';
import { DiscoverPage } from './DiscoverPage';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

  build() {
    Tabs({ index: this.currentIndex }) {
      TabContent() {
        HomePage()
      }
      .tabBar({ text: '首页', icon: $r('app.media.startIcon') })

      TabContent() {
        DiscoverPage()
      }
      .tabBar({ text: '发现', icon: $r('app.media.startIcon') })

      TabContent() {
        ProfilePage()
      }
      .tabBar({ text: '我的', icon: $r('app.media.startIcon') })
    }
    .barMode(BarMode.Fixed)
    .barPosition(BarPosition.End)
    .onChange((index: number) => {
      this.currentIndex = index;
      if (index === 2) {
        AppStorage.SetOrCreate('interactionVersion', Date.now());
      }
    })
  }
}
