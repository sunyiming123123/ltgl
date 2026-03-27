export type ApiEnvelope<T> = {
  success: boolean
  data?: T
  message?: string
}

export type UserItem = {
  id: number
  username: string
  email: string
  fullName?: string | null
  createdAt: string
  isActive: boolean
}

export type LoginResponse = {
  token: string
  user: UserItem
}

export type FriendshipItem = {
  id: number
  userId: number
  username: string
  fullName?: string | null
  status: string
  createdAt: string
  isRequester: boolean
}

export type GroupMember = {
  userId: number
  username: string
  fullName?: string | null
  role: string
  joinedAt: string
}

export type ChatGroupItem = {
  id: number
  name: string
  description?: string | null
  avatarUrl?: string | null
  creatorId: number
  createdAt: string
  memberCount: number
  members: GroupMember[]
}

export type ChatMessageItem = {
  id: number
  senderId: number
  senderUsername: string
  senderFullName?: string | null
  receiverId?: number | null
  chatGroupId?: number | null
  messageType: string
  content: string
  attachmentUrl?: string | null
  sentAt: string
  isRead: boolean
}

export type UnreadCountData = {
  unreadCount: number
}

export type ConversationType = 'private' | 'group'

export type PreferredChat = {
  type: ConversationType
  id: number
}