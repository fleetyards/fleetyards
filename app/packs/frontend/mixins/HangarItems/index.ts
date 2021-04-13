import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import HangarItemsCollection from 'frontend/api/collections/HangarItems'

@Component<HangarItemsMixin>({})
export default class HangarItemsMixin extends Vue {
  @Getter('isAuthenticated', { namespace: 'session' }) isAuthenticated

  @Watch('$route')
  onRouteChange() {
    this.fetchHangarItems()
  }

  @Watch('isAuthenticated')
  onSessionChange() {
    this.fetchHangarItems()
  }

  created() {
    this.fetchHangarItems()
  }

  async fetchHangarItems() {
    if (!this.isAuthenticated) {
      return
    }

    await this.$store.dispatch(
      'hangar/saveHangar',
      await HangarItemsCollection.findAll(),
    )
  }
}
