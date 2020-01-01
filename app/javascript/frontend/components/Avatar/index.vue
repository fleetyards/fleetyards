<template>
  <div
    class="avatar"
    :class="{
      [`avatar-${size}`]: true,
      'avatar-editable': editable || creatable,
      'avatar-transparent': transparent,
    }"
  >
    <img
      v-if="avatar"
      :src="avatar"
      alt="avatar"
    >
    <div
      v-else
      class="no-avatar"
    >
      <i :class="icon" />
    </div>
    <div
      v-if="editable || creatable"
      class="edit"
      @click.prevent="emitClick"
    >
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
  props: {
    size: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'small', 'large'].indexOf(value) !== -1
      },
    },

    avatar: {
      type: String,
      default: null,
    },

    editable: {
      type: Boolean,
      default: false,
    },

    creatable: {
      type: Boolean,
      default: false,
    },

    icon: {
      type: String,
      default: 'fad fa-user',
    },

    transparent: {
      type: Boolean,
      default: false,
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
  @import 'index';
</style>
