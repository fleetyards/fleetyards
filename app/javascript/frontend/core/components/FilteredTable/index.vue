<template>
  <Panel>
    <transition-group
      name="fade"
      class="filtered-table"
      tag="div"
      :appear="true"
    >
      <div
        v-if="internalSelected.length"
        key="selected-header"
        class="fade-list-item col-12 filtered-table-selected"
      >
        <div class="filtered-table-row">
          <div>
            {{
              $t('labels.table.selected', { count: internalSelected.length })
            }}
            <Btn
              v-tooltip="$t('actions.unselect')"
              size="small"
              variant="link"
              :inline="true"
              @click.native="resetSelected"
            >
              <i class="fal fa-times" />
            </Btn>
          </div>
          <slot
            :selectedCount="internalSelected.length"
            name="selected-actions"
          />
        </div>
      </div>
      <div key="heading" class="fade-list-item col-12 filtered-table-heading">
        <div class="filtered-table-row">
          <div v-if="selectable && !mobile">
            <Checkbox :value="allSelected" @input="onAllSelectedChange" />
          </div>
          <div
            v-for="(column, index) in columns"
            :key="`filtered-table-heading-${uuid}-${index}-${column.name}`"
            :class="column.class"
            :style="{
              'flex-grow': column.flexGrow,
              'width': column.width,
            }"
          >
            {{ column.label }}
          </div>
        </div>
      </div>
      <template v-if="records.length">
        <div
          v-for="(record, index) in records"
          :key="record[primaryKey]"
          class="fade-list-item col-12 filtered-table-item"
        >
          <slot :record="record" :index="index">
            <div class="filtered-table-row">
              <div v-if="selectable && !mobile">
                <Checkbox
                  v-model="internalSelected"
                  :checkbox-value="record.id"
                />
              </div>
              <template v-for="(column, colIndex) in columns">
                <div
                  :key="
                    `filtered-table-item-${uuid}-${colIndex}-${column.name}`
                  "
                  :class="column.class"
                  :style="{
                    'flex-grow': column.flexGrow,
                    'width': column.width,
                  }"
                >
                  <slot :record="record" :name="`col-${column.name}`">
                    {{ record[column.field || column.name] }}
                  </slot>
                </div>
              </template>
            </div>
          </slot>
        </div>
      </template>
      <div
        v-if="loading"
        key="loading-row"
        class="fade-list-item col-12 filtered-table-loader"
      >
        <div class="filtered-table-row">
          <Loader :loading="loading" :inline="true" />
        </div>
      </div>
      <div
        v-else-if="emptyBoxVisible"
        key="empty-row"
        class="fade-list-item col-12 filtered-table-empty"
      >
        <div class="filtered-table-row">
          {{ $t('texts.empty.info') }}
        </div>
      </div>
    </transition-group>
  </Panel>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import Panel from 'frontend/core/components/Panel'
import Checkbox from 'frontend/core/components/Form/Checkbox'
import Loader from 'frontend/core/components/Loader'
import Btn from 'frontend/core/components/Btn'
import { uniq as uniqArray } from 'frontend/utils/Array'

export type FilteredTableColumn = {
  name: string
  class: maybe<string>
  label: string
}

@Component<FilteredTable>({
  components: {
    Panel,
    Loader,
    Checkbox,
    Btn,
  },
})
export default class FilteredTable extends Vue {
  @Prop({ required: true }) records!: any[]

  @Prop({ required: true }) columns!: FilteredTableColumn[]

  @Prop({ required: true }) primaryKey!: string

  @Prop({ default: false }) loading!: boolean

  @Prop({ default: false }) emptyBoxVisible!: boolean

  @Prop({ default: false }) selectable!: boolean

  @Prop({
    default: () => {
      return []
    },
  })
  selected!: string[]

  internalSelected: string[] = []

  @Getter('mobile') mobile

  get uuid() {
    return this._uid
  }

  get allSelected() {
    if (!this.records.length) {
      return false
    }

    return this.records
      .map(record => record.id)
      .every(recordId => {
        return this.internalSelected.includes(recordId)
      })
  }

  get scopedSlots() {
    const itemSlotPrefix = 'col.'
    return Object.keys(this.$scopedSlots)
      .filter(name => name.startsWith(itemSlotPrefix))
      .map(name => name.substring(itemSlotPrefix.length))
  }

  @Watch('selected')
  onSelectedChange() {
    this.internalSelected = this.selected
  }

  @Watch('internalSelected')
  onInternalSelectedChange() {
    this.$emit('selected-change', this.internalSelected)
  }

  onAllSelectedChange(value) {
    if (value) {
      this.internalSelected = [
        ...this.internalSelected,
        ...this.records.map(record => record.id),
      ].filter(uniqArray)
    } else {
      this.internalSelected = [...this.internalSelected].filter(selected => {
        return !this.records.map(record => record.id).includes(selected)
      })
    }
  }

  resetSelected() {
    this.internalSelected = []
  }
}
</script>
