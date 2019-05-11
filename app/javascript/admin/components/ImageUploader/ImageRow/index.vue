<template>
  <tr class="fade in">
    <td class="file-preview">
      <span class="preview">
        <a
          v-if="uploaded"
          :href="file.url"
          :title="file.name"
          :download="file.name"
          target="_blank"
        >
          <img
            :src="file.smallUrl"
            :alt="file.name"
          >
        </a>
        <img
          v-else
          :src="file.smallUrl"
          :alt="file.name"
        >
      </span>
    </td>
    <td>
      <p class="name">
        <a
          v-if="uploaded"
          href=""
          :title="file.name"
          :download="file.name"
        >
          {{ file.name }}
        </a>
        <span v-else>
          {{ file.name }}
        </span>
      </p>
      <div v-if="file.error">
        <span class="label label-danger">
          Error
        </span>
      </div>
    </td>

    <td
      v-if="uploaded"
      class="file-size"
    >
      <span class="size">
        {{ file.size | formatSize }}
      </span>
    </td>
    <td
      v-else
      class="upload-progress"
    >
      <p
        v-if="file.active"
        class="size"
      >
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
    </td>

    <td
      v-if="uploaded"
      class="actions"
    >
      <div class="btn-group">
        <button
          :class="{
            active: file.background,
          }"
          :disabled="updating"
          class="btn btn-default active"
          type="button"
          @click="toggleBackground"
        >
          <i
            :class="{
              'fa-eye': file.background,
              'fa-eye-slash': !file.background,
            }"
            class="fa"
          />
        </button>
        <button
          :class="{
            active: file.enabled,
          }"
          :disabled="updating"
          class="btn btn-default"
          type="button"
          @click="toggleEnabled"
        >
          <i
            :class="{
              'fa-check': file.enabled,
              'fa-square': !file.enabled,
            }"
            class="fa"
          />
        </button>

        <button
          class="btn btn-danger delete"
          :disabled="deleting"
          @click="deleteFile"
        >
          <i class="fa fa-trash" />
          <span>Delete</span>
        </button>
      </div>
    </td>
    <td
      v-else
      class="actions"
    >
      <div class="btn-group">
        <button
          v-if="!file.success"
          class="btn btn-primary start"
          @click.prevent="start(file)"
        >
          <i class="fa fa-upload" />
          <span>Start</span>
        </button>
        <button
          class="btn btn-warning cancel"
          @click.prevent="cancel(file)"
        >
          <i class="fa fa-ban-circle" />
          <span>Cancel</span>
        </button>
      </div>
    </td>
  </tr>
</template>

<script>
export default {
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
