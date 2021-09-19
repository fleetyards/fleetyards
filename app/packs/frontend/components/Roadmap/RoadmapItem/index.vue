<template>
  <Panel v-tooltip="inactiveTooltip" class="roadmap-item" :class="cssClasses">
    <div
      v-lazy:background-image="storeImage"
      class="item-image lazy"
      @click="openImage"
    >
      <div
        v-if="recentlyUpdated"
        v-tooltip="$t('labels.roadmap.recentlyUpdated')"
        class="roadmap-item-updated"
      />
    </div>
    <div class="item-body">
      <h3>
        <router-link
          v-if="item.model"
          v-tooltip="item.name"
          :to="{
            name: 'model',
            params: {
              slug: item.model.slug,
            },
          }"
        >
          {{ item.name }}
        </router-link>
        <span v-else v-tooltip="item.name" @click="openModal">
          {{ item.name }}
        </span>
        <small>
          <div v-tooltip="$t('labels.roadmap.lastUpdate')" class="text-muted">
            <span>{{ item.lastVersionChangedAtLabel }}</span>
            <i
              v-tooltip="item.lastVersionChangedAtLabel"
              class="far fa-clock"
            />
          </div>
          <div
            v-if="item.committed"
            v-tooltip="$t('labels.roadmap.committed')"
            class="roadmap-item-committed"
          >
            <span class="text-muted">{{ $t('labels.roadmap.committed') }}</span>
            <i class="far fa-check" />
          </div>
        </small>
      </h3>
      <p v-if="!compact">{{ description }}</p>
      <ul v-if="item.lastVersion && !compact">
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
    </div>
  </Panel>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Panel from 'frontend/core/components/Panel'
import { isBefore, addHours } from 'date-fns'

@Component<RoadmapItem>({
  components: {
    Panel,
  },
})
export default class RoadmapItem extends Vue {
  @Prop({ required: true }) item!: Object

  @Prop({ default: false }) compact!: boolean

  @Prop({ default: true }) showProgress!: boolean

  @Prop({ default: null }) active!: boolean

  get storeImage() {
    if (this.item.storeImageSmall) {
      return this.item.storeImageSmall
    }

    return `https://robertsspaceindustries.com${this.item.image}`
  }

  get description() {
    if (this.item.body) {
      return this.item.body
    }

    return this.item.description
  }

  get recentlyUpdated() {
    return isBefore(
      new Date(),
      addHours(new Date(this.item.lastVersionChangedAt), 24),
    )
  }

  get cssClasses() {
    return {
      compact: this.compact,
      inactive: !this.item.active && !this.active,
    }
  }

  get inactiveTooltip() {
    if (!this.item.active) {
      return this.$t('texts.roadmap.inactive')
    }
    return null
  }

  get updates() {
    if (!this.item) {
      return []
    }

    const { lastVersion } = this.item

    if (!lastVersion) {
      return []
    }

    return ['committed', 'release', 'released', 'active']
      .filter(key => lastVersion[key])
      .map(key => {
        const count = parseInt(lastVersion[key][1] - lastVersion[key][0], 10)

        return {
          key,
          change: count < 0 ? 'decreased' : 'increased',
          old: lastVersion[key][0],
          new: lastVersion[key][1],
          count,
        }
      })
      .filter(
        update =>
          update.key !== 'released' ||
          (update.key === 'released' && update.old),
      )
      .filter(
        update =>
          update.key !== 'commited' ||
          (update.key === 'commited' && update.old),
      )
      .filter(
        update =>
          update.key !== 'active' || (update.key === 'active' && update.old),
      )
  }

  openImage() {
    window.open(this.item.storeImage, '_blank').focus()
  }

  openModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Roadmap/RoadmapItem/Modal'),
      props: {
        item: this.item,
      },
    })
  }
}
</script>
