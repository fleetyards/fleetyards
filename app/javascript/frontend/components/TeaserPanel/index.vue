<template>
  <Panel>
    <div v-if="fullscreen" class="panel-heading">
      <h2 class="panel-title">
        {{ title }}
      </h2>
    </div>
    <div
      class="teaser-panel"
      :class="{
        'teaser-panel-text': variant === 'text',
        'teaser-panel-fullscreen': fullscreen,
      }"
    >
      <div class="teaser-panel-image teaser-panel-item">
        <LazyImage :src="image" />
      </div>
      <div v-if="!fullscreen" class="teaser-panel-body teaser-panel-item">
        <router-link v-if="to" :to="to">
          <h3>{{ title }}</h3>
          <p v-if="withDescription">
            {{ item.description }}
          </p>
        </router-link>
        <template v-else>
          <h3>{{ title }}</h3>
          <p v-if="withDescription">
            {{ item.description }}
          </p>
        </template>
      </div>
    </div>
  </Panel>
</template>

<script>
import Panel from 'frontend/components/Panel'
import LazyImage from 'frontend/components/LazyImage'

export default {
  name: 'TeaserPanel',

  components: {
    Panel,
    LazyImage,
  },

  props: {
    item: {
      type: Object,
      required: true,
    },

    to: {
      type: Object,
      default: null,
    },

    withDescription: {
      type: Boolean,
      default: true,
    },

    fullscreen: {
      type: Boolean,
      default: false,
    },

    variant: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'text'].indexOf(value) !== -1
      },
    },
  },

  computed: {
    image() {
      return this.item.storeImageMedium
    },

    title() {
      if (this.item.title) {
        return this.item.title
      }
      if (this.item.label) {
        return this.item.label
      }
      return this.item.name
    },
  },
}
</script>
