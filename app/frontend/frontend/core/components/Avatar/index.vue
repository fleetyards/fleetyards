<template>
  <div
    class="avatar"
    :class="{
      [`avatar-${size}`]: true,
      'avatar-editable': editable || creatable,
      'avatar-transparent': transparent,
      'avatar-round': round,
    }"
  >
    <img v-if="avatar" :src="avatar" alt="avatar" />
    <div v-else class="no-avatar">
      <i :class="icon" />
    </div>
    <div v-if="editable || creatable" class="edit" @click.prevent="emitClick">
      <template v-if="avatar">
        <i class="fa fa-times" />

        {{ $t('actions.remove') }}
      </template>
      <template v-else>
        <i class="fa fa-upload" />

        <template v-if="editable">
          {{ $t('actions.change') }}
        </template>
        <template v-else>
          {{ $t('actions.upload') }}
        </template>
      </template>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AvatarComponent',
  props: {
    avatar: {
      default: null,
      type: String,
    },

    creatable: {
      default: false,
      type: Boolean,
    },

    editable: {
      default: false,
      type: Boolean,
    },

    icon: {
      default: 'fad fa-user',
      type: String,
    },

    round: {
      default: true,
      type: Boolean,
    },

    size: {
      default: 'default',
      type: String,
      validator(value) {
        return ['default', 'small', 'large'].indexOf(value) !== -1
      },
    },
    transparent: {
      default: false,
      type: Boolean,
    },
  },
  methods: {
    emitClick() {
      if (this.avatar) {
        this.$emit('destroy')
      } else {
        this.$emit('upload')
      }
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index.scss';
</style>
