<template>
  <div class="flex-list-row">
    <div class="store-image">
      <a
        v-if="uploaded"
        :href="file.url"
        :title="file.name"
        :download="file.name"
        target="_blank"
      >
        <div
          :key="file.smallUrl"
          v-lazy:background-image="file.smallUrl"
          class="image lazy"
          alt="storeImage"
        />
      </a>
      <div
        v-else
        :key="file.smallUrl"
        v-lazy:background-image="file.smallUrl"
        class="image lazy"
        alt="storeImage"
      />
    </div>
    <div class="description">
      <h2>
        <a
          v-if="uploaded"
          :href="file.url"
          :title="file.name"
          :download="file.name"
        >
          {{ file.name }}
        </a>
        <span v-else>
          {{ file.name }}
        </span>
      </h2>
      <div v-if="file.error">
        <span class="label label-danger">
          Error
        </span>
      </div>
      <template v-if="!uploaded">
        <p v-if="file.active">
          Processing...
          {{ file.speed | formatSize }}
        </p>
        <div
          v-if="file.active || file.progress !== '0.00'"
          class="progress"
        >
          <div
            class="progress-bar progress-bar-info progress-bar-striped"
            :class="{
              'progress-bar-danger': file.error,
              'progress-bar-animated': file.active
            }"
            role="progressbar"
            :style="{width: file.progress + '%'}"
          >
            {{ file.progress }} %
          </div>
        </div>
      </template>
    </div>
    <div class="size">
      {{ file.size | formatSize }}
    </div>
    <div class="actions">
      <template v-if="uploaded">
        <Btn
          :disabled="updating"
          size="small"
          @click.native="toggleBackground"
        >
          <i
            :class="{
              'fa-eye': file.background,
              'fa-eye-slash': !file.background,
            }"
            class="fa"
          />
        </Btn>
        <Btn
          :disabled="updating"
          size="small"
          @click.native="toggleEnabled"
        >
          <i
            :class="{
              'fa fa-check': file.enabled,
              'far fa-square': !file.enabled,
            }"
          />
        </Btn>
        <Btn
          :disabled="deleting"
          size="small"
          @click.native="deleteFile"
        >
          <i class="fa fa-trash" />
          <span>Delete</span>
        </Btn>
      </template>
      <template v-else>
        <Btn
          v-if="!file.success"
          @click.native="start(file)"
        >
          <i class="fa fa-upload" />
          <span>Start</span>
        </Btn>
        <Btn
          class="btn btn-warning cancel"
          @click.native="cancel(file)"
        >
          <i class="fa fa-ban-circle" />
          <span>Cancel</span>
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
    file: {
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
      return !!this.file.url
    },
  },
  methods: {
    start() {
      this.$emit('start', this.file)
    },
    cancel() {
      this.$emit('cancel', this.file)
    },
    fetch() {
      this.$emit('fetch')
    },
    async toggleEnabled() {
      this.updating = true
      this.file.enabled = !this.file.enabled
      const response = await this.$api.put(`images/${this.file.id}`, {
        enabled: this.file.enabled,
      })

      this.updating = false

      if (response.error) {
        this.file.enabled = !this.file.enabled
      }
    },
    async toggleBackground() {
      this.updating = true
      this.file.background = !this.file.background
      const response = await this.$api.put(`images/${this.file.id}`, {
        background: this.file.background,
      })

      this.updating = false

      if (response.error) {
        this.file.background = !this.file.background
      }
    },
    async deleteFile() {
      this.deleting = true
      const response = await this.$api.destroy(`images/${this.file.id}`)

      if (!response.error) {
        await this.fetch()
        this.deleting = false
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'styles/index.scss';
</style>
