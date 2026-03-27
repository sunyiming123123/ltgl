<script setup lang="ts">
const props = defineProps<{
  authBusy: boolean
  message: string
  loginForm: {
    username: string
    password: string
  }
}>()

const emit = defineEmits<{
  submit: []
}>()
</script>

<template>
  <main class="login-page login-page--centered">
    <section class="login-hero login-hero--single">
      <div class="login-hero__copy">
        <p class="eyebrow">glxt Access</p>
        <h1>登录并进入聊天工作台</h1>
        <p class="intro">
          前端已对接最新 Swagger 地址中的聊天接口。登录成功后会自动加载好友、待处理请求、群组列表和当前会话。
        </p>

        <div class="bullet-list">
          <div>
            <span class="bullet-list__label">Swagger</span>
            <a href="https://localhost:7146/swagger/index.html" target="_blank" rel="noreferrer">打开接口文档</a>
          </div>
          <div>
            <span class="bullet-list__label">登录接口</span>
            <strong>/api/Users/login</strong>
          </div>
          <div>
            <span class="bullet-list__label">聊天接口</span>
            <strong>/api/Friendship · /api/ChatGroup · /api/Message</strong>
          </div>
        </div>
      </div>

      <article class="login-card">
        <div class="login-card__header">
          <span class="badge">未登录</span>
          <h2>账号登录</h2>
          <p>输入 Swagger 可用账号后获取 JWT Token，并同步聊天数据。</p>
        </div>

        <form class="form" @submit.prevent="emit('submit')">
          <label class="field">
            <span>用户名</span>
            <input v-model="props.loginForm.username" placeholder="请输入用户名" autocomplete="username" />
          </label>

          <label class="field">
            <span>密码</span>
            <input
              v-model="props.loginForm.password"
              type="password"
              placeholder="请输入密码"
              autocomplete="current-password"
            />
          </label>

          <button :disabled="props.authBusy" type="submit">{{ props.authBusy ? '登录中...' : '立即登录' }}</button>
        </form>

        <p class="message login-message">{{ props.message }}</p>
      </article>
    </section>
  </main>
</template>