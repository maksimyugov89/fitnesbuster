/** Shared type definitions for Cloud Functions request/response payloads. */

export interface FriendRequestData {
  toUid: string;
}

export interface AcceptDeclineData {
  requestId: string;
}

export interface RemoveFriendData {
  friendUid: string;
}

export interface SearchUsersData {
  query: string;
}

export interface CreateChallengeData {
  title: string;
  description: string;
  goalType: string;
  targetValue: number;
  durationDays: number;
  isPublic: boolean;
}

export interface JoinChallengeData {
  challengeId: string;
}

export interface UpdateChallengeProgressData {
  challengeId: string;
  value: number;
}

export interface RecordWorkoutData {
  durationMinutes: number;
  caloriesBurned: number;
  cardioMinutes: number;
  streak: number;
}

export interface DeepSeekRequest {
  messages: Array<{role: string; content: string}>;
  maxTokens?: number;
  temperature?: number;
}

export interface DeepSeekResponse {
  content: string;
}
