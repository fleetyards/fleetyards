<template>
  <Modal v-if="item" :title="item.name" class="roadmap-modal">
    <small class="roadmap-modal-subheadline">
      <div class="text-muted">
        <span>
          {{ $t('labels.roadmap.lastUpdate') }}:
          {{ item.lastVersionChangedAtLabel }}
        </span>
        <i class="far fa-clock" />
      </div>
      <div v-if="item.committed" class="roadmap-item-committed">
        <span class="text-muted">{{ $t('labels.roadmap.committed') }}</span>
        <i class="far fa-check" />
      </div>
    </small>
    <div class="roadmap-modal-image" @click="openImage">
      <img :src="storeImage" :alt="item.name" />
    </div>
    <p>{{ description }}</p>
    <ul v-if="item.lastVersion">
      <li v-for="(update, index) in updates" :key="index">
        <template v-if="update.key === 'release' && !update.old">
          {{
            $t('labels.roadmap.lastVersion.addedToRelease', {
              release: update.new,
            })
          }}
        </template>
        <template v-else-if="update.key === 'released'">
          {{ $t(`labels.roadmap.lastVersion.released`) }}
        </template>
        <template v-else-if="update.key === 'commited'">
          {{ $t(`labels.roadmap.lastVersion.committed`) }}
        </template>
        <template v-else-if="update.key === 'active'">
          {{ $t(`labels.roadmap.lastVersion.active.${update.change}`) }}
        </template>
        <template v-else>
          {{
            $t(`labels.roadmap.lastVersion.${update.key}`, {
              old: update.old,
              new: update.new,
              count: update.count,
            })
          }}
        </template>
      </li>
    </ul>

    <template #footer>
      <div class="float-sm-right">
        <Btn v-if="item.model" :inline="true" @click.native="openDetail">
          {{ $t('actions.showMore') }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script>
import Modal from '@/frontend/core/components/AppModal/Modal/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'

export default {
  name: 'RoadmapItemModal',

  components: {
    Btn,
    Modal,
  },

  props: {
    item: {
      type: Object,
      required: true,
    },
  },

  computed: {
    description() {
      if (this.item.body) {
        return this.item.body
      }

      return this.item.description
    },

    storeImage() {
      if (this.item.storeImage) {
        return this.item.storeImage
      }

      return `https://robertsspaceindustries.com${this.item.image}`
    },

    updates() {
      if (!this.item) {
        return []
      }

      const { lastVersion } = this.item

      if (!lastVersion) {
        return []
      }

      return ['committed', 'release', 'released', 'active']
        .filter((key) => lastVersion[key])
        .map((key) => {
          const count = parseInt(lastVersion[key][1] - lastVersion[key][0], 10)

          return {
            change: count < 0 ? 'decreased' : 'increased',
            count,
            key,
            new: lastVersion[key][1],
            old: lastVersion[key][0],
          }
        })
        .filter(
          (update) =>
            update.key !== 'released' ||
            (update.key === 'released' && update.old)
        )
        .filter(
          (update) =>
            update.key !== 'commited' ||
            (update.key === 'commited' && update.old)
        )
        .filter(
          (update) =>
            update.key !== 'active' || (update.key === 'active' && update.old)
        )
    },
  },

  methods: {
    openDetail() {
      this.$comlink.$emit('close-modal')
      this.$router
        .push({
          name: 'model',
          params: {
            slug: this.item.model.slug,
          },
        })
        .catch(() => {})
    },

    openImage() {
      window.open(this.storeImage, '_blank').focus()
    },
  },
}
</script>
