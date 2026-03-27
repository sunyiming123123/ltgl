<script setup lang="ts">
import type { ChatGroupItem } from '../shared/chatTypes'

const props = defineProps<{
  selectedGroup: ChatGroupItem
  selectedGroupMembershipRole: string
  canManageSelectedGroup: boolean
  updateGroupForm: {
    name: string
    description: string
  }
  addMembersForm: {
    usernames: string
  }
  actionBusy: boolean
}>()

const emit = defineEmits<{
  updateGroup: []
  leaveGroup: []
  removeGroupMember: [memberId: number]
  addMembers: []
}>()
</script>

<template>
  <article class="panel">
    <div class="panel__header">
      <div>
        <h3>群组管理</h3>
        <p>{{ props.selectedGroup.name }} · 当前角色 {{ props.selectedGroupMembershipRole }}</p>
      </div>
      <button :disabled="props.actionBusy" class="ghost" type="button" @click="emit('leaveGroup')">退出群组</button>
    </div>

    <div class="detail-grid">
      <section class="detail-card">
        <h4>群组信息</h4>
        <form class="form form--compact" @submit.prevent="emit('updateGroup')">
          <label class="field">
            <span>群组名称</span>
            <input v-model="props.updateGroupForm.name" :disabled="!props.canManageSelectedGroup" />
          </label>

          <label class="field">
            <span>群组描述</span>
            <textarea v-model="props.updateGroupForm.description" :disabled="!props.canManageSelectedGroup" rows="3"></textarea>
          </label>

          <button :disabled="props.actionBusy || !props.canManageSelectedGroup" class="secondary" type="submit">
            更新群组
          </button>
        </form>
      </section>

      <section class="detail-card">
        <h4>群成员</h4>
        <div class="member-list">
          <div v-for="member in props.selectedGroup.members" :key="member.userId" class="member-row">
            <div>
              <strong>{{ member.fullName || member.username }}</strong>
              <p>@{{ member.username }} · {{ member.role }}</p>
            </div>

            <button
              v-if="props.canManageSelectedGroup && member.role !== 'Owner'"
              :disabled="props.actionBusy"
              class="ghost"
              type="button"
              @click="emit('removeGroupMember', member.userId)"
            >
              移除
            </button>
          </div>
        </div>
      </section>

      <section v-if="props.canManageSelectedGroup" class="detail-card">
        <h4>添加成员</h4>
        <form class="form form--compact" @submit.prevent="emit('addMembers')">
          <label class="field">
            <span>用户名列表</span>
            <input v-model="props.addMembersForm.usernames" placeholder="多个用户名用逗号分隔" />
          </label>

          <button :disabled="props.actionBusy" type="submit">添加到群组</button>
        </form>
      </section>
    </div>
  </article>
</template>