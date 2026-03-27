<script setup lang="ts">
import { computed } from 'vue'
import { formatDate, getInitials } from '../shared/chatFormatters'
import type { UserItem } from '../shared/chatTypes'

const props = defineProps<{
  filteredUsers: UserItem[]
  usersCount: number
  userKeyword: string
  activeUserCount: number
  inactiveUserCount: number
}>()

const emit = defineEmits<{
  updateUserKeyword: [value: string]
}>()

const keywordModel = computed({
  get: () => props.userKeyword,
  set: (value: string) => emit('updateUserKeyword', value),
})
</script>

<template>
  <article class="panel">
    <div class="panel__header">
      <h3>用户目录</h3>
      <span>{{ props.filteredUsers.length }}/{{ props.usersCount }}</span>
    </div>

    <div class="list-toolbar">
      <input v-model="keywordModel" :disabled="!props.usersCount" placeholder="搜索用户名、邮箱、姓名或 ID" />
      <div class="toolbar-chip-group">
        <span class="toolbar-chip">启用 {{ props.activeUserCount }}</span>
        <span class="toolbar-chip">停用 {{ props.inactiveUserCount }}</span>
      </div>
    </div>

    <div v-if="props.filteredUsers.length" class="directory-list">
      <div v-for="item in props.filteredUsers" :key="item.id" class="directory-row">
        <div class="user-main">
          <div class="avatar">{{ getInitials(item) }}</div>
          <div>
            <strong>{{ item.fullName || item.username }}</strong>
            <p>@{{ item.username }} · {{ item.email }}</p>
          </div>
        </div>

        <div class="user-meta">
          <span>ID {{ item.id }}</span>
          <span>{{ formatDate(item.createdAt) }}</span>
        </div>

        <span :class="['status-chip', item.isActive ? 'status-chip--active' : 'status-chip--inactive']">
          {{ item.isActive ? '启用' : '停用' }}
        </span>
      </div>
    </div>

    <div v-else class="empty-state">
      <strong>{{ props.usersCount ? '没有匹配结果' : '还没有用户数据' }}</strong>
      <p>{{ props.usersCount ? '试试更换搜索关键词。' : '登录成功后未获取到用户列表，可点击同步数据重试。' }}</p>
    </div>
  </article>
</template>