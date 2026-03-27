export function formatDate(value: string) {
  return new Intl.DateTimeFormat('zh-CN', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

export function getInitials(user: { username: string; fullName?: string | null }) {
  const source = (user.fullName || user.username).trim()
  return source.slice(0, 2).toUpperCase()
}