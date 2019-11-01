<template>
  <div class="labels">
    <h3 class="label-title">
      Groups:
    </h3>
    <draggable
      v-model="groups"
      @start="drag=true"
      @end="drag=false"
    >
      <transition-group
        name="fade-list"
        appear
      >
        <a
          v-for="group in groups"
          :key="group.id"
          :class="{
            'active': isActive(group.slug),
            'inverted': isInverted(group.slug),
          }"
          class="label label-link fade-list-item"
          @click.exact="filter(group.slug)"
          @click.right.prevent="edit(group)"
        >
          <span class="label-inner">
            <span
              :style="{
                'background-color': group.color
              }"
              class="label-color"
            />
            {{ group.name }}: {{ group.vehiclesCount }}
          </span>
        </a>
      </transition-group>
    </draggable>
    <a
      v-tooltip="$t('actions.addGroup')"
      class="label label-link"
      @click="add"
    >
      <span class="label-inner">
        <i class="far fa-plus" />
      </span>
    </a>
    <GroupModal
      ref="groupModal"
      :group="selectedGroup"
    />
  </div>
</template>

<script>
import draggable from 'vuedraggable'
import GroupModal from 'frontend/partials/Vehicles/GroupModal'

export default {
  components: {
    GroupModal,
    draggable,
  },
  props: {
    hangarGroups: {
      type: Array,
      default() {
        return []
      },
    },
  },
  data() {
    return {
      selectedGroup: {},
      groups: this.hangarGroups,
      delay: 300,
      clicks: 0,
      timer: null,
    }
  },
  computed: {
    sortIndex() {
      return this.groups.map((item) => item.id)
    },
  },
  watch: {
    hangarGroups() {
      this.groups = this.hangarGroups
    },
    groups() {
      if (this.groups !== this.hangarGroups) {
        this.updateSort()
      }
    },
  },
  methods: {
    filter(filter) {
      const query = JSON.parse(JSON.stringify(this.$route.query.q || {}))

      if ((query.hangarGroupsIn || []).includes(filter)) {
        if (!query.hangarGroupsNotIn) {
          query.hangarGroupsNotIn = []
        }
        query.hangarGroupsNotIn.push(filter)

        const index = query.hangarGroupsIn.findIndex((item) => item === filter)
        if (index > -1) {
          query.hangarGroupsIn.splice(index, 1)
        }
      } else if ((query.hangarGroupsNotIn || []).includes(filter)) {
        const index = query.hangarGroupsNotIn.findIndex((item) => item === filter)
        if (index > -1) {
          query.hangarGroupsNotIn.splice(index, 1)
        }
      } else {
        if (!query.hangarGroupsIn) {
          query.hangarGroupsIn = []
        }
        query.hangarGroupsIn.push(filter)
      }

      this.$router.replace({
        name: this.$route.name,
        query: {
          q: query,
        },
      })
    },
    isActive(group) {
      if (!this.$route.query.q) {
        return false
      }

      const filter = this.$route.query.q.hangarGroupsIn
      if (!filter) {
        return false
      }

      if (filter.includes(group)) {
        return true
      }

      return false
    },
    isInverted(group) {
      if (!this.$route.query.q) {
        return false
      }

      const filter = this.$route.query.q.hangarGroupsNotIn
      if (!filter) {
        return false
      }

      if (filter.includes(group)) {
        return true
      }

      return false
    },
    async updateSort() {
      const response = await this.$api.put('hangar-groups/sort', {
        sorting: this.sortIndex,
      })

      if (response.error) {
        this.$alert({
          text: response.error.response.data.message,
        })
      }
    },
    add() {
      this.selectedGroup = {}
      this.$refs.groupModal.open()
    },
    edit(group) {
      this.selectedGroup = group
      this.$refs.groupModal.open()
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
