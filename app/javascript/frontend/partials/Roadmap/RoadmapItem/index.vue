<template>
  <Panel>
    <div class="roadmap-item">
      <div
        v-lazy:background-image="storeImage"
        class="item-image lazy"
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
            :to="{
              name: 'model',
              params: {
                slug: item.model.slug,
              }
            }"
          >
            {{ item.name }}
          </router-link>
          <template v-else>
            {{ item.name }}
          </template>
          <small
            v-tooltip="$t('labels.roadmap.lastUpdate')"
            class="pull-right"
          >
            {{ item.lastVersionChangedAtLabel }}
            <i class="far fa-clock" />
          </small>
        </h3>
        <p>{{ description }}</p>
        <ul v-if="item.lastVersion && !slim">
          <li
            v-for="(update, index) in updates(item.lastVersion)"
            :key="index"
          >
            <template v-if="update.key === 'release' && !update.old">
              {{ $t('labels.roadmap.lastVersion.addedToRelease', {
                release: update.new,
              }) }}
            </template>
            <template v-else-if="update.key === 'released'">
              {{ $t(`labels.roadmap.lastVersion.released`) }}
            </template>
            <template v-else-if="update.key === 'tasks'">
              {{ $t(`labels.roadmap.lastVersion.tasks.${update.change}`, {
                value: removeSign(update.count),
              }) }}
            </template>
            <template v-else-if="update.key === 'completed'">
              {{ $t(`labels.roadmap.lastVersion.completed.${update.change}`, {
                value: removeSign(update.count),
              }) }}
            </template>
            <template v-else-if="update.key === 'active'">
              {{ $t(`labels.roadmap.lastVersion.active.${update.change}`) }}
            </template>
            <template v-else>
              {{ $t(`labels.roadmap.lastVersion.${update.key}`, {
                old: update.old,
                new: update.new,
                count: update.count,
              }) }}
            </template>
          </li>
        </ul>
        <b-progress :max="item.tasks">
          <div class="progress-label">
            {{ progressLabel }} | {{ completedPercent }} %
          </div>
          <b-progress-bar
            v-if="completed !== 0"
            :value="completed"
            :class="{
              completed: completed === item.tasks
            }"
          />
        </b-progress>
      </div>
    </div>
  </Panel>
</template>

<script>
import Panel from 'frontend/components/Panel'
import { isBefore, addHours } from 'date-fns'

export default {
  components: {
    Panel,
  },

  props: {
    item: {
      type: Object,
      required: true,
    },

    slim: {
      type: Boolean,
      default: false,
    },
  },

  computed: {
    tasks() {
      if (this.item.tasks) {
        return this.item.tasks
      }

      return '?'
    },

    completed() {
      if (this.item.completed) {
        return this.item.completed
      }

      return 0
    },

    completedPercent() {
      if (!this.item.tasks) {
        return '?'
      }

      return Math.round((100 * this.completed) / this.item.tasks)
    },

    progressLabel() {
      return `${this.completed} ${this.$t('labels.roadmap.tasks', { count: this.tasks })}`
    },

    storeImage() {
      if (this.item.storeImageSmall) {
        return this.item.storeImageSmall
      }

      return `https://robertsspaceindustries.com${this.item.image}`
    },

    description() {
      if (this.item.body) {
        return this.item.body
      }

      return this.item.description
    },

    recentlyUpdated() {
      return isBefore(new Date(), addHours(new Date(this.item.lastVersionChangedAt), 24))
    },
  },

  methods: {
    removeSign(number) {
      return (number < 0) ? number * -1 : number
    },

    updates(lastVersion) {
      return ['tasks', 'completed', 'release', 'released', 'active'].filter((key) => lastVersion[key])
        .map((key) => {
          const count = parseInt(lastVersion[key][1] - lastVersion[key][0], 10)

          return {
            key,
            change: (count < 0) ? 'decreased' : 'increased',
            old: lastVersion[key][0],
            new: lastVersion[key][1],
            count,
          }
        })
        .filter((update) => update.key !== 'released' || (update.key === 'released' && update.old))
        .filter((update) => update.key !== 'tasks' || (update.key === 'tasks' && update.count !== 0))
        .filter((update) => update.key !== 'completed' || (update.key === 'completed' && update.count !== 0))
    },
  },
}
</script>
