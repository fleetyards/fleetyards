<template>
  <Panel>
    <div class="roadmap-item">
      <div
        v-lazy:background-image="storeImage"
        class="item-image lazy"
      />
      <div class="item-body">
        <h3>
          <router-link
            v-if="item.model"
            :to="{
              name: 'model',
              params: {
                slug: item.model.slug
              }
            }"
          >
            {{ item.name }}
          </router-link>
          <template v-else>
            {{ item.name }}
          </template>
        </h3>
        <p v-if="!withoutDescription">
          {{ description }}
        </p>
        <h4>
          {{ t('labels.roadmap.lastUpdate') }}
          <small>{{ l(item.updatedAt) }}</small>
        </h4>
        <ul v-if="item.lastVersion">
          <li
            v-for="(update, index) in updates(item.lastVersion)"
            :key="index"
          >
            <template v-if="update.key === 'tasks'">
              {{ t(`labels.roadmap.lastVersion.${update.key}.${update.change}`, {
                value: removeSign(update.count),
              }) }}
            </template>
            <template v-else>
              {{ t(`labels.roadmap.lastVersion.${update.key}`, {
                old: update.old,
                new: update.new,
                count: update.count,
              }) }}
            </template>
          </li>
        </ul>
        <b-progress :max="item.tasks">
          <div class="progress-label">
            {{ completed }} {{ t('labels.roadmap.tasks', {
              count: tasks,
            }) }}
          </div>
          <b-progress-bar
            v-if="completed !== 0"
            :value="completed"
            :class="{
              completed: completed === item.tasks
            }"
          />
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
import I18n from 'frontend/mixins/I18n'

export default {
  components: {
    Panel,
  },
  mixins: [I18n],
  props: {
    item: {
      type: Object,
      required: true,
    },
    withoutDescription: {
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
    storeImage() {
      if (this.item.storeImage) {
        return this.item.storeImage
      }
      return `https://robertsspaceindustries.com${this.item.image}`
    },
    description() {
      if (this.item.body) {
        return this.item.body
      }
      return this.item.description
    },
  },
  methods: {
    removeSign(number) {
      return (number < 0) ? number * -1 : number
    },
    updates(lastVersion) {
      return ['tasks', 'completed', 'release'].filter(key => lastVersion[key]).map((key) => {
        const count = parseInt(lastVersion[key][1] - lastVersion[key][0], 10)
        return {
          key,
          change: (Math.sign(count) === -1) ? 'decreased' : 'increased',
          old: lastVersion[key][0],
          new: lastVersion[key][1],
          count,
        }
      })
    },
  },
}
</script>
