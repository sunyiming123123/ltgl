<script setup lang="ts">
import { formatDate } from '../shared/chatFormatters'
import type { ChatMessageItem, ConversationType } from '../shared/chatTypes'

const props = defineProps<{
  activeConversationTitle: string
  activeConversationMeta: string
  unreadCount: number
  conversationBusy: boolean
  activeMessages: ChatMessageItem[]
  selectedChatType: ConversationType | null
  composerPlaceholder: string
  messageForm: {
    content: string
  }
  sendingMessage: boolean
  currentUserId: number | null
}>()

const emit = defineEmits<{
  sendMessage: []
}>()

function isOwnMessage(item: ChatMessageItem) {
  return item.senderId === props.currentUserId
}

function isSystemMessage(item: ChatMessageItem) {
  return item.messageType.toLowerCase() !== 'text'
}
</script>

<template>
  <article class="panel panel--conversation">
    <div class="panel__header panel__header--conversation">
      <div>
        <p class="eyebrow">Conversation</p>
        <h3>{{ props.activeConversationTitle }}</h3>
        <p>{{ props.activeConversationMeta }}</p>
      </div>

      <div class="conversation-actions">
        <span class="badge badge--soft">未读 {{ props.unreadCount }}</span>
        <span v-if="props.conversationBusy" class="muted-text">消息同步中...</span>
      </div>
    </div>

    <div v-if="props.activeMessages.length" class="message-stream">
      <article
        v-for="item in props.activeMessages"
        :key="item.id"
        :class="[
          'message-bubble',
          isOwnMessage(item) ? 'message-bubble--self' : '',
          isSystemMessage(item) ? 'message-bubble--system' : '',
        ]"
      >
        <div class="message-bubble__meta">
          <strong>{{ item.senderFullName || item.senderUsername }}</strong>
          <span>{{ formatDate(item.sentAt) }}</span>
        </div>

        <p class="message-bubble__content">{{ item.content }}</p>

        <a v-if="item.attachmentUrl" :href="item.attachmentUrl" target="_blank" rel="noreferrer">
          查看附件
        </a>

        <span
          v-if="props.selectedChatType === 'private' && isOwnMessage(item) && !isSystemMessage(item)"
          class="message-bubble__state"
        >
          {{ item.isRead ? '已读' : '未读' }}
        </span>
      </article>
    </div>

    <div v-else class="empty-state empty-state--conversation">
      <strong>{{ props.selectedChatType ? '当前会话还没有消息' : '还没有选中任何会话' }}</strong>
      <p>
        {{
          props.selectedChatType
            ? '可以在下方输入框里发送第一条消息。'
            : '左侧选择一个好友或群组后，这里会展示完整消息记录。'
        }}
      </p>
    </div>

    <form class="composer" @submit.prevent="emit('sendMessage')">
      <label class="field">
        <span>消息内容</span>
        <textarea v-model="props.messageForm.content" :placeholder="props.composerPlaceholder" rows="4"></textarea>
      </label>

      <div class="composer__footer">
        <p class="muted-text">
          {{ props.selectedChatType ? '支持私聊和群聊文本消息。' : '未选择会话时不会发送请求。' }}
        </p>
        <button :disabled="props.sendingMessage || !props.selectedChatType" type="submit">
          {{ props.sendingMessage ? '发送中...' : '发送消息' }}
        </button>
      </div>
    </form>
  </article>
</template>