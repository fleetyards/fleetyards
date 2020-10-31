<template>
  <Panel v-tooltip="inactiveTooltip" class="roadmap-item" :class="cssClasses">
    <div v-lazy:background-image="storeImage" class="item-image lazy">
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
          :to="{
            name: 'model',
            params: {
              slug: item.model.slug,
            },
          }"
        >
          {{ item.name }}
        </router-link>
        <template v-else>
          {{ item.name }}
        </template>
        <small
          v-tooltip="$t('labels.roadmap.lastUpdate')"
          class="float-sm-right text-muted"
        >
          <span>{{ item.lastVersionChangedAtLabel }}</span>
          <i v-tooltip="item.lastVersionChangedAtLabel" class="far fa-clock" />
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
          <template v-else-if="update.key === 'tasks'">
            {{
              $t(`labels.roadmap.lastVersion.tasks.${update.change}`, {
                value: removeSign(update.count),
              })
            }}
          </template>
          <template v-else-if="update.key === 'completed'">
            {{
              $t(`labels.roadmap.lastVersion.completed.${update.change}`, {
                value: removeSign(update.count),
              })
            }}
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
      <BProgress v-if="item && showProgress" :max="item.tasks">
        <div class="progress-label">
          <template v-if="inProgress">
            {{ progressLabel }} | {{ completedPercent }} %
          </template>
          <template v-else-if="inPolish">
            {{ $t('labels.roadmap.inPolish') }}
          </template>
          <template v-else-if="item.released">
            {{ $t('labels.roadmap.released') }}
          </template>
        </div>
        <BProgressBar
          v-if="completed !== 0 && completedChange > 0"
          :value="completed - completedChange"
          :class="{
            completed: completed >= item.tasks,
          }"
        />
        <BProgressBar
          v-else-if="completed !== 0"
          :value="completed"
          :class="{
            completed: completed >= item.tasks,
          }"
        />
        <BProgressBar
          v-if="completedChange > 0"
          :value="completedChange"
          :striped="true"
          :class="{
            completed: completed >= item.tasks,
          }"
        />
      </BProgress>
    </div>
  </Panel>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import { BProgress, BProgressBar } from 'bootstrap-vue'
import Panel from 'frontend/core/components/Panel'
import { isBefore, addHours } from 'date-fns'

@Component<RoadmapItem>({
  components: {
    BProgress,
    BProgressBar,
    Panel,
  },
})
export default class RoadmapItem extends Vue {
  @Prop({ required: true }) item!: Object

  @Prop({ default: false }) compact!: boolean

  @Prop({ default: true }) showProgress!: boolean

  @Prop({ default: null }) active!: boolean

  getCompleted

  get tasks() {
    if (this.item.tasks) {
      return this.item.tasks
    }

    return '?'
  }

  get completed() {
    if (this.item.completed) {
      return this.item.completed
    }

    return 0
  }

  get inProgress() {
    if (this.tasks === '?') {
      return false
    }

    return this.completed < this.tasks && !this.item.released
  }

  get inPolish() {
    if (this.tasks === '?') {
      return false
    }

    return this.completed >= this.tasks && !this.item.released
  }

  get completedPercent() {
    if (!this.item.tasks) {
      return '?'
    }

    return Math.round((100 * this.completed) / this.item.tasks)
  }

  get progressLabel() {
    return `${this.completed} ${this.$t('labels.roadmap.tasks', {
      count: this.tasks,
    })}`
  }

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

  get completedChange() {
    return this.updates.find(item => item.key === 'completed')?.count || 0
  }

  get tasksChange() {
    return this.updates.find(item => item.key === 'tasks')?.count || 0
  }

  get updates() {
    if (!this.item) {
      return []
    }

    const { lastVersion } = this.item

    if (!lastVersion) {
      return []
    }

    return ['tasks', 'completed', 'release', 'released', 'active']
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
          update.key !== 'tasks' ||
          (update.key === 'tasks' && update.count !== 0),
      )
      .filter(
        update =>
          update.key !== 'active' || (update.key === 'active' && update.old),
      )
      .filter(
        update =>
          update.key !== 'completed' ||
          (update.key === 'completed' && update.count !== 0),
      )
  }

  removeSign(number) {
    return number < 0 ? number * -1 : number
  }
}
</script>
