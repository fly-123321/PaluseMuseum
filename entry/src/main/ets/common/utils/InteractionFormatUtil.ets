import { ReviewStatus } from '../models/InteractionModels';

export function formatReviewStatus(status: ReviewStatus): string {
  return status === ReviewStatus.Approved ? '已通过' : '审核中';
}

export function formatReviewColor(status: ReviewStatus): string {
  return status === ReviewStatus.Approved ? '#18A058' : '#FF7A00';
}

export function formatDateTime(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) {
    return iso;
  }
  const month = date.getMonth() + 1;
  const day = date.getDate();
  const hours = date.getHours();
  const minutes = date.getMinutes();
  const minuteText = minutes < 10 ? `0${minutes}` : `${minutes}`;
  return `${month}月${day}日 ${hours}:${minuteText}`;
}
