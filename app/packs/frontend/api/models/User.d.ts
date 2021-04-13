type User = {
  id: string
  username: string
  twoFactorRequired: boolean
}

type UserForm = {
  rsiHandle: string
  homepage: string
  discord: string
  youtube: string
  twitch: string
  guilded: string
  removeAvatar: boolean
}

type UserAccountForm = {
  username: string
  email: string
}
