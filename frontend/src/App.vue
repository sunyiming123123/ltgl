<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import ConversationPanel from './components/ConversationPanel.vue'
import GroupManagementPanel from './components/GroupManagementPanel.vue'
import LoginView from './components/LoginView.vue'
import UserDirectoryPanel from './components/UserDirectoryPanel.vue'
import WorkspaceSidebar from './components/WorkspaceSidebar.vue'
import { formatDate } from './shared/chatFormatters'
import type {
  ApiEnvelope,
  ChatGroupItem,
  ChatMessageItem,
  ConversationType,
  FriendshipItem,
  LoginResponse,
  PreferredChat,
  UnreadCountData,
  UserItem,
} from './shared/chatTypes'

const loginForm = ref({
  username: '',
  password: '',
})

const friendRequestForm = ref({
  username: '',
})

const groupForm = ref({
  name: '',
  description: '',
  memberUsernames: '',
})

const updateGroupForm = ref({
  name: '',
  description: '',
})

const addMembersForm = ref({
  usernames: '',
})

const messageForm = ref({
  content: '',
})

const token = ref(localStorage.getItem('glxt_token') ?? '')
const currentUser = ref<UserItem | null>(readStoredUser())
const users = ref<UserItem[]>([])
const friends = ref<FriendshipItem[]>([])
const friendRequests = ref<FriendshipItem[]>([])
const groups = ref<ChatGroupItem[]>([])
const activeMessages = ref<ChatMessageItem[]>([])
const userKeyword = ref('')
const selectedChatType = ref<ConversationType | null>(null)
const selectedFriendId = ref<number | null>(null)
const selectedGroupId = ref<number | null>(null)
const unreadCount = ref(0)
const authBusy = ref(false)
const dashboardBusy = ref(false)
const conversationBusy = ref(false)
const actionBusy = ref(false)
const sendingMessage = ref(false)
const message = ref(
  token.value ? '检测到本地 Token，正在准备聊天工作台。' : '输入用户名和密码后，将请求 Swagger 中的登录接口。',
)

const isLoggedIn = computed(() => token.value.length > 0)
const filteredUsers = computed(() => {
  const keyword = userKeyword.value.trim().toLowerCase()

  if (!keyword) {
    return users.value
  }

  return users.value.filter((item) => {
    return [item.username, item.email, item.fullName ?? '', String(item.id)]
      .join(' ')
      .toLowerCase()
      .includes(keyword)
  })
})
const activeUserCount = computed(() => users.value.filter((item) => item.isActive).length)
const inactiveUserCount = computed(() => users.value.length - activeUserCount.value)
const tokenPreview = computed(() => {
  if (!token.value) {
    return '尚未获取 Token'
  }

  if (token.value.length <= 36) {
    return token.value
  }

  return `${token.value.slice(0, 18)}...${token.value.slice(-12)}`
})
const pendingRequestCount = computed(() => friendRequests.value.length)
const friendCount = computed(() => friends.value.length)
const groupCount = computed(() => groups.value.length)
const selectedFriend = computed(() => {
  return friends.value.find((item) => item.userId === selectedFriendId.value) ?? null
})
const selectedGroup = computed(() => {
  return groups.value.find((item) => item.id === selectedGroupId.value) ?? null
})
const selectedGroupMembership = computed(() => {
  return selectedGroup.value?.members.find((item) => item.userId === currentUser.value?.id) ?? null
})
const canManageSelectedGroup = computed(() => {
  return ['Owner', 'Admin'].includes(selectedGroupMembership.value?.role ?? '')
})
const activeConversationTitle = computed(() => {
  if (selectedChatType.value === 'private') {
    return selectedFriend.value?.fullName || selectedFriend.value?.username || '私聊会话'
  }

  if (selectedChatType.value === 'group') {
    return selectedGroup.value?.name || '群聊会话'
  }

  return '选择一个会话开始聊天'
})
const activeConversationMeta = computed(() => {
  if (selectedChatType.value === 'private' && selectedFriend.value) {
    return `好友账号：${selectedFriend.value.username} · 建立于 ${formatDate(selectedFriend.value.createdAt)}`
  }

  if (selectedChatType.value === 'group' && selectedGroup.value) {
    return `${selectedGroup.value.memberCount} 位成员 · 创建于 ${formatDate(selectedGroup.value.createdAt)}`
  }

  return '左侧可切换好友、群组、好友请求和建群入口。'
})
const composerPlaceholder = computed(() => {
  if (!selectedChatType.value) {
    return '先从左侧选择好友或群组，再发送消息。'
  }

  if (selectedChatType.value === 'private') {
    return `发送给 ${selectedFriend.value?.username ?? '好友'} 的消息`
  }

  return `发送到群组 ${selectedGroup.value?.name ?? ''}`
})

function readStoredUser() {
  const raw = localStorage.getItem('glxt_user')

  if (!raw) {
    return null
  }

  try {
    return JSON.parse(raw) as UserItem
  } catch {
    localStorage.removeItem('glxt_user')
    return null
  }
}

function persistAuth(result: LoginResponse) {
  token.value = result.token
  currentUser.value = result.user
  localStorage.setItem('glxt_token', result.token)
  localStorage.setItem('glxt_user', JSON.stringify(result.user))
}

function resetConversationState() {
  activeMessages.value = []
  selectedChatType.value = null
  selectedFriendId.value = null
  selectedGroupId.value = null
  messageForm.value.content = ''
  updateGroupForm.value = {
    name: '',
    description: '',
  }
  addMembersForm.value.usernames = ''
}

function splitCommaList(value: string) {
  return Array.from(
    new Set(
      value
        .split(/[，,\n]/)
        .map((item) => item.trim())
        .filter(Boolean),
    ),
  )
}

function hydrateSelectedGroupForm(group: ChatGroupItem | null) {
  updateGroupForm.value = {
    name: group?.name ?? '',
    description: group?.description ?? '',
  }
}

function getPreferredChat(): PreferredChat | null {
  if (selectedChatType.value === 'private' && selectedFriendId.value !== null) {
    return { type: 'private', id: selectedFriendId.value }
  }

  if (selectedChatType.value === 'group' && selectedGroupId.value !== null) {
    return { type: 'group', id: selectedGroupId.value }
  }

  return null
}

function mergeGroup(group: ChatGroupItem) {
  const index = groups.value.findIndex((item) => item.id === group.id)

  if (index >= 0) {
    groups.value[index] = group
    return
  }

  groups.value.unshift(group)
}

async function request<T>(url: string, init?: RequestInit): Promise<T> {
  const headers = new Headers(init?.headers)

  if (!headers.has('Content-Type') && init?.body) {
    headers.set('Content-Type', 'application/json')
  }

  if (token.value) {
    headers.set('Authorization', `Bearer ${token.value}`)
  }

  const response = await fetch(url, {
    ...init,
    headers,
  })

  const rawText = response.status === 204 ? '' : await response.text()
  const payload = rawText ? (JSON.parse(rawText) as ApiEnvelope<T> | T) : undefined

  if (!response.ok) {
    if (response.status === 401 || response.status === 403) {
      throw new Error('登录已失效，请重新登录')
    }

    const errorMessage =
      typeof payload === 'object' && payload !== null && 'message' in payload
        ? String(payload.message ?? '请求失败')
        : '请求失败'

    throw new Error(errorMessage)
  }

  if (payload && typeof payload === 'object' && 'success' in payload) {
    if (!payload.success) {
      throw new Error(payload.message || '接口返回失败')
    }

    return payload.data as T
  }

  return payload as T
}

async function refreshUnreadCount() {
  const data = await request<UnreadCountData>('/api/Message/unread-count')
  unreadCount.value = data.unreadCount
}

async function markVisibleMessagesAsRead(items: ChatMessageItem[]) {
  if (!currentUser.value) {
    return
  }

  const unreadIds = items
    .filter((item) => item.receiverId === currentUser.value?.id && !item.isRead)
    .map((item) => item.id)

  if (!unreadIds.length) {
    return
  }

  await Promise.all(unreadIds.map((messageId) => request(`/api/Message/mark-read/${messageId}`, { method: 'PUT' })))

  const unreadIdSet = new Set(unreadIds)
  activeMessages.value = items.map((item) => {
    return unreadIdSet.has(item.id)
      ? {
          ...item,
          isRead: true,
        }
      : item
  })

  await refreshUnreadCount()
}

async function loadPrivateConversation(friend: FriendshipItem) {
  conversationBusy.value = true

  try {
    const items = await request<ChatMessageItem[]>(`/api/Message/private/${friend.userId}`)
    selectedChatType.value = 'private'
    selectedFriendId.value = friend.userId
    selectedGroupId.value = null
    activeMessages.value = items
    hydrateSelectedGroupForm(null)
    await markVisibleMessagesAsRead(items)
    message.value = `已载入与 ${friend.username} 的私聊消息，共 ${items.length} 条`
  } catch (error) {
    message.value = error instanceof Error ? error.message : '加载私聊消息失败'
  } finally {
    conversationBusy.value = false
  }
}

async function loadGroupConversation(group: ChatGroupItem) {
  conversationBusy.value = true

  try {
    const [groupDetail, items] = await Promise.all([
      request<ChatGroupItem>(`/api/ChatGroup/${group.id}`),
      request<ChatMessageItem[]>(`/api/Message/group/${group.id}`),
    ])

    mergeGroup(groupDetail)
    selectedChatType.value = 'group'
    selectedGroupId.value = group.id
    selectedFriendId.value = null
    activeMessages.value = items
    hydrateSelectedGroupForm(groupDetail)
    message.value = `已载入群组 ${groupDetail.name} 的消息，共 ${items.length} 条`
  } catch (error) {
    message.value = error instanceof Error ? error.message : '加载群聊消息失败'
  } finally {
    conversationBusy.value = false
  }
}

async function selectFriend(friend: FriendshipItem) {
  await loadPrivateConversation(friend)
}

async function selectGroup(group: ChatGroupItem) {
  await loadGroupConversation(group)
}

async function resolvePreferredConversation(preferred: PreferredChat | null) {
  if (preferred?.type === 'private') {
    const matchedFriend = friends.value.find((item) => item.userId === preferred.id)

    if (matchedFriend) {
      await loadPrivateConversation(matchedFriend)
      return
    }
  }

  if (preferred?.type === 'group') {
    const matchedGroup = groups.value.find((item) => item.id === preferred.id)

    if (matchedGroup) {
      await loadGroupConversation(matchedGroup)
      return
    }
  }

  if (friends.value.length) {
    await loadPrivateConversation(friends.value[0])
    return
  }

  if (groups.value.length) {
    await loadGroupConversation(groups.value[0])
    return
  }

  resetConversationState()
}

async function loadDashboardData(preferred: PreferredChat | null = getPreferredChat()) {
  dashboardBusy.value = true

  try {
    const [userList, friendList, requestList, groupList] = await Promise.all([
      request<UserItem[]>('/api/Users'),
      request<FriendshipItem[]>('/api/Friendship/friends'),
      request<FriendshipItem[]>('/api/Friendship/requests'),
      request<ChatGroupItem[]>('/api/ChatGroup/my-groups'),
    ])

    users.value = userList
    friends.value = friendList
    friendRequests.value = requestList
    groups.value = groupList
    await refreshUnreadCount()
    await resolvePreferredConversation(preferred)
    message.value = `已同步聊天数据：${friendList.length} 位好友，${requestList.length} 条待处理请求，${groupList.length} 个群组`
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : '加载工作台失败'

    if (errorMessage.includes('重新登录')) {
      performLogout(errorMessage)
      return
    }

    message.value = errorMessage
  } finally {
    dashboardBusy.value = false
  }
}

async function login() {
  authBusy.value = true

  try {
    const result = await request<LoginResponse>('/api/Users/login', {
      method: 'POST',
      body: JSON.stringify(loginForm.value),
    })

    persistAuth(result)
    await loadDashboardData()
    message.value = `登录成功，当前用户：${result.user.username}`
  } catch (error) {
    message.value = error instanceof Error ? error.message : '登录失败'
  } finally {
    authBusy.value = false
  }
}

async function refreshWorkspace() {
  await loadDashboardData()
}

async function sendFriendRequest() {
  actionBusy.value = true

  try {
    await request('/api/Friendship/send-request', {
      method: 'POST',
      body: JSON.stringify({ username: friendRequestForm.value.username.trim() }),
    })
    friendRequestForm.value.username = ''
    await loadDashboardData(getPreferredChat())
    message.value = '好友请求已发送'
  } catch (error) {
    message.value = error instanceof Error ? error.message : '发送好友请求失败'
  } finally {
    actionBusy.value = false
  }
}

async function handleFriendRequest(friendshipId: number, accept: boolean) {
  actionBusy.value = true

  try {
    await request('/api/Friendship/handle-request', {
      method: 'POST',
      body: JSON.stringify({ friendshipId, accept }),
    })
    await loadDashboardData(getPreferredChat())
    message.value = accept ? '已接受好友请求' : '已拒绝好友请求'
  } catch (error) {
    message.value = error instanceof Error ? error.message : '处理好友请求失败'
  } finally {
    actionBusy.value = false
  }
}

async function createGroup() {
  actionBusy.value = true

  try {
    const createdGroup = await request<ChatGroupItem>('/api/ChatGroup/create', {
      method: 'POST',
      body: JSON.stringify({
        name: groupForm.value.name.trim(),
        description: groupForm.value.description.trim() || null,
        memberUsernames: splitCommaList(groupForm.value.memberUsernames),
      }),
    })

    groupForm.value = {
      name: '',
      description: '',
      memberUsernames: '',
    }

    await loadDashboardData({ type: 'group', id: createdGroup.id })
    message.value = `群组 ${createdGroup.name} 创建成功`
  } catch (error) {
    message.value = error instanceof Error ? error.message : '创建群组失败'
  } finally {
    actionBusy.value = false
  }
}

async function updateSelectedGroup() {
  if (!selectedGroup.value) {
    message.value = '请先选择一个群组'
    return
  }

  actionBusy.value = true

  try {
    await request(`/api/ChatGroup/update/${selectedGroup.value.id}`, {
      method: 'PUT',
      body: JSON.stringify({
        name: updateGroupForm.value.name.trim(),
        description: updateGroupForm.value.description.trim() || null,
      }),
    })
    await loadDashboardData({ type: 'group', id: selectedGroup.value.id })
    message.value = '群组信息已更新'
  } catch (error) {
    message.value = error instanceof Error ? error.message : '更新群组失败'
  } finally {
    actionBusy.value = false
  }
}

async function addMembersToSelectedGroup() {
  if (!selectedGroup.value) {
    message.value = '请先选择一个群组'
    return
  }

  actionBusy.value = true

  try {
    await request('/api/ChatGroup/add-members', {
      method: 'POST',
      body: JSON.stringify({
        groupId: selectedGroup.value.id,
        usernames: splitCommaList(addMembersForm.value.usernames),
      }),
    })
    addMembersForm.value.usernames = ''
    await loadDashboardData({ type: 'group', id: selectedGroup.value.id })
    message.value = '成员添加成功'
  } catch (error) {
    message.value = error instanceof Error ? error.message : '添加群成员失败'
  } finally {
    actionBusy.value = false
  }
}

async function removeGroupMember(memberId: number) {
  if (!selectedGroup.value) {
    return
  }

  actionBusy.value = true

  try {
    await request(`/api/ChatGroup/remove-member?groupId=${selectedGroup.value.id}&memberId=${memberId}`, {
      method: 'DELETE',
    })
    await loadDashboardData({ type: 'group', id: selectedGroup.value.id })
    message.value = '群成员已移除'
  } catch (error) {
    message.value = error instanceof Error ? error.message : '移除群成员失败'
  } finally {
    actionBusy.value = false
  }
}

async function leaveSelectedGroup() {
  if (!selectedGroup.value) {
    return
  }

  actionBusy.value = true

  try {
    const leavingGroupId = selectedGroup.value.id
    await request(`/api/ChatGroup/leave/${leavingGroupId}`, {
      method: 'POST',
    })
    await loadDashboardData()
    message.value = '已退出群组'
  } catch (error) {
    message.value = error instanceof Error ? error.message : '退出群组失败'
  } finally {
    actionBusy.value = false
  }
}

async function sendMessage() {
  const content = messageForm.value.content.trim()

  if (!content) {
    message.value = '消息内容不能为空'
    return
  }

  if (!selectedChatType.value) {
    message.value = '请先选择一个会话'
    return
  }

  sendingMessage.value = true

  try {
    const payload =
      selectedChatType.value === 'private'
        ? { receiverId: selectedFriendId.value, content, messageType: 'Text' }
        : { chatGroupId: selectedGroupId.value, content, messageType: 'Text' }

    await request('/api/Message/send', {
      method: 'POST',
      body: JSON.stringify(payload),
    })

    messageForm.value.content = ''

    if (selectedChatType.value === 'private' && selectedFriend.value) {
      await loadPrivateConversation(selectedFriend.value)
      message.value = `消息已发送给 ${selectedFriend.value.username}`
      return
    }

    if (selectedChatType.value === 'group' && selectedGroup.value) {
      await loadGroupConversation(selectedGroup.value)
      message.value = `消息已发送到群组 ${selectedGroup.value.name}`
    }
  } catch (error) {
    message.value = error instanceof Error ? error.message : '发送消息失败'
  } finally {
    sendingMessage.value = false
  }
}

function performLogout(nextMessage = '已退出登录') {
  token.value = ''
  currentUser.value = null
  users.value = []
  friends.value = []
  friendRequests.value = []
  groups.value = []
  unreadCount.value = 0
  userKeyword.value = ''
  loginForm.value.password = ''
  friendRequestForm.value.username = ''
  groupForm.value = {
    name: '',
    description: '',
    memberUsernames: '',
  }
  resetConversationState()
  localStorage.removeItem('glxt_token')
  localStorage.removeItem('glxt_user')
  message.value = nextMessage
}

onMounted(async () => {
  if (token.value) {
    await loadDashboardData()
  }
})
</script>

<template>
  <LoginView v-if="!isLoggedIn" :auth-busy="authBusy" :login-form="loginForm" :message="message" @submit="login" />

  <main v-else class="workspace-page">
    <section class="workspace-shell">
      <WorkspaceSidebar
        :action-busy="actionBusy"
        :conversation-busy="conversationBusy"
        :current-user="currentUser"
        :dashboard-busy="dashboardBusy"
        :friend-count="friendCount"
        :friend-request-form="friendRequestForm"
        :friend-requests="friendRequests"
        :friends="friends"
        :group-count="groupCount"
        :group-form="groupForm"
        :groups="groups"
        :message="message"
        :pending-request-count="pendingRequestCount"
        :selected-chat-type="selectedChatType"
        :selected-friend-id="selectedFriendId"
        :selected-group-id="selectedGroupId"
        :token-preview="tokenPreview"
        :unread-count="unreadCount"
        @create-group="createGroup"
        @handle-friend-request="handleFriendRequest"
        @logout="performLogout()"
        @refresh="refreshWorkspace"
        @select-friend="selectFriend"
        @select-group="selectGroup"
        @send-friend-request="sendFriendRequest"
      />

      <section class="workspace-main">
        <ConversationPanel
          :active-conversation-meta="activeConversationMeta"
          :active-conversation-title="activeConversationTitle"
          :active-messages="activeMessages"
          :composer-placeholder="composerPlaceholder"
          :conversation-busy="conversationBusy"
          :current-user-id="currentUser?.id ?? null"
          :message-form="messageForm"
          :selected-chat-type="selectedChatType"
          :sending-message="sendingMessage"
          :unread-count="unreadCount"
          @send-message="sendMessage"
        />

        <GroupManagementPanel
          v-if="selectedChatType === 'group' && selectedGroup"
          :action-busy="actionBusy"
          :add-members-form="addMembersForm"
          :can-manage-selected-group="canManageSelectedGroup"
          :selected-group="selectedGroup"
          :selected-group-membership-role="selectedGroupMembership?.role || 'Member'"
          :update-group-form="updateGroupForm"
          @add-members="addMembersToSelectedGroup"
          @leave-group="leaveSelectedGroup"
          @remove-group-member="removeGroupMember"
          @update-group="updateSelectedGroup"
        />

        <UserDirectoryPanel
          :active-user-count="activeUserCount"
          :filtered-users="filteredUsers"
          :inactive-user-count="inactiveUserCount"
          :user-keyword="userKeyword"
          :users-count="users.length"
          @update-user-keyword="userKeyword = $event"
        />
      </section>
    </section>
  </main>
</template>