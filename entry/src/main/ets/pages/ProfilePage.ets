import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { UserInteractionStats } from '../common/models/InteractionModels';
import { interactionStore } from '../common/store/InteractionStore';

@Entry
@Component
export struct ProfilePage {
  @StorageLink('isLogin') isLogin: boolean = false;
  @StorageLink('username') username: string = '';
  @StorageLink('interactionVersion') @Watch('onInteractionVersionChange') interactionVersion: number = 0;
  @StorageLink('profileLikes') profileLikes: number = 0;
  @StorageLink('profileFavorites') profileFavorites: number = 0;
  @StorageLink('profileComments') profileComments: number = 0;
  @StorageLink('profilePhotos') profilePhotos: number = 0;

  @State stats: UserInteractionStats = {
    likes: 0,
    favorites: 0,
    comments: 0,
    photos: 0,
    history: 0
  };

  aboutToAppear() {
    this.refreshStats();
  }

  private async refreshStats() {
    if (!this.isLogin || !this.username) {
      this.stats = { likes: 0, favorites: 0, comments: 0, photos: 0, history: 0 };
      this.profileLikes = 0;
      this.profileFavorites = 0;
      this.profileComments = 0;
      this.profilePhotos = 0;
      return;
    }

    this.stats = await interactionStore.getStats(this.username);
    this.profileLikes = this.stats.likes;
    this.profileFavorites = this.stats.favorites;
    this.profileComments = this.stats.comments;
    this.profilePhotos = this.stats.photos;
  }

  private onInteractionVersionChange(): void {
    this.refreshStats();
  }

  build() {
    Column() {
      if (this.isLogin) {
        Column() {
          Circle({ width: 80, height: 80 })
            .fill('#CCCCCC')
            .margin({ top: 28 })

          Text(this.username)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 10 })

          Text('个人主页')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        Column() {
          this.MenuItem('收藏夹', '📦', 'pages/MyFavoritesPage')
          this.MenuItem('浏览记录', '⏰', 'pages/MyHistoryPage')
          this.MenuItem('我的评论', '💬', 'pages/MyCommentsPage')
          this.MenuItem('上传的照片', '📷', 'pages/MyUploadsPage')
          this.MenuItem('隐私设置', '🔒', 'pages/PrivacySettingPage')
          Divider()
          this.MenuItem('退出登录', '🚪', '')
        }
        .width('100%')
        .margin({ top: 18 })
        .padding({ left: 20, right: 20 })
      } else {
        Column({ space: 20 }) {
          Circle({ width: 80, height: 80 })
            .fill('#CCCCCC')
            .margin({ top: 72 })

          Text('未登录')
            .fontSize(18)

          Button('去登录')
            .width(200)
            .height(44)
            .backgroundColor('#007AFF')
            .onClick(() => {
              router.pushUrl({ url: 'pages/LoginPage' });
            })

          Button('注册账号')
            .width(200)
            .height(44)
            .backgroundColor('transparent')
            .fontColor('#007AFF')
            .onClick(() => {
              router.pushUrl({ url: 'pages/RegisterPage' });
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
    .onAppear(() => {
      this.refreshStats();
    })
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, currentRatio: number) => {
      if (isVisible && currentRatio > 0) {
        this.refreshStats();
      }
    })
  }

  @Builder
  MenuItem(title: string, icon: string, route: string) {
    Row() {
      Text(icon)
        .fontSize(24)
        .margin({ right: 12 })

      Text(title)
        .fontSize(16)

      Blank()

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(50)
    .onClick(() => {
      if (title === '退出登录') {
        this.doLogout();
        return;
      }

      if (!this.isLogin) {
        promptAction.showToast({ message: '请先登录' });
        router.pushUrl({ url: 'pages/LoginPage' });
        return;
      }

      if (route) {
        router.pushUrl({ url: route });
      }
    })
  }

  doLogout() {
    AppStorage.SetOrCreate('isLogin', false);
    AppStorage.SetOrCreate('username', '');
    AppStorage.SetOrCreate('profileLikes', 0);
    AppStorage.SetOrCreate('profileFavorites', 0);
    AppStorage.SetOrCreate('profileComments', 0);
    AppStorage.SetOrCreate('profilePhotos', 0);
    this.refreshStats();
    promptAction.showToast({ message: '已退出登录' });
  }
}
