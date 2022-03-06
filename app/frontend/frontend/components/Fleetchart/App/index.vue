<template>
  <div
    v-if="isShow"
    class="fleetchart-app fade"
    :class="{
      in: isOpen,
      show: isShow,
    }"
  >
    <BtnDropdown size="small" class="fleetchart-app-mode">
      <template #label>
        <template v-if="!mobile">
          {{ $t('labels.fleetchartApp.mode') }}:
        </template>
        {{ $t(`labels.fleetchartApp.modeOptions.${mode}`) }}
      </template>
      <Btn
        v-for="(option, index) in modeOptions"
        :key="`fleetchart-screen-height-drowndown-${index}-${option}`"
        size="small"
        variant="link"
        :active="mode === option"
        @click.native="setMode(option)"
      >
        {{ $t(`labels.fleetchartApp.modeOptions.${option}`) }}
      </Btn>
    </BtnDropdown>

    <Btn
      size="large"
      variant="link"
      class="fleetchart-app-close"
      @click.native="hide"
    >
      <i class="fal fa-times" />
    </Btn>

    <template v-if="innerItems.length && !loading">
      <FleetchartListPanzoom
        v-if="mode == 'panzoom'"
        :items="innerItems"
        :my-ship="myShip"
        :namespace="namespace"
        :download-name="downloadName"
      />
      <FleetchartList
        v-else
        :items="innerItems"
        :my-ship="myShip"
        :namespace="namespace"
        :download-name="downloadName"
      />
    </template>

    <Loader v-else :loading="loading" :fixed="true" />
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import FleetchartListPanzoom from '@/frontend/components/Fleetchart/ListPanzoom/index.vue'
import FleetchartList from '@/frontend/components/Fleetchart/List/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import BtnDropdown from '@/frontend/core/components/BtnDropdown/index.vue'
import Loader from '@/frontend/core/components/Loader/index.vue'

export default {
  name: 'FleetchartApp',

  components: {
    Btn,
    BtnDropdown,
    FleetchartList,
    FleetchartListPanzoom,
    Loader,
  },

  props: {
    downloadName: {
      type: String,
      default: null,
    },

    items: {
      type: Array,
      default() {
        return []
      },
    },

    loading: {
      type: Boolean,
      default: true,
    },

    myShip: {
      type: Boolean,
      default: false,
    },

    namespace: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      innerItems: [],
      isOpen: false,
      isShow: false,
      modeOptions: ['panzoom', 'classic'],
    }
  },
  computed: {
    ...mapGetters(['mobile']),

    mode() {
      return this.$store.getters[`${this.namespace}/fleetchartMode`]
    },

    visible() {
      return this.$store.getters[`${this.namespace}/fleetchartVisible`]
    },
  },

  watch: {
    items() {
      this.updateItems()
    },

    visible() {
      if (this.visible) {
        this.open()
      } else {
        this.close()
      }
    },
  },

  mounted() {
    this.updateItems()

    if (this.$route.query.fleetchart) {
      this.$store.commit(`${this.namespace}/setFleetchartVisible`, true)
    }

    if (this.visible) {
      this.open()
    }
  },

  methods: {
    ...mapActions('app', ['showOverlay', 'hideOverlay']),

    close() {
      this.isOpen = false
      this.hideOverlay()

      this.$nextTick(function onClose() {
        setTimeout(() => {
          this.isShow = false

          this.$emit('fleetchart-closed')
        }, 300)
      })
    },

    hide() {
      this.$store.commit(`${this.namespace}/setFleetchartVisible`, false)
    },

    open() {
      this.isShow = true
      this.showOverlay()

      this.$nextTick(() => {
        // make sure the component is present
        setTimeout(() => {
          // make sure initial animations have enough time
          this.isOpen = true

          this.$emit('fleetchart-opened')
        }, 100)
      })
    },

    setMode(mode) {
      this.$store.commit(`${this.namespace}/setFleetchartMode`, mode)
    },

    updateItems() {
      this.innerItems = JSON.parse(JSON.stringify(this.items)).sort((a, b) => {
        if (a.model) {
          if (a.model.length < b.model.length) {
            return -1
          }

          if (a.model.length > b.model.length) {
            return 1
          }

          return 0
        }

        if (a.length < b.length) {
          return -1
        }

        if (a.length > b.length) {
          return 1
        }

        return 0
      })
    },
  },
}
</script>
