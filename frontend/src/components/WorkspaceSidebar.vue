<script setup lang="ts">
import { formatDate, getInitials } from '../shared/chatFormatters'
import type { ChatGroupItem, ConversationType, FriendshipItem, UserItem } from '../shared/chatTypes'

const props = defineProps<{
  currentUser: UserItem | null
  message: string
  tokenPreview: string
  friendCount: number
  pendingRequestCount: number
  groupCount: number
  unreadCount: number
  dashboardBusy: boolean
  conversationBusy: boolean
  actionBusy: boolean
  friendRequests: FriendshipItem[]
  friendRequestForm: {
    username: string
  }
  groupForm: {
    name: string
    description: string
    memberUsernames: string
  }
  friends: FriendshipItem[]
  groups: ChatGroupItem[]
  selectedChatType: ConversationType | null
  selectedFriendId: number | null
  selectedGroupId: number | null
}>()

const emit = defineEmits<{
  refresh: []
  logout: []
  handleFriendRequest: [friendshipId: number, accept: boolean]
  sendFriendRequest: []
  createGroup: []
  selectFriend: [friend: FriendshipItem]
  selectGroup: [group: ChatGroupItem]
}>()
</script>

<template>
  <aside class="workspace-sidebar">
    <article class="panel panel--hero">
      <div class="panel__header panel__header--start">
        <div>
          <p class="eyebrow">Workspace</p>
          <h3>欢迎回来，{{ props.currentUser?.fullName || props.currentUser?.username }}</h3>
        </div>
        <span class="badge badge--soft">在线工作台</span>
      </div>

      <p class="message">{{ props.message }}</p>
      <p class="token-preview">{{ props.tokenPreview }}</p>

      <div v-if="props.currentUser" class="meta-grid">
        <span>{{ props.currentUser.username }}</span>
        <span>{{ props.currentUser.email }}</span>
      </div>

      <div class="stats-row stats-row--sidebar">
        <div class="stat-card">
          <strong>{{ props.friendCount }}</strong>
          <span>好友</span>
        </div>
        <div class="stat-card">
          <strong>{{ props.pendingRequestCount }}</strong>
          <span>待处理请求</span>
        </div>
        <div class="stat-card">
          <strong>{{ props.groupCount }}</strong>
          <span>群组</span>
        </div>
        <div class="stat-card">
          <strong>{{ props.unreadCount }}</strong>
          <span>未读私信</span>
        </div>
      </div>

      <div class="login-card__footer">
        <button :disabled="props.dashboardBusy || props.conversationBusy" class="secondary" type="button" @click="emit('refresh')">
          {{ props.dashboardBusy ? '同步中...' : '同步数据' }}
        </button>
        <button class="ghost" type="button" @click="emit('logout')">退出登录</button>
      </div>
    </article>

    <article class="panel">
      <div class="panel__header">
        <h3>好友请求</h3>
        <span>{{ props.pendingRequestCount }}</span>
      </div>

      <div v-if="props.friendRequests.length" class="request-list">
        <div v-for="requestItem in props.friendRequests" :key="requestItem.id" class="request-card">
          <div>
            <strong>{{ requestItem.fullName || requestItem.username }}</strong>
            <p>@{{ requestItem.username }} · {{ formatDate(requestItem.createdAt) }}</p>
          </div>

          <div class="inline-actions">
            <button
              :disabled="props.actionBusy"
              class="secondary"
              type="button"
              @click="emit('handleFriendRequest', requestItem.id, true)"
            >
              接受
            </button>
            <button
              :disabled="props.actionBusy"
              class="ghost"
              type="button"
              @click="emit('handleFriendRequest', requestItem.id, false)"
            >
              拒绝
            </button>
          </div>
        </div>
      </div>

      <div v-else class="empty-state empty-state--tight">
        <strong>当前没有待处理请求</strong>
        <p>新的好友申请会展示在这里。</p>
      </div>
    </article>

    <article class="panel">
      <div class="panel__header panel__header--start">
        <div>
          <h3>快捷操作</h3>
          <p>直接调用最新聊天接口。</p>
        </div>
      </div>

      <div class="action-stack">
        <form class="form form--compact" @submit.prevent="emit('sendFriendRequest')">
          <label class="field">
            <span>添加好友</span>
            <input v-model="props.friendRequestForm.username" placeholder="输入对方用户名" />
          </label>
          <button :disabled="props.actionBusy" class="secondary" type="submit">发送好友请求</button>
        </form>

        <form class="form form--compact" @submit.prevent="emit('createGroup')">
          <label class="field">
            <span>群组名称</span>
            <input v-model="props.groupForm.name" placeholder="例如：项目讨论群" />
          </label>

          <label class="field">
            <span>群组描述</span>
            <textarea v-model="props.groupForm.description" rows="3" placeholder="描述这个群组的用途"></textarea>
          </label>

          <label class="field">
            <span>初始成员用户名</span>
            <input v-model="props.groupForm.memberUsernames" placeholder="多个用户名用逗号分隔" />
          </label>

          <button :disabled="props.actionBusy" type="submit">创建群组</button>
        </form>
      </div>
    </article>

    <article class="panel">
      <div class="panel__header">
        <h3>好友会话</h3>
        <span>{{ props.friendCount }}</span>
      </div>

      <div v-if="props.friends.length" class="contact-list">
        <button
          v-for="friend in props.friends"
          :key="friend.id"
          :class="['contact-card', props.selectedChatType === 'private' && props.selectedFriendId === friend.userId ? 'contact-card--active' : '']"
          type="button"
          @click="emit('selectFriend', friend)"
        >
          <div class="user-main user-main--compact">
            <div class="avatar avatar--small">{{ getInitials(friend) }}</div>
            <div>
              <strong>{{ friend.fullName || friend.username }}</strong>
              <p>@{{ friend.username }}</p>
            </div>
          </div>
          <span class="contact-card__meta">{{ formatDate(friend.createdAt) }}</span>
        </button>
      </div>

      <div v-else class="empty-state empty-state--tight">
        <strong>还没有好友</strong>
        <p>先从上面的快捷操作发送一个好友请求。</p>
      </div>
    </article>

    <article class="panel">
      <div class="panel__header">
        <h3>群组会话</h3>
        <span>{{ props.groupCount }}</span>
      </div>

      <div v-if="props.groups.length" class="contact-list">
        <button
          v-for="group in props.groups"
          :key="group.id"
          :class="['contact-card', props.selectedChatType === 'group' && props.selectedGroupId === group.id ? 'contact-card--active' : '']"
          type="button"
          @click="emit('selectGroup', group)"
        >
          <div>
            <strong>{{ group.name }}</strong>
            <p>{{ group.description || '暂无群介绍' }}</p>
          </div>
          <span class="contact-card__meta">{{ group.memberCount }} 人</span>
        </button>
      </div>

      <div v-else class="empty-state empty-state--tight">
        <strong>还没有群组</strong>
        <p>创建后会自动加入当前工作台。</p>
      </div>
    </article>
  </aside>
</template>