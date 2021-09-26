<template>
  <BtnDropdown
    v-if="mobile"
    :mobile-block="true"
    size="small"
    class="labels-dropdown"
  >
    <template slot="label">
      {{ $t('labels.groups') }}
    </template>
    <Btn
      v-for="group in groups"
      :key="group.id"
      variant="dropdown"
      class="labels-dropdown-item"
      :class="{
        active: isActive(group.slug),
        inverted: isInverted(group.slug),
      }"
      @click.exact.native="filter(group.slug)"
    >
      <span
        :style="{
          'background-color': group.color,
        }"
        class="label-color"
      />
      <span class="label-text-wrapper">
        <span class="label-text">
          {{ group.name }}
        </span>
        <span class="label-count">{{ groupCount(group).count }}</span>
      </span>
    </Btn>
  </BtnDropdown>
  <div v-else class="labels">
    <h3 v-if="groups.length || editable" class="label-title">
      {{ $t('labels.groups') }}:
    </h3>
    <draggable v-model="groups" @start="drag = true" @end="drag = false">
      <transition-group name="fade-list" appear>
        <a
          v-for="group in groups"
          :key="group.id"
          :class="{
            active: isActive(group.slug),
            inverted: isInverted(group.slug),
          }"
          class="label label-link fade-list-item"
          @click.exact="filter(group.slug)"
          @click.right.prevent="openGroupModal(group)"
          @mouseenter="highlight(group)"
          @mouseleave="highlight(null)"
        >
          <span class="label-inner">
            <span
              :style="{
                'background-color': group.color,
              }"
              class="label-color"
            />
            {{ group.name }}: {{ groupCount(group).count }}
          </span>
        </a>
      </transition-group>
    </draggable>
    <a
      v-if="editable"
      v-tooltip="$t('actions.addGroup')"
      class="label label-link"
      @click="openGroupModal()"
    >
      <span class="label-inner">
        <i class="far fa-plus" />
      </span>
    </a>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import draggable from 'vuedraggable'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import Btn from 'frontend/core/components/Btn'
import { displayAlert } from 'frontend/lib/Noty'
import { Getter } from 'vuex-class'

@Component<GroupLabels>({
  components: {
    BtnDropdown,
    Btn,
    draggable,
  },
})
export default class GroupLabels extends Vue {
  groups: HangarGroup[] = []

  @Prop({
    default() {
      return []
    },
  })
  hangarGroups: HangarGroup[]

  @Prop({
    default() {
      return []
    },
  })
  hangarGroupCounts: Array

  @Prop({ default: false }) editable!: boolean

  @Getter('mobile') mobile

  get sortIndex() {
    return this.groups.map(item => item.id)
  }

  mounted() {
    this.groups = this.hangarGroups
  }

  @Watch('hangarGroups')
  onHangarGroupsChange() {
    this.groups = this.hangarGroups
  }

  @Watch('groups')
  onGroupsFake() {
    if (this.groups !== this.hangarGroups) {
      this.updateSort()
    }
  }

  groupCount(group) {
    return (
      this.hangarGroupCounts.find(count => count.id === group.id) || {
        count: 0,
      }
    )
  }

  filter(filter) {
    const query = JSON.parse(JSON.stringify(this.$route.query.q || {}))

    if ((query.hangarGroupsIn || []).includes(filter)) {
      if (!query.hangarGroupsNotIn) {
        query.hangarGroupsNotIn = []
      }
      query.hangarGroupsNotIn.push(filter)

      const index = query.hangarGroupsIn.findIndex(item => item === filter)
      if (index > -1) {
        query.hangarGroupsIn.splice(index, 1)
      }
    } else if ((query.hangarGroupsNotIn || []).includes(filter)) {
      const index = query.hangarGroupsNotIn.findIndex(item => item === filter)
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
  }

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
  }

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
  }

  async updateSort() {
    const response = await this.$api.put('hangar-groups/sort', {
      sorting: this.sortIndex,
    })

    if (response.error) {
      displayAlert({
        text: response.error.response.data.message,
      })
    }
  }

  openGroupModal(hangarGroup) {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Vehicles/GroupModal'),
      props: {
        hangarGroup,
      },
    })
  }

  highlight(group) {
    this.$emit('highlight', group)
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
