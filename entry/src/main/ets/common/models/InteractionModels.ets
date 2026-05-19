export enum ReviewStatus {
  Pending = 'pending',
  Approved = 'approved'
}

export interface FavoriteItem {
  artifactId: string;
  title: string;
  imageUrl: string;
  period: string;
  museum: string;
  groupName: string;
  createdAt: string;
}

export interface FavoriteGroupSummary {
  name: string;
  count: number;
  isDefault?: boolean;
}

export interface CommentItem {
  id: string;
  artifactId: string;
  artifactTitle: string;
  username: string;
  content: string;
  createdAt: string;
  status: ReviewStatus;
  parentId?: string;
  replyTo?: string;
  likeCount?: number;
  likedByCurrentUser?: boolean;
  children?: CommentItem[];
}

export interface UploadedPhotoItem {
  id: string;
  artifactId: string;
  artifactTitle: string;
  username: string;
  imageUri: string;
  location: string;
  description: string;
  createdAt: string;
  status: ReviewStatus;
}

export interface HistoryItem {
  artifactId: string;
  title: string;
  imageUrl: string;
  period: string;
  museum: string;
  viewedAt: string;
}

export interface CreatedAtItem {
  createdAt: string;
}

export interface PrivacySettings {
  showFavorites: boolean;
  showComments: boolean;
  showPhotos: boolean;
}

export interface UserInteractionStats {
  likes: number;
  favorites: number;
  comments: number;
  photos: number;
  history: number;
}

export interface UploadDraft {
  artifactId: string;
  artifactTitle: string;
  username: string;
  imageUri: string;
  location: string;
  description: string;
}

export interface InteractionSummary {
  active: boolean;
  count: number;
}

export const DEFAULT_PRIVACY_SETTINGS: PrivacySettings = {
  showFavorites: true,
  showComments: true,
  showPhotos: true
};

export const FAVORITE_GROUPS: string[] = [
  '默认收藏夹',
  '课堂资料',
  '细看展柜',
  '参观打卡'
];
