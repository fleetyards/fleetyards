<template>
  <div class="flex-list-row">
    <div class="store-image wide">
      <a
        v-if="uploaded"
        :href="image.url"
        :title="image.name"
        :download="image.name"
        target="_blank"
      >
        <div
          :key="image.smallUrl"
          v-lazy:background-image="image.smallUrl"
          class="image lazy"
          alt="storeImage"
        />
      </a>
      <div
        v-else
        :key="image.smallUrl"
        v-lazy:background-image="image.smallUrl"
        class="image lazy"
        alt="storeImage"
      />
    </div>
    <div class="description">
      <h2>
        <a
          v-if="uploaded"
          :href="image.url"
          :title="image.name"
          :download="image.name"
        >
          {{ image.name }}
        </a>
        <span v-else>
          {{ image.name }}
        </span>
      </h2>
      <div v-if="image.error">
        <span class="pill pill-danger">
          {{ $t('labels.image.error') }}
        </span>
      </div>
      <template v-if="!uploaded">
        <p v-if="image.active">
          {{ $t('labels.image.processing') }}
          {{ image.speed | formatSize }}
        </p>
        <div
          v-if="image.active || image.progress !== '0.00'"
          class="progress"
        >
          <div
            class="progress-bar progress-bar-info progress-bar-striped"
            :class="{
              'progress-bar-danger': image.error,
              'progress-bar-animated': image.active
            }"
            role="progressbar"
            :style="{width: image.progress + '%'}"
          >
            {{ image.progress }} %
          </div>
        </div>
      </template>
    </div>
    <div class="size">
      {{ image.size | formatSize }}
    </div>
    <div class="actions">
      <template v-if="uploaded">
        <Btn
          v-tooltip="$t('labels.image.background')"
          :disabled="updating"
          size="small"
          @click.native="toggleBackground"
        >
          <span v-show="image.background">
            <i class="fa fa-eye" />
          </span>
          <span v-show="!image.background">
            <i class="far fa-eye-slash" />
          </span>
        </Btn>
        <Btn
          v-tooltip="$t('labels.image.enabled')"
          :disabled="updating"
          size="small"
          @click.native="toggleEnabled"
        >
          <span v-show="image.enabled">
            <i class="fa fa-check-square" />
          </span>
          <span v-show="!image.enabled">
            <i class="far fa-square" />
          </span>
        </Btn>
        <Btn
          v-tooltip="$t('labels.image.global')"
          :disabled="updating"
          size="small"
          @click.native="toggleGlobal"
        >
          <span v-show="image.global">
            <i class="fas fa-globe" />
          </span>
          <span v-show="!image.global">
            <i class="fal fa-globe icon-disabled" />
          </span>
        </Btn>
        <Btn
          :disabled="deleting"
          size="small"
          @click.native="deleteImage"
        >
          <i class="fa fa-trash" />
          <span>{{ $t('labels.image.delete') }}</span>
        </Btn>
      </template>
      <template v-else>
        <Btn
          v-if="!image.success"
          @click.native="start(image)"
        >
          <i class="fa fa-upload" />
          <span>{{ $t('labels.image.start') }}</span>
        </Btn>
        <Btn @click.native="cancel(image)">
          <i class="fa fa-ban-circle" />
          <span>{{ $t('labels.image.cancel') }}</span>
        </Btn>
      </template>
    </div>
  </div>
</template>

<script>
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Btn,
  },
  props: {
    image: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      deleting: false,
      updating: false,
    }
  },
  computed: {
    uploaded() {
      return !!this.image.url
    },
  },
  methods: {
    start() {
      this.$emit('start', this.image)
    },
    cancel() {
      this.$emit('cancel', this.image)
    },
    async toggleEnabled() {
      this.updating = true
      this.image.enabled = !this.image.enabled
      const response = await this.$api.put(`images/${this.image.id}`, {
        enabled: this.image.enabled,
      })

      this.updating = false

      if (response.error) {
        this.image.enabled = !this.image.enabled
      }
    },
    async toggleGlobal() {
      this.updating = true
      this.image.global = !this.image.global
      const response = await this.$api.put(`images/${this.image.id}`, {
        global: this.image.global,
      })

      this.updating = false

      if (response.error) {
        this.image.global = !this.image.global
      }
    },
    async toggleBackground() {
      this.updating = true
      this.image.background = !this.image.background
      const response = await this.$api.put(`images/${this.image.id}`, {
        background: this.image.background,
      })

      this.updating = false

      if (response.error) {
        this.image.background = !this.image.background
      }
    },
    async deleteImage() {
      this.deleting = true
      const response = await this.$api.destroy(`images/${this.image.id}`)

      if (!response.error) {
        this.$emit('imageDeleted', this.image)
        this.deleting = false
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
