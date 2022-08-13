export default {
  name: 'ServiceWorkerMixin',
  data() {
    return {
      updateSW: undefined,
      offlineReady: false,
      needRefresh: false,
    }
  },
  async mounted() {
    try {
      // eslint-disable-next-line import/no-unresolved
      const { registerSW } = await import('virtual:pwa-register')

      this.updateSW = registerSW({
        immediate: true,
        onOfflineReady: this.onOfflineReadyFn,
        onNeedRefresh: this.onNeedRefreshFn,
      })
    } catch {
      console.info('PWA disabled.')
    }
  },
  methods: {
    async closePromptUpdateSW() {
      this.offlineReady = false
      this.needRefresh = false
    },

    onOfflineReadyFn() {
      this.offlineReady = true
      console.info('onOfflineReady')
    },

    onNeedRefreshFn() {
      this.needRefresh = true
      console.info('onNeedRefresh')
    },

    updateServiceWorker() {
      if (this.updateSW) {
        this.updateSW(true)
      }
    },
  },
}
