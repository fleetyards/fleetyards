<template>
  <transition name="fade">
    <div v-if="visible" class="empty-box">
      <Box class="info" :large="true">
        <h1>{{ $t('headlines.empty') }}</h1>
        <template v-if="isQueryPresent">
          <p>{{ $t('texts.empty.query') }}</p>
          <div slot="footer" class="float-sm-right">
            <Btn v-if="isPagePresent" @click.native="resetPage">
              {{ $t('actions.empty.resetPage') }}
            </Btn>
            <Btn :to="{ name: this.$route.name }" :exact="true">
              {{ $t('actions.empty.reset') }}
            </Btn>
          </div>
        </template>
        <p v-else>
          {{ $t('texts.empty.info') }}
        </p>
      </Box>
    </div>
  </transition>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Box from 'frontend/components/Box'
import Btn from 'frontend/components/Btn'

@Component<EmptyBox>({
  components: {
    Box,
    Btn,
  },
})
export default class EmptyBox extends Vue {
  @Prop({ required: true }) visible: boolean

  @Prop({ default: false }) ignoreFilter: boolean

  get isPagePresent() {
    return !!this.$route.query.page
  }

  get isQueryPresent() {
    return !this.ignoreFilter && Object.keys(this.$route.query).length > 0
  }

  resetPage() {
    const query = {
      ...JSON.parse(JSON.stringify(this.$route.query)),
    }

    if (query.page) {
      delete query.page
    }

    this.$router
      .replace({
        name: this.$route.name,
        query: {
          ...query,
          q: this.$route.query.q || {},
        },
      })
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch(_err => {})
  }
}
</script>
