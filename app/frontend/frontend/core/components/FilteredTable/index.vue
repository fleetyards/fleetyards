<template>
  <Panel :class="listClasses">
    <div class="filtered-table-wrapper">
      <transition-group
        name="fade"
        class="filtered-table"
        tag="div"
        :appear="true"
      >
        <div
          v-if="internalSelected.length"
          key="selected-header"
          class="fade-list-item filtered-table-selected"
        >
          <div class="filtered-table-row">
            <div class="selected-count">
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
        <div key="heading" class="fade-list-item filtered-table-heading">
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
            class="fade-list-item filtered-table-item"
            :class="listItemClasses"
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
                    :key="`filtered-table-item-${uuid}-${colIndex}-${column.name}`"
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
          class="fade-list-item filtered-table-loader"
        >
          <div class="filtered-table-row">
            <Loader :loading="loading" :inline="true" />
          </div>
        </div>
        <div
          v-else-if="emptyBoxVisible"
          key="empty-row"
          class="fade-list-item filtered-table-empty"
        >
          <div class="filtered-table-row">
            {{ $t('texts.empty.info') }}
          </div>
        </div>
      </transition-group>
    </div>
  </Panel>
</template>

<script>
import { mapGetters } from 'vuex'
import Panel from '@/frontend/core/components/Panel/index.vue'
import Checkbox from '@/frontend/core/components/Form/Checkbox/index.vue'
import Loader from '@/frontend/core/components/Loader/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import { uniq as uniqArray } from '@/frontend/utils/Array'

export default {
  name: 'FilteredTable',

  components: {
    Btn,
    Checkbox,
    Loader,
    Panel,
  },

  props: {
    columns: {
      type: Array,
      required: true,
    },

    emptyBoxVisible: {
      default: false,
      type: Boolean,
    },

    listClasses: {
      type: [Array, Object, String],
      default: null,
    },

    listItemClasses: {
      type: [Array, Object, String],
      default: null,
    },

    loading: {
      type: Boolean,
      default: false,
    },

    primaryKey: {
      type: String,
      required: true,
    },

    records: {
      type: Array,
      required: true,
    },

    selectable: {
      type: Boolean,
      default: false,
    },

    selected: {
      default() {
        return []
      },
      type: Array,
    },
  },

  data() {
    return {
      internalSelected: [],
    }
  },

  computed: {
    ...mapGetters(['mobile']),

    allSelected() {
      if (!this.records.length) {
        return false
      }

      return this.records
        .map((record) => record.id)
        .every((recordId) => this.internalSelected.includes(recordId))
    },

    scopedSlots() {
      const itemSlotPrefix = 'col.'
      return Object.keys(this.$scopedSlots)
        .filter((name) => name.startsWith(itemSlotPrefix))
        .map((name) => name.substring(itemSlotPrefix.length))
    },

    uuid() {
      return this._uid
    },
  },

  watch: {
    internalSelected() {
      this.$emit('selected-change', this.internalSelected)
    },

    selected() {
      this.internalSelected = this.selected
    },
  },

  methods: {
    onAllSelectedChange(value) {
      if (value) {
        this.internalSelected = [
          ...this.internalSelected,
          ...this.records.map((record) => record.id),
        ].filter(uniqArray)
      } else {
        this.internalSelected = [...this.internalSelected].filter(
          (selected) =>
            !this.records.map((record) => record.id).includes(selected)
        )
      }
    },

    resetSelected() {
      this.internalSelected = []
    },
  },
}
</script>
