<template>
  <section class="container fleet-detail" />
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Watch } from "vue-property-decorator";
import { Getter, Action } from "vuex-class";
import fleetsCollection from "@/frontend/api/collections/Fleets";
import {
  displayConfirm,
  displayAlert,
  displaySuccess,
} from "@/frontend/lib/Noty";
import { useApiClient } from "@/frontend/composables/useApiClient";

const { fleets: fleetService } = useApiClient();

@Component<FleetInvite>()
export default class FleetInvite extends Vue {
  @Getter("currentUser", { namespace: "session" }) currentUser: User;

  @Action("resetInviteToken", { namespace: "fleet" })
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  resetFleetInviteToken: any;

  @Watch("currentUser")
  onCurrentUserChange() {
    this.useInvite();
  }

  mounted() {
    this.useInvite();
  }

  async useInvite() {
    if (!this.currentUser) {
      return;
    }

    try {
      const fleet = await fleetService.findByInvite({
        token: this.$route.params.token,
      });

      if (!fleet) {
        displayAlert({
          text: this.$t("messages.fleetInvite.notFound"),
        });

        this.$router.push({
          name: "home",
        });
      } else {
        displayConfirm({
          text: this.$t("messages.fleetInvite.confirm", {
            fleet: fleet.name,
          }),
          onConfirm: () => {
            this.handleFleetInvite();
          },
          onClose: () => {
            this.$router.push({
              name: "home",
            });
          },
        });
      }
    } catch (error) {
      console.error(error);
    }
  }

  async handleFleetInvite() {
    const member = await this.createMember();

    if (!member) {
      displayAlert({
        text: this.$t("messages.fleetInvite.failure"),
      });

      this.$router.push({
        name: "home",
      });

      return;
    }

    this.resetFleetInviteToken();

    displaySuccess({
      text: this.$t("messages.fleetInvite.used", { fleet: member.fleetName }),
    });

    this.$router.push({
      name: "fleet",
      params: { slug: member.fleetSlug },
    });
  }

  createMember(): Promise<FleetMember | null> {
    return fleetsCollection.useInvite({
      token: this.$route.params.token,
      username: this.currentUser.username,
    });
  }
}
</script>
