import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { FAVORITE_GROUPS, FavoriteGroupSummary, FavoriteItem } from '../common/models/InteractionModels';
import { interactionStore } from '../common/store/InteractionStore';
import { formatDateTime } from '../common/utils/InteractionFormatUtil';

const ALL_GROUP = '全部';

@Entry
@Component
export struct MyFavoritesPage {
  @StorageLink('username') username: string = '';
  @State favorites: FavoriteItem[] = [];
  @State groupSummaries: FavoriteGroupSummary[] = [];
  @State favoriteGroups: string[] = [];
  @State selectedGroup: string = ALL_GROUP;
  @State editingArtifactId: string = '';
  @State isLoading: boolean = true;
  @State newGroupName: string = '';

  aboutToAppear() {
    this.loadFavorites();
  }

  async loadFavorites() {
    this.isLoading = true;
    this.favorites = await interactionStore.getFavorites(this.username);
    this.favoriteGroups = await interactionStore.getFavoriteGroups(this.username);
    this.groupSummaries = await interactionStore.getFavoriteGroupSummaries(this.username);
    if (this.selectedGroup !== ALL_GROUP && this.favoriteGroups.indexOf(this.selectedGroup) === -1) {
      this.selectedGroup = ALL_GROUP;
    }
    this.isLoading = false;
  }

  private getFilteredFavorites(): FavoriteItem[] {
    if (this.selectedGroup === ALL_GROUP) {
      return this.favorites;
    }
    return this.favorites.filter((item: FavoriteItem) => item.groupName === this.selectedGroup);
  }

  private hasCustomGroup(): boolean {
    return this.favoriteGroups.length > FAVORITE_GROUPS.length;
  }

  private shouldShowGroupTools(): boolean {
    return this.favorites.length > 0 || this.hasCustomGroup();
  }

  private getEmptyHintText(): string {
    if (this.favorites.length === 0) {
      return '还没有收藏文物，去首页看看吧';
    }
    return `“${this.selectedGroup}”里还没有内容`;
  }

  build() {
    Column() {
      this.PageHeader('收藏夹')

      this.GroupManageBar()

      if (!this.isLoading && this.shouldShowGroupTools()) {
        this.GroupFilterBar()
        this.DeleteSelectedGroupBar()
      }

      if (this.isLoading) {
        LoadingProgress().width(40).height(40).margin({ top: 80 })
      } else if (this.getFilteredFavorites().length === 0) {
        this.EmptyHint(this.getEmptyHintText())
      } else {
        List({ space: 12 }) {
          ForEach(this.getFilteredFavorites(), (item: FavoriteItem) => {
            ListItem() {
              this.FavoriteRow(item)
            }
          }, (item: FavoriteItem) => item.artifactId)
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
  GroupManageBar() {
    Column({ space: 8 }) {
      TextInput({ placeholder: '输入新收藏夹名称', text: this.newGroupName })
        .height(40)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .onChange((value: string) => {
          this.newGroupName = value;
        })

      Button('新建收藏夹')
        .width('100%')
        .height(40)
        .fontSize(14)
        .backgroundColor('#18A058')
        .fontColor(Color.White)
        .onClick(async () => {
          if (!this.username) {
            promptAction.showToast({ message: '请先登录后再创建收藏夹' });
            return;
          }
          const trimmed = this.newGroupName.trim();
          if (!trimmed) {
            promptAction.showToast({ message: '请输入收藏夹名称' });
            return;
          }
          if (this.favoriteGroups.indexOf(trimmed) > -1) {
            promptAction.showToast({ message: '收藏夹名称已存在' });
            return;
          }
          await interactionStore.addFavoriteGroup(this.username, trimmed);
          this.newGroupName = '';
          this.selectedGroup = trimmed;
          promptAction.showToast({ message: '收藏夹已创建' });
          await this.loadFavorites();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12 })
  }

  @Builder
  GroupFilterBar() {
    Scroll() {
      Row({ space: 8 }) {
        this.GroupFilterChip(ALL_GROUP, this.favorites.length)
        ForEach(this.groupSummaries, (group: FavoriteGroupSummary) => {
          this.GroupFilterChip(group.name, group.count)
        }, (group: FavoriteGroupSummary) => group.name)
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 4 })
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  @Builder
  GroupFilterChip(label: string, count: number) {
    Text(`${label} ${count}`)
      .fontSize(13)
      .fontColor(this.selectedGroup === label ? '#FFFFFF' : '#5B6CFF')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(this.selectedGroup === label ? '#5B6CFF' : '#EEF2FF')
      .borderRadius(16)
      .onClick(() => {
        this.selectedGroup = label;
      })
  }

  @Builder
  DeleteSelectedGroupBar() {
    if (this.canDeleteSelectedGroup()) {
      Row() {
        Blank()
        Text('删除当前收藏夹')
          .fontSize(12)
          .fontColor('#FF4D4F')
          .margin({ right: 16, top: 4 })
          .onClick(async () => {
            await interactionStore.deleteFavoriteGroup(this.username, this.selectedGroup);
            this.selectedGroup = ALL_GROUP;
            promptAction.showToast({ message: '收藏夹已删除，内容已迁移到默认分组' });
            await this.loadFavorites();
          })
      }
      .width('100%')
    }
  }

  private canDeleteSelectedGroup(): boolean {
    const selected = this.groupSummaries.find((group: FavoriteGroupSummary) => group.name === this.selectedGroup);
    return !!selected && !selected.isDefault;
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
  FavoriteRow(item: FavoriteItem) {
    Column() {
      Row() {
        Image(item.imageUrl)
          .width(72)
          .height(72)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#DDDDDD')
          .alt($r('app.media.startIcon'))

        Column() {
          Text(item.title)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(`${item.period} · ${item.museum}`)
            .fontSize(13)
            .fontColor('#666666')
            .margin({ top: 4 })
          Text(`当前分组：${item.groupName}`)
            .fontSize(12)
            .fontColor('#5B6CFF')
            .margin({ top: 4 })
          Text(formatDateTime(item.createdAt))
            .fontSize(12)
            .fontColor('#BBBBBB')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 12 })
        .layoutWeight(1)
      }
      .width('100%')
      .onClick(() => {
        router.pushUrl({
          url: 'pages/ArtifactDetailPage',
          params: { id: item.artifactId }
        });
      })

      Row({ space: 16 }) {
        Text(this.editingArtifactId === item.artifactId ? '收起分组' : '更换分组')
          .fontSize(13)
          .fontColor('#007AFF')
          .onClick(() => {
            this.editingArtifactId = this.editingArtifactId === item.artifactId ? '' : item.artifactId;
          })
        Text('移出收藏')
          .fontSize(13)
          .fontColor('#FF4D4F')
          .onClick(async () => {
            await interactionStore.removeFavorite(item.artifactId, this.username);
            this.editingArtifactId = '';
            promptAction.showToast({ message: '已移出收藏夹' });
            await this.loadFavorites();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .margin({ top: 12 })

      if (this.editingArtifactId === item.artifactId) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.favoriteGroups, (groupName: string) => {
            Text(groupName)
              .fontSize(12)
              .fontColor(item.groupName === groupName ? '#FFFFFF' : '#5B6CFF')
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor(item.groupName === groupName ? '#5B6CFF' : '#EEF2FF')
              .borderRadius(14)
              .margin({ right: 8, top: 10 })
              .onClick(async () => {
                await interactionStore.moveFavoriteToGroup(item.artifactId, this.username, groupName);
                promptAction.showToast({ message: `已移到“${groupName}”` });
                await this.loadFavorites();
              })
          }, (groupName: string) => groupName)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }
}
