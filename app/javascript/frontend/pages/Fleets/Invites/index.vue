<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1>
          {{ $t('headlines.fleets.invites') }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <Panel v-if="currentUser && fleetInvites.length">
          <transition-group
            name="fade"
            class="flex-list flex-list-users"
            tag="div"
            appear
          >
            <div
              key="heading"
              class="fade-list-item col-xs-12 col-md-8 col-md-offset-2 flex-list-heading"
            >
              <div class="flex-list-row">
                <div class="name" />
                <div class="actions">
                  {{ $t('labels.actions') }}
                </div>
              </div>
            </div>
            <div
              v-for="(fleet, index) in fleetInvites"
              :key="`invites-${index}`"
              class="fade-list-item col-xs-12 col-md-8 col-md-offset-2 flex-list-item"
            >
              <div class="flex-list-row">
                <div class="name">
                  {{ fleet.name }}
                </div>
                <div class="actions">
                  <Btn
                    size="small"
                    inline
                    @click.native="accept(fleet)"
                  >
                    <i class="fal fa-chevron-up" />
                  </Btn>
                </div>
              </div>
            </div>
          </transition-group>
        </Panel>
      </div>
    </div>
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Panel from 'frontend/components/Panel'
import Btn from 'frontend/components/Btn'

export default {
  name: 'FleetInvites',

  components: {
    Panel,
    Btn,
  },

  mixins: [
    MetaInfo,
  ],

  computed: {
    ...mapGetters('session', [
      'currentUser',
    ]),

    fleetInvites() {
      return this.currentUser.fleets.filter((item) => !item.accepted) || []
    },
  },
}
</script>
