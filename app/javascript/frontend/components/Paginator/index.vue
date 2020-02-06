<template>
  <ul
    v-if="total > 1"
    :class="{
      'pagination-centered': center,
      'pagination-right': right,
    }"
    class="pagination"
  >
    <li :class="{ disabled: page < 2 }" class="arrow">
      <router-link
        v-if="page > 1"
        :to="{ query: { page: page - 1, q } }"
        :aria-label="$t('pagination.previous')"
      >
        <i class="fa fa-chevron-left" />
      </router-link>
      <a v-else :aria-label="$t('pagination.previous')">
        <i class="fa fa-chevron-left" />
      </a>
    </li>
    <li v-if="page > 1">
      <router-link :to="{ query: { page: 1, q } }">
        1
      </router-link>
    </li>
    <Gap v-if="showLeftGap" />
    <li v-for="n in leftPagesCount" :key="`left-${n}`">
      <router-link
        :to="{ query: { page: page + (n - (leftPagesCount + 1)), q } }"
      >
        {{ page + (n - (leftPagesCount + 1)) }}
      </router-link>
    </li>
    <li class="active">
      <router-link :to="{ query: { page, q } }">
        {{ page }}
      </router-link>
    </li>
    <li v-for="n in rightPagesCount" :key="`right-${n}`">
      <router-link :to="{ query: { page: page + n, q } }">
        {{ page + n }}
      </router-link>
    </li>
    <Gap v-if="showRightGap" />
    <li v-if="page < total">
      <router-link :to="{ query: { page: total, q } }">
        {{ total }}
      </router-link>
    </li>
    <li :class="{ disabled: page + 1 > total }" class="arrow">
      <router-link
        v-if="page + 1 <= total"
        :to="{ query: { page: page + 1, q } }"
        :aria-label="$t('pagination.next')"
      >
        <i class="fa fa-chevron-right" />
      </router-link>
      <a v-else :aria-label="$t('pagination.next')">
        <i class="fa fa-chevron-right" />
      </a>
    </li>
  </ul>
  <div v-else />
</template>

<script>
import Gap from 'frontend/components/Paginator/Gap'

export default {
  components: {
    Gap,
  },
  props: {
    page: {
      type: Number,
      default: 1,
    },
    total: {
      type: Number,
      default: null,
    },
    visible: {
      type: Number,
      default: 7,
    },
    center: {
      type: Boolean,
      default: false,
    },
    right: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    mobile() {
      return document.documentElement.clientWidth < 992
    },
    q() {
      return this.$route.query.q
    },
    totalVisible() {
      if (this.mobile) {
        return Math.min(5, this.total)
      }
      return Math.min(Math.max(5, this.visible), this.total)
    },
    leftPagesCount() {
      let leftPagesCount = this.totalVisible - 2
      if (this.page < this.total - 2) {
        leftPagesCount = Math.floor(leftPagesCount / 2)
      }
      if (this.showLeftGap) {
        leftPagesCount -= 1
      }
      if (this.page < 4) {
        leftPagesCount = 1
      }
      if (this.page < 3) {
        leftPagesCount = 0
      }
      if (this.page === this.total - 1 && this.total !== 4) {
        leftPagesCount -= 1
      }
      if (this.page === this.total - 2 && this.total !== 5) {
        leftPagesCount -= 2
      }
      return Math.max(leftPagesCount, 0)
    },
    rightPagesCount() {
      let rightPagesCount = this.totalVisible - 2
      if (this.page > 3) {
        rightPagesCount = Math.floor(rightPagesCount / 2)
      }
      if (this.showRightGap) {
        rightPagesCount -= 1
      }
      if (this.page > this.total - 3) {
        rightPagesCount = 1
      }
      if (this.page > this.total - 2) {
        rightPagesCount = 0
      }
      if (this.page === 2 && this.total !== 4) {
        rightPagesCount -= 1
      }
      if (this.page === 3 && this.total !== 5) {
        rightPagesCount -= 2
      }
      return Math.max(rightPagesCount, 0)
    },
    showGap() {
      return this.total > this.totalVisible
    },
    showLeftGap() {
      return this.showGap && this.page > Math.round(this.totalVisible / 2)
    },
    showRightGap() {
      return (
        this.showGap &&
        this.page < this.total - (Math.round(this.totalVisible / 2) - 1)
      )
    },
  },
}
</script>
