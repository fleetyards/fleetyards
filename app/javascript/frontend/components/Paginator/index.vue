<template>
  <ul
    v-if="total > 1"
    :class="{'pagination-centered': center}"
    class="pagination"
  >
    <li
      :class="{disabled: page < 2}"
      class="arrow"
    >
      <router-link
        v-if="page > 1"
        :to="{ query: { page: page - 1, q }}"
        :aria-label="t('pagination.previous')"
      >
        <i class="fa fa-chevron-left" />
      </router-link>
      <a
        v-else
        :aria-label="t('pagination.previous')"
      >
        <i class="fa fa-chevron-left" />
      </a>
    </li>
    <li :class="{active: page == 1}">
      <router-link :to="{ query: { page: 1, q }}">1</router-link>
    </li>
    <Gap v-if="showStartEndGap" />
    <li
      v-if="total > 2 && !showStartEndGap"
      :class="{active: page == 2}"
    >
      <router-link :to="{ query: { page: 2, q }}">2</router-link>
    </li>
    <li
      v-if="total > 3 && !showStartEndGap && !compact"
      :class="{active: page == 3}"
    >
      <router-link :to="{ query: { page: 3, q }}">3</router-link>
    </li>
    <Gap v-if="showCenterGap" />
    <li v-if="showStartEndGap && !compact">
      <router-link :to="{ query: { page: page - 1, q }}">
        {{ page - 1 }}
      </router-link>
    </li>
    <li
      v-if="showStartEndGap"
      class="active"
    >
      <router-link :to="{ query: { page, q }}">
        {{ page }}
      </router-link>
    </li>
    <li v-if="showStartEndGap && !compact">
      <router-link :to="{ query: { page: page + 1, q }}">
        {{ page + 1 }}
      </router-link>
    </li>
    <li
      v-if="total > 4 && !showStartEndGap && !compact"
      :class="{active: page == total - 2}"
    >
      <router-link :to="{ query: { page: total - 2, q }}">{{ total - 2 }}</router-link>
    </li>
    <li
      v-if="total > 5 && !showStartEndGap"
      :class="{active: page == total - 1}"
    >
      <router-link :to="{ query: { page: total - 1, q }}">{{ total - 1 }}</router-link>
    </li>
    <Gap v-if="showStartEndGap" />
    <li
      v-if="total > 1"
      :class="{active: total == page}"
    >
      <router-link :to="{ query: { page: total, q }}">{{ total }}</router-link>
    </li>
    <li
      :class="{disabled: page + 1 > total}"
      class="arrow"
    >
      <router-link
        v-if="page + 1 <= total"
        :to="{ query: { page: page + 1, q }}"
        :aria-label="t('pagination.next')"
      >
        <i class="fa fa-chevron-right" />
      </router-link>
      <a
        v-else
        :aria-label="t('pagination.next')"
      >
        <i class="fa fa-chevron-right" />
      </a>
    </li>
  </ul>
  <div v-else/>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Gap from 'frontend/components/Paginator/Gap'

export default {
  components: {
    Gap,
  },
  mixins: [I18n],
  props: {
    page: {
      type: Number,
      default: 1,
    },
    total: {
      type: Number,
      default: null,
    },
    totalVisible: {
      type: Number,
      default: 7,
    },
    center: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    q() {
      return this.$route.query.q
    },
    compact() {
      return document.documentElement.clientWidth < 992
    },
    showGap() {
      return this.total >= this.totalVisible
    },
    showStartEndGap() {
      if (this.compact) {
        return this.showGap && this.page > 2 && this.page < this.total - 1
      }
      return this.showGap && this.page > 3 && this.page < this.total - 2
    },
    showCenterGap() {
      if (this.compact) {
        return this.showGap && (this.page <= 2 || this.page >= this.total - 1)
      }
      return this.showGap && (this.page <= 3 || this.page >= this.total - 2)
    },
  },
}
</script>
