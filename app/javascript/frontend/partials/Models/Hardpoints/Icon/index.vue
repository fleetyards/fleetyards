<template>
  <div
    :class="{
      'hardpoint-empty': hardpoint.defaultEmpty,
      'hardpoint-with-component': !!hardpoint.component,
    }"
    class="hardpoint-icon"
  >
    <svg
      class="hardpoint-icon"
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 47.98 55.4">
      <rect
        v-if="hardpoint.quantity && hardpoint.quantity > 1"
        class="c-specbox__background-dot hardpoint-icon-part"
        x="22.85"
        y="26.56"
        width="2.29"
        height="2.29"
      />
      <g class="hardpoint-icon-empty-bg">
        <path
          :d="hardpointIconBg"
          class="b hardpoint-icon-part"
          transform="translate(0 0)"/>
        <polygon
          class="hardpoint-icon-part"
          points="23.99 55.4 0 41.55 0 13.85 23.99 0 47.98 13.85 47.98 41.55 23.99 55.4"/>
      </g>
      <polygon
        class="hardpoint-icon-bg"
        points="23.99 55.4 0 41.55 0 13.85 23.99 0 47.98 13.85 47.98 41.55 23.99 55.4"/>
      <g
        v-if="hardpoint.quantity && hardpoint.quantity > 1"
        class="hardpoint-icon-part hardpoint-icon-quantity"
      >
        <polygon
          class="hardpoint-icon-part"
          points="23.98 28 0 13.85 23.99 0 47.98 13.85 23.98 28"/>
        <rect
          class="hardpoint-icon-part "
          x="23.49"
          y="27.5"
          width="1"
          height="1"/>
      </g>
      <circle
        v-if="hardpoint.mounts && hardpoint.mounts > 1"
        class="hardpoint-icon-part hardpoint-icon-mounts"
        cx="37.5"
        cy="6.38"
        r="6.38"
      />
      <polygon
        v-if="hardpoint.category"
        class="hardpoint-icon-part hardpoint-icon-category"
        points="14,0 7,0 3.5,6.1 7,12.1 14,12.1 17.5,6.1"
      />
      <g>
        <rect
          class="hardpoint-icon-part"
          x="23.48"
          width="1"
          height="1"/>
        <rect
          class="hardpoint-icon-part"
          x="23.49"
          y="54.39"
          width="1"
          height="1"/>
        <rect
          class="hardpoint-icon-part"
          y="40.55"
          width="1"
          height="1"/>
        <rect
          class="hardpoint-icon-part"
          y="13.84"
          width="1"
          height="1"/>
        <rect
          class="hardpoint-icon-part"
          x="46.98"
          y="13.85"
          width="1"
          height="1"/>
        <rect
          class="hardpoint-icon-part"
          x="46.98"
          y="40.56"
          width="1"
          height="1"/>
      </g>
    </svg>
    <div
      v-if="hardpoint.size && hardpoint.size !== '-'"
      :class="{
        'hardpoint-size-label-small': (hardpoint.quantity && hardpoint.quantity > 1)
      }"
      class="hardpoint-label hardpoint-size-label"
    >
      {{ hardpoint.size }}
    </div>
    <div
      v-if="hardpoint.category"
      class="hardpoint-label hardpoint-category-label"
    >
      {{ hardpoint.category }}
    </div>
    <div
      v-if="hardpoint.quantity && hardpoint.quantity > 1"
      class="hardpoint-label hardpoint-quantity-label"
    >
      {{ quantity }}
    </div>
    <div
      v-if="hardpoint.mounts && hardpoint.mounts > 1"
      class="hardpoint-label hardpoint-mounts-label"
    >
      {{ hardpoint.mounts }}
    </div>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'

export default {
  mixins: [I18n],
  props: {
    hardpoint: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hardpointIconBg() {
      return 'M24,0,22.26,1l.5.87L24,1.15,25.4,2l.5-.87L24.17.1l-.06.1L24,0ZM20.53,2,18.79,3l.5.87,1.73-1L20.53,2ZM17.06,4,15.33,5l.5.87,1.73-1L17.06,4ZM13.6,6,11.87,7l.5.87,1.73-1L13.6,6ZM10.13,8h-.06L8.4,9l.5.87,1.73-1L10.13,8ZM6.67,10,4.94,11l.5.87,1.73-1L6.67,10ZM3.21,12,1.47,13l.5.87,1.73-1L3.21,12ZM1,14.15H0v2H1v-2Zm0,4H0v2H1v-2Zm0,4H0v2H1v-2Zm0,4H0v2H1v-2Zm0,4H0v2H1v-2Zm0,4H0v2H1v-2Zm0,4H0v2H1v-2ZM1,41l-.5.87,1.29.75h0l.43.25.5-.87L1,41Zm3.46,2-.5.87,1.73,1,.5-.87L4.48,43Zm3.46,2-.5.87,1.73,1,.5-.87L7.95,45Zm3.46,2-.5.87,1.73,1,.5-.87-1.73-1Zm3.46,2-.5.87,1.73,1,.5-.87-1.73-1Zm3.46,2-.5.87,1.73,1,.5-.87-1.73-1Zm3.46,2-.5.87,1.73,1,.5-.87L21.8,53Zm4.2.1-1.73,1,.5.87.84-.49h0L26.5,54l-.5-.87Zm3.46-2-1.73,1,.5.87L30,52l-.5-.87Zm3.46-2-1.73,1,.5.87,1.73-1-.5-.87Zm3.46-2-1.73,1,.5.87,1.73-1-.5-.87Zm3.46-2-1.73,1,.5.87,1.73-1-.5-.87Zm3.46-2-1.73,1,.5.87,1.73-1-.5-.87Zm3.46-2-1.73,1,.5.87,1.73-1-.5-.87ZM48,38.35H47v2h1v-2Zm0-4H47v2h1v-2Zm0-4H47v2h1v-2Zm0-4H47v2h1v-2Zm0-4H47v2h1v-2Zm0-4H47v2h1v-2Zm0-4H47v2h1v-2ZM45,12.1l-.5.87,1.73,1,.5-.87-.8-.46L45,12.1Zm-3.46-2L41,11l1.73,1,.5-.87-1.73-1ZM38,8.1l-.5.87,1.73,1,.5-.87L38,8.1Zm-3.46-2-.5.87,1.73,1,.5-.87-1.73-1Zm-3.46-2L30.6,5l1.73,1,.5-.87-1.73-1Zm-3.46-2-.5.87,1.73,1,.5-.87-1.73-1Z'
    },
    quantity() {
      if (this.hardpoint.type !== 'missiles' || !this.hardpoint.component || this.hardpoint.size === this.hardpoint.component.size) {
        return this.hardpoint.quantity
      }
      return Math.floor(this.hardpoint.quantity
        / ((this.hardpoint.size - this.hardpoint.component.size) * 2))
    },
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
