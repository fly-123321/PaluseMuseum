import { Artifact } from '../models/Artifact';
import {
  CommentItem,
  CreatedAtItem,
  DEFAULT_PRIVACY_SETTINGS,
  FAVORITE_GROUPS,
  FavoriteGroupSummary,
  FavoriteItem,
  HistoryItem,
  InteractionSummary,
  PrivacySettings,
  ReviewStatus,
  UploadedPhotoItem,
  UploadDraft,
  UserInteractionStats
} from '../models/InteractionModels';
import { preferencesUtil } from '../utils/PreferencesUtil';

interface CommentResult {
  ok: boolean;
  message: string;
}

const BLOCKED_WORDS: string[] = ['广告', 'spam', '辱骂', '违法'];
const MAX_HISTORY = 20;
const COMMENT_REVIEW_DELAY_MS = 1500;

class InteractionStore {
  private readonly likeKey = 'pm.likes';
  private readonly favoriteKey = 'pm.favorites';
  private readonly favoriteGroupKey = 'pm.favoriteGroups';
  private readonly commentKey = 'pm.comments';
  private readonly commentLikeKey = 'pm.commentLikes';
  private readonly uploadKey = 'pm.uploads';
  private readonly historyKey = 'pm.history';
  private readonly privacyKey = 'pm.privacy';

  private notifyInteractionChanged(): void {
    AppStorage.SetOrCreate('interactionVersion', Date.now());
  }

  private async syncProfileStats(username: string): Promise<void> {
    if (!username) {
      AppStorage.SetOrCreate('profileLikes', 0);
      AppStorage.SetOrCreate('profileFavorites', 0);
      AppStorage.SetOrCreate('profileComments', 0);
      AppStorage.SetOrCreate('profilePhotos', 0);
      this.notifyInteractionChanged();
      return;
    }
    const stats = await this.getStats(username);
    AppStorage.SetOrCreate('profileLikes', stats.likes);
    AppStorage.SetOrCreate('profileFavorites', stats.favorites);
    AppStorage.SetOrCreate('profileComments', stats.comments);
    AppStorage.SetOrCreate('profilePhotos', stats.photos);
    this.notifyInteractionChanged();
  }

  private async getJsonValue<T>(key: string, fallback: T): Promise<T> {
    try {
      const text = await preferencesUtil.getString(key, '');
      if (!text) {
        return fallback;
      }
      return JSON.parse(text) as T;
    } catch (error) {
      console.error(`读取本地交互数据失败: ${key} ${JSON.stringify(error)}`);
      return fallback;
    }
  }

  private async setJsonValue<T>(key: string, value: T): Promise<void> {
    await preferencesUtil.putString(key, JSON.stringify(value));
  }

  private mapToObject<K, V>(map: Map<K, V>): Record<string, V> {
    const obj: Record<string, V> = {};
    map.forEach((value, key) => {
      obj[String(key)] = value;
    });
    return obj;
  }

  private objectToMap<V>(obj: Record<string, V>): Map<string, V> {
    const map = new Map<string, V>();
    Object.keys(obj).forEach((key: string) => {
      map.set(key, obj[key]);
    });
    return map;
  }

  private getDefaultFavoriteGroup(): string {
    return FAVORITE_GROUPS[0];
  }

  private uniqueStrings(items: string[]): string[] {
    const seen = new Set<string>();
    const result: string[] = [];
    items.forEach((item: string) => {
      const trimmed = item.trim();
      if (!trimmed || seen.has(trimmed)) {
        return;
      }
      seen.add(trimmed);
      result.push(trimmed);
    });
    return result;
  }

  private async loadFavoriteGroups(username: string): Promise<string[]> {
    const groupObj = await this.getJsonValue<Record<string, string[]>>(this.favoriteGroupKey, {});
    const groupMap = this.objectToMap<string[]>(groupObj);
    const customGroups = username ? (groupMap.get(username) || []) : [];
    return this.uniqueStrings([...FAVORITE_GROUPS, ...customGroups]);
  }

  private async normalizeFavoriteGroupForUser(username: string, groupName: string): Promise<string> {
    const groups = await this.loadFavoriteGroups(username);
    return groups.indexOf(groupName) > -1 ? groupName : groups[0];
  }

  private normalizeFavoriteGroup(groupName: string): string {
    return FAVORITE_GROUPS.indexOf(groupName) > -1 ? groupName : FAVORITE_GROUPS[0];
  }

  private sortByDateDesc<T extends CreatedAtItem>(items: T[]): T[] {
    return [...items].sort((left: T, right: T) => {
      const leftTime = new Date(left.createdAt).getTime();
      const rightTime = new Date(right.createdAt).getTime();
      return rightTime - leftTime;
    });
  }

  private buildLikeBaseCount(artifactId: string): number {
    const seed = Number(artifactId);
    return Number.isNaN(seed) ? 16 : 16 + seed * 5;
  }

  private buildFavoriteBaseCount(artifactId: string): number {
    const seed = Number(artifactId);
    return Number.isNaN(seed) ? 8 : 8 + seed * 3;
  }

  private buildCommentBaseCount(commentId: string): number {
    if (!commentId.startsWith('seed-')) {
      return 0;
    }
    let total = 0;
    for (let index = 0; index < commentId.length; index += 1) {
      total += commentId.charCodeAt(index);
    }
    return 2 + total % 5;
  }

  private cloneCommentItem(item: CommentItem): CommentItem {
    const cloned: CommentItem = {
      id: item.id,
      artifactId: item.artifactId,
      artifactTitle: item.artifactTitle,
      username: item.username,
      content: item.content,
      createdAt: item.createdAt,
      status: item.status
    };
    if (item.parentId) {
      cloned.parentId = item.parentId;
    }
    if (item.replyTo) {
      cloned.replyTo = item.replyTo;
    }
    if (item.likeCount !== undefined) {
      cloned.likeCount = item.likeCount;
    }
    if (item.likedByCurrentUser !== undefined) {
      cloned.likedByCurrentUser = item.likedByCurrentUser;
    }
    return cloned;
  }

  private shouldAutoApproveComment(item: CommentItem): boolean {
    if (item.status !== ReviewStatus.Pending) {
      return false;
    }
    const createdTime = new Date(item.createdAt).getTime();
    if (Number.isNaN(createdTime)) {
      return true;
    }
    return Date.now() - createdTime >= COMMENT_REVIEW_DELAY_MS;
  }

  private async syncCommentReviewStatus(comments: CommentItem[]): Promise<CommentItem[]> {
    let changed = false;
    const synced: CommentItem[] = comments.map((item: CommentItem): CommentItem => {
      const nextItem = this.cloneCommentItem(item);
      if (this.shouldAutoApproveComment(nextItem)) {
        nextItem.status = ReviewStatus.Approved;
        changed = true;
      }
      return nextItem;
    });
    if (changed) {
      await this.setJsonValue(this.commentKey, synced);
    }
    return synced;
  }

  private cloneUploadItem(item: UploadedPhotoItem): UploadedPhotoItem {
    return {
      id: item.id,
      artifactId: item.artifactId,
      artifactTitle: item.artifactTitle,
      username: item.username,
      imageUri: item.imageUri,
      location: item.location,
      description: item.description,
      createdAt: item.createdAt,
      status: item.status
    };
  }

  private shouldAutoApproveUpload(item: UploadedPhotoItem): boolean {
    if (item.status !== ReviewStatus.Pending) {
      return false;
    }
    const createdTime = new Date(item.createdAt).getTime();
    if (Number.isNaN(createdTime)) {
      return true;
    }
    return Date.now() - createdTime >= COMMENT_REVIEW_DELAY_MS;
  }

  private async syncUploadReviewStatus(items: UploadedPhotoItem[]): Promise<UploadedPhotoItem[]> {
    let changed = false;
    const synced: UploadedPhotoItem[] = items.map((item: UploadedPhotoItem): UploadedPhotoItem => {
      const nextItem = this.cloneUploadItem(item);
      if (this.shouldAutoApproveUpload(nextItem)) {
        nextItem.status = ReviewStatus.Approved;
        changed = true;
      }
      return nextItem;
    });
    if (changed) {
      await this.setJsonValue(this.uploadKey, synced);
    }
    return synced;
  }

  private getSeedComments(artifactId: string): CommentItem[] {
    return [
      {
        id: `seed-${artifactId}-1`,
        artifactId: artifactId,
        artifactTitle: '',
        username: '文博爱好者',
        content: '文物信息很完整，配合语音讲解一起看体验更好。',
        createdAt: '2026-05-10T10:00:00.000Z',
        status: ReviewStatus.Approved
      },
      {
        id: `seed-${artifactId}-2`,
        artifactId: artifactId,
        artifactTitle: '',
        username: '海外馆藏观察员',
        content: '如果能补充同年代关联文物，会更方便横向比较。',
        createdAt: '2026-05-12T14:30:00.000Z',
        status: ReviewStatus.Approved
      }
    ];
  }

  private buildFavoriteItem(artifact: Artifact, groupName: string): FavoriteItem {
    return {
      artifactId: artifact.id,
      title: artifact.title,
      imageUrl: artifact.imageUrl,
      period: artifact.period,
      museum: artifact.museum,
      groupName: groupName,
      createdAt: new Date().toISOString()
    };
  }

  private buildHistoryItem(artifact: Artifact): HistoryItem {
    return {
      artifactId: artifact.id,
      title: artifact.title,
      imageUrl: artifact.imageUrl,
      period: artifact.period,
      museum: artifact.museum,
      viewedAt: new Date().toISOString()
    };
  }

  private async getCommentLikeMap(): Promise<Map<string, string[]>> {
    const commentLikeObj = await this.getJsonValue<Record<string, string[]>>(this.commentLikeKey, {});
    return this.objectToMap<string[]>(commentLikeObj);
  }

  private async enrichComments(items: CommentItem[], username: string = ''): Promise<CommentItem[]> {
    const likeMap = await this.getCommentLikeMap();
    return items.map((item: CommentItem) => {
      const users = likeMap.get(item.id) || [];
      const enriched = this.cloneCommentItem(item);
      enriched.likeCount = this.buildCommentBaseCount(item.id) + users.length;
      enriched.likedByCurrentUser = username ? users.indexOf(username) > -1 : false;
      return enriched;
    });
  }

  async getLikeSummary(artifactId: string, username: string = ''): Promise<InteractionSummary> {
    const likeObj = await this.getJsonValue<Record<string, string[]>>(this.likeKey, {});
    const likeMap = this.objectToMap<string[]>(likeObj);
    const users = likeMap.get(artifactId) || [];
    return {
      active: username ? users.indexOf(username) > -1 : false,
      count: this.buildLikeBaseCount(artifactId) + users.length
    };
  }

  async toggleLike(artifactId: string, username: string): Promise<InteractionSummary> {
    const likeObj = await this.getJsonValue<Record<string, string[]>>(this.likeKey, {});
    const likeMap = this.objectToMap<string[]>(likeObj);
    const users = likeMap.get(artifactId) || [];
    const existingIndex = users.indexOf(username);
    if (existingIndex > -1) {
      users.splice(existingIndex, 1);
    } else {
      users.unshift(username);
    }
    likeMap.set(artifactId, users);
    await this.setJsonValue(this.likeKey, this.mapToObject(likeMap));
    await this.syncProfileStats(username);
    return this.getLikeSummary(artifactId, username);
  }

  async getFavoriteSummary(artifactId: string, username: string = ''): Promise<InteractionSummary> {
    const favoriteObj = await this.getJsonValue<Record<string, FavoriteItem[]>>(this.favoriteKey, {});
    const favoriteMap = this.objectToMap<FavoriteItem[]>(favoriteObj);
    const isActive = username
      ? (favoriteMap.get(username) || []).some((item: FavoriteItem) => item.artifactId === artifactId)
      : false;
    let favoriteUsers = 0;
    favoriteMap.forEach((list: FavoriteItem[]) => {
      if (list.some((item: FavoriteItem) => item.artifactId === artifactId)) {
        favoriteUsers += 1;
      }
    });
    return {
      active: isActive,
      count: this.buildFavoriteBaseCount(artifactId) + favoriteUsers
    };
  }

  async toggleFavorite(
    artifact: Artifact,
    username: string,
    groupName: string = FAVORITE_GROUPS[0]
  ): Promise<InteractionSummary> {
    const favoriteObj = await this.getJsonValue<Record<string, FavoriteItem[]>>(this.favoriteKey, {});
    const favoriteMap = this.objectToMap<FavoriteItem[]>(favoriteObj);
    const list = favoriteMap.get(username) || [];
    const existingIndex = list.findIndex((item: FavoriteItem) => item.artifactId === artifact.id);
    if (existingIndex > -1) {
      list.splice(existingIndex, 1);
    } else {
      const normalizedGroup = await this.normalizeFavoriteGroupForUser(username, groupName);
      list.unshift(this.buildFavoriteItem(artifact, normalizedGroup));
    }
    favoriteMap.set(username, list);
    await this.setJsonValue(this.favoriteKey, this.mapToObject(favoriteMap));
    await this.syncProfileStats(username);
    return this.getFavoriteSummary(artifact.id, username);
  }

  async getFavorites(username: string): Promise<FavoriteItem[]> {
    const favoriteObj = await this.getJsonValue<Record<string, FavoriteItem[]>>(this.favoriteKey, {});
    const favoriteMap = this.objectToMap<FavoriteItem[]>(favoriteObj);
    const favorites = favoriteMap.get(username) || [];
    const groups = await this.loadFavoriteGroups(username);
    const fallbackGroup = groups.length > 0 ? groups[0] : this.getDefaultFavoriteGroup();
    return favorites.map((item: FavoriteItem): FavoriteItem => {
      const normalizedItem: FavoriteItem = {
        artifactId: item.artifactId,
        title: item.title,
        imageUrl: item.imageUrl,
        period: item.period,
        museum: item.museum,
        groupName: groups.indexOf(item.groupName) > -1 ? item.groupName : fallbackGroup,
        createdAt: item.createdAt
      };
      return normalizedItem;
    });
  }

  async getFavoriteGroups(username: string): Promise<string[]> {
    return this.loadFavoriteGroups(username);
  }

  async addFavoriteGroup(username: string, groupName: string): Promise<string[]> {
    const trimmed = groupName.trim();
    if (!username || !trimmed) {
      return this.loadFavoriteGroups(username);
    }
    const groupObj = await this.getJsonValue<Record<string, string[]>>(this.favoriteGroupKey, {});
    const groupMap = this.objectToMap<string[]>(groupObj);
    const currentGroups = groupMap.get(username) || [];
    groupMap.set(username, this.uniqueStrings([...currentGroups, trimmed]));
    await this.setJsonValue(this.favoriteGroupKey, this.mapToObject(groupMap));
    return this.loadFavoriteGroups(username);
  }

  async deleteFavoriteGroup(username: string, groupName: string): Promise<string[]> {
    if (!username || FAVORITE_GROUPS.indexOf(groupName) > -1) {
      return this.loadFavoriteGroups(username);
    }
    const nextGroups = (await this.loadFavoriteGroups(username)).filter((item: string) => item !== groupName);
    const fallbackGroup = nextGroups.length > 0 ? nextGroups[0] : this.getDefaultFavoriteGroup();
    const groupObj = await this.getJsonValue<Record<string, string[]>>(this.favoriteGroupKey, {});
    const groupMap = this.objectToMap<string[]>(groupObj);
    const customGroups = nextGroups.filter((item: string) => FAVORITE_GROUPS.indexOf(item) === -1);
    groupMap.set(username, customGroups);
    await this.setJsonValue(this.favoriteGroupKey, this.mapToObject(groupMap));

    const favoriteObj = await this.getJsonValue<Record<string, FavoriteItem[]>>(this.favoriteKey, {});
    const favoriteMap = this.objectToMap<FavoriteItem[]>(favoriteObj);
    const favorites = (favoriteMap.get(username) || []).map((item: FavoriteItem): FavoriteItem => {
      const nextItem: FavoriteItem = {
        artifactId: item.artifactId,
        title: item.title,
        imageUrl: item.imageUrl,
        period: item.period,
        museum: item.museum,
        groupName: item.groupName === groupName ? fallbackGroup : item.groupName,
        createdAt: item.createdAt
      };
      return nextItem;
    });
    favoriteMap.set(username, favorites);
    await this.setJsonValue(this.favoriteKey, this.mapToObject(favoriteMap));
    await this.syncProfileStats(username);
    return this.loadFavoriteGroups(username);
  }

  async getFavoriteGroupForArtifact(username: string, artifactId: string): Promise<string> {
    const favorites = await this.getFavorites(username);
    const target = favorites.find((item: FavoriteItem) => item.artifactId === artifactId);
    const groups = await this.loadFavoriteGroups(username);
    return target ? target.groupName : (groups.length > 0 ? groups[0] : this.getDefaultFavoriteGroup());
  }

  async getFavoriteGroupSummaries(username: string): Promise<FavoriteGroupSummary[]> {
    const favorites = await this.getFavorites(username);
    const groups = await this.loadFavoriteGroups(username);
    return groups.map((groupName: string): FavoriteGroupSummary => {
      const summary: FavoriteGroupSummary = {
        name: groupName,
        count: favorites.filter((item: FavoriteItem) => item.groupName === groupName).length,
        isDefault: FAVORITE_GROUPS.indexOf(groupName) > -1
      };
      return summary;
    });
  }

  async moveFavoriteToGroup(artifactId: string, username: string, groupName: string): Promise<string> {
    const favoriteObj = await this.getJsonValue<Record<string, FavoriteItem[]>>(this.favoriteKey, {});
    const favoriteMap = this.objectToMap<FavoriteItem[]>(favoriteObj);
    const favorites = favoriteMap.get(username) || [];
    const target = favorites.find((item: FavoriteItem) => item.artifactId === artifactId);
    if (!target) {
      const groups = await this.loadFavoriteGroups(username);
      return groups.length > 0 ? groups[0] : this.getDefaultFavoriteGroup();
    }
    target.groupName = await this.normalizeFavoriteGroupForUser(username, groupName);
    favoriteMap.set(username, favorites);
    await this.setJsonValue(this.favoriteKey, this.mapToObject(favoriteMap));
    return target.groupName;
  }

  async cycleFavoriteGroup(artifactId: string, username: string): Promise<string> {
    const groups = await this.loadFavoriteGroups(username);
    const currentGroup = await this.getFavoriteGroupForArtifact(username, artifactId);
    const currentIndex = groups.indexOf(currentGroup);
    const nextIndex = currentIndex > -1 ? (currentIndex + 1) % groups.length : 0;
    return this.moveFavoriteToGroup(artifactId, username, groups[nextIndex]);
  }

  async removeFavorite(artifactId: string, username: string): Promise<void> {
    const favoriteObj = await this.getJsonValue<Record<string, FavoriteItem[]>>(this.favoriteKey, {});
    const favoriteMap = this.objectToMap<FavoriteItem[]>(favoriteObj);
    favoriteMap.set(username, (favoriteMap.get(username) || []).filter((item: FavoriteItem) => item.artifactId !== artifactId));
    await this.setJsonValue(this.favoriteKey, this.mapToObject(favoriteMap));
    await this.syncProfileStats(username);
  }

  async recordHistory(artifact: Artifact, username: string): Promise<void> {
    if (!username) {
      return;
    }
    const historyObj = await this.getJsonValue<Record<string, HistoryItem[]>>(this.historyKey, {});
    const historyMap = this.objectToMap<HistoryItem[]>(historyObj);
    const currentHistory = historyMap.get(username) || [];
    const filtered = currentHistory.filter((item: HistoryItem) => item.artifactId !== artifact.id);
    filtered.unshift(this.buildHistoryItem(artifact));
    historyMap.set(username, filtered.slice(0, MAX_HISTORY));
    await this.setJsonValue(this.historyKey, this.mapToObject(historyMap));
  }

  async getHistory(username: string): Promise<HistoryItem[]> {
    const historyObj = await this.getJsonValue<Record<string, HistoryItem[]>>(this.historyKey, {});
    const historyMap = this.objectToMap<HistoryItem[]>(historyObj);
    return historyMap.get(username) || [];
  }

  async getCommentsForArtifact(artifactId: string, username: string = ''): Promise<CommentItem[]> {
    const comments = await this.syncCommentReviewStatus(
      await this.getJsonValue<CommentItem[]>(this.commentKey, [])
    );
    const current = comments.filter((item: CommentItem) => item.artifactId === artifactId);
    const approved = current.filter((item: CommentItem) => item.status === ReviewStatus.Approved);
    const ownPending = username
      ? current.filter((item: CommentItem) => item.username === username && item.status !== ReviewStatus.Approved)
      : [];
    const merged = this.sortByDateDesc<CommentItem>([
      ...this.getSeedComments(artifactId),
      ...approved,
      ...ownPending
    ]);
    return this.enrichComments(merged, username);
  }

  async getCommentLikeSummary(commentId: string, username: string = ''): Promise<InteractionSummary> {
    const likeMap = await this.getCommentLikeMap();
    const users = likeMap.get(commentId) || [];
    return {
      active: username ? users.indexOf(username) > -1 : false,
      count: this.buildCommentBaseCount(commentId) + users.length
    };
  }

  async toggleCommentLike(commentId: string, username: string): Promise<InteractionSummary> {
    const likeMap = await this.getCommentLikeMap();
    const users = likeMap.get(commentId) || [];
    const existingIndex = users.indexOf(username);
    if (existingIndex === -1) {
      users.unshift(username);
    }
    likeMap.set(commentId, users);
    await this.setJsonValue(this.commentLikeKey, this.mapToObject(likeMap));
    await this.syncProfileStats(username);
    return this.getCommentLikeSummary(commentId, username);
  }

  async addComment(
    artifact: Artifact,
    username: string,
    content: string,
    parentId: string = '',
    replyTo: string = ''
  ): Promise<CommentResult> {
    const trimmed = content.trim();
    if (!trimmed) {
      return { ok: false, message: '评论内容不能为空' };
    }
    if (trimmed.length < 2) {
      return { ok: false, message: '评论至少输入 2 个字' };
    }
    if (trimmed.length > 200) {
      return { ok: false, message: '评论请控制在 200 字以内' };
    }
    if (BLOCKED_WORDS.some((word: string) => trimmed.indexOf(word) > -1)) {
      return { ok: false, message: '评论包含敏感词，请修改后再试' };
    }

    const comments = await this.getJsonValue<CommentItem[]>(this.commentKey, []);
    const record: CommentItem = {
      id: `comment-${Date.now()}`,
      artifactId: artifact.id,
      artifactTitle: artifact.title,
      username: username,
      content: trimmed,
      createdAt: new Date().toISOString(),
      status: ReviewStatus.Pending
    };
    if (parentId) {
      record.parentId = parentId;
    }
    if (replyTo) {
      record.replyTo = replyTo;
    }
    comments.unshift(record);
    await this.setJsonValue(this.commentKey, comments);
    await this.syncProfileStats(username);
    return { ok: true, message: '评论已提交，等待审核' };
  }

  async getUserComments(username: string): Promise<CommentItem[]> {
    const comments = await this.syncCommentReviewStatus(
      await this.getJsonValue<CommentItem[]>(this.commentKey, [])
    );
    const current = this.sortByDateDesc<CommentItem>(
      comments.filter((item: CommentItem) => item.username === username)
    );
    return this.enrichComments(current, username);
  }

  async addUpload(draft: UploadDraft): Promise<void> {
    const uploads = await this.getJsonValue<UploadedPhotoItem[]>(this.uploadKey, []);
    uploads.unshift({
      id: `upload-${Date.now()}`,
      artifactId: draft.artifactId,
      artifactTitle: draft.artifactTitle,
      username: draft.username,
      imageUri: draft.imageUri,
      location: draft.location.trim(),
      description: draft.description.trim(),
      createdAt: new Date().toISOString(),
      status: ReviewStatus.Pending
    });
    await this.setJsonValue(this.uploadKey, uploads);
    await this.syncProfileStats(draft.username);
  }

  async getUploads(username: string): Promise<UploadedPhotoItem[]> {
    const uploads = await this.syncUploadReviewStatus(
      await this.getJsonValue<UploadedPhotoItem[]>(this.uploadKey, [])
    );
    return uploads.filter((item: UploadedPhotoItem) => item.username === username);
  }

  async getPrivacy(username: string): Promise<PrivacySettings> {
    if (!username) {
      return DEFAULT_PRIVACY_SETTINGS;
    }
    const privacyObj = await this.getJsonValue<Record<string, PrivacySettings>>(this.privacyKey, {});
    const privacyMap = this.objectToMap<PrivacySettings>(privacyObj);
    return privacyMap.get(username) || DEFAULT_PRIVACY_SETTINGS;
  }

  async savePrivacy(username: string, privacy: PrivacySettings): Promise<void> {
    const privacyObj = await this.getJsonValue<Record<string, PrivacySettings>>(this.privacyKey, {});
    const privacyMap = this.objectToMap<PrivacySettings>(privacyObj);
    privacyMap.set(username, privacy);
    await this.setJsonValue(this.privacyKey, this.mapToObject(privacyMap));
  }

  async getStats(username: string): Promise<UserInteractionStats> {
    const favorites = await this.getFavorites(username);
    const uploads = await this.getUploads(username);
    const comments = await this.getUserComments(username);
    const history = await this.getHistory(username);
    const likeObj = await this.getJsonValue<Record<string, string[]>>(this.likeKey, {});
    const likeMap = this.objectToMap<string[]>(likeObj);
    const commentLikeMap = await this.getCommentLikeMap();

    let likes = 0;
    likeMap.forEach((users: string[]) => {
      if (users.indexOf(username) > -1) {
        likes += 1;
      }
    });
    commentLikeMap.forEach((users: string[]) => {
      if (users.indexOf(username) > -1) {
        likes += 1;
      }
    });

    return {
      likes: likes,
      favorites: favorites.length,
      comments: comments.length,
      photos: uploads.length,
      history: history.length
    };
  }
}

export const interactionStore = new InteractionStore();
