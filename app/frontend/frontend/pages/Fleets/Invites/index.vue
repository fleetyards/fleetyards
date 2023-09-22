<template>
  <section class="container">
    <div class="row justify-content-lg-center">
      <div class="col-12 col-lg-6">
        <h1>
          {{ $t("headlines.fleets.invites") }}
        </h1>
      </div>
    </div>
    <div class="row justify-content-lg-center">
      <div class="col-12 col-lg-6">
        <Panel>
          <transition-group
            name="fade"
            class="flex-list flex-list-users"
            tag="div"
            appear
          >
            <div key="heading" class="fade-list-item col-12 flex-list-heading">
              <div class="flex-list-row">
                <div class="fleet-name" />
                <div class="actions">
                  {{ $t("labels.actions") }}
                </div>
              </div>
            </div>
            <div
              v-for="(invite, index) in invites"
              :key="`invites-${index}`"
              class="fade-list-item col-12 flex-list-item"
            >
              <div class="flex-list-row">
                <div class="fleet-name">
                  {{ invite.fleet.name }}
                </div>
                <div v-if="invited(invite)" class="actions">
                  <Btn
                    size="small"
                    :disabled="submitting"
                    :inline="true"
                    @click.native="accept(invite)"
                  >
                    <i class="fal fa-check" />
                    {{ $t("actions.fleet.acceptInvite") }}
                  </Btn>
                  <Btn
                    size="small"
                    variant="danger"
                    :disabled="submitting"
                    :inline="true"
                    @click.native="decline(invite)"
                  >
                    <i class="fal fa-times" />
                    {{ $t("actions.fleet.declineInvite") }}
                  </Btn>
                </div>
                <div v-else-if="requested(invite)">
                  <Btn size="small" :disabled="true" :inline="true">
                    <i class="fal fa-clock" />
                    {{ $t("labels.fleet.awaitingConfirmation") }}
                  </Btn>
                </div>
              </div>
            </div>
            <div
              v-if="!invites.length && !loading"
              key="empty"
              class="fade-list-item col-12 flex-list-item"
            >
              <div class="flex-list-row">
                <div class="empty">
                  {{ $t("labels.blank.fleetInvites") }}
                </div>
              </div>
            </div>
          </transition-group>
        </Panel>

        <Loader :loading="loading" :fixed="true" />
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import Vue from "vue";
import { Component } from "vue-property-decorator";
import Btn from "@/frontend/core/components/Btn/index.vue";
import {
  displaySuccess,
  displayAlert,
  displayConfirm,
} from "@/frontend/lib/Noty";
import Panel from "@/frontend/core/components/Panel/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";
import { useApiClient } from "@/frontend/composables/useApiClient";

const { fleetMembership: membershipService } = useApiClient();

@Component<FleetInvites>({
  components: {
    Panel,
    Loader,
    Btn,
  },
})
export default class FleetInvites extends Vue {
  loading = true;

  submitting = false;

  invites: FleetMember[] = [];

  mounted() {
    this.fetch();
  }

  invited(invite) {
    return invite.status === "invited";
  }

  requested(invite) {
    return invite.status === "requested";
  }

  async accept(invite) {
    this.submitting = true;

    try {
      await membershipService.acceptMembership({
        fleetSlug: invite.fleet.slug,
      });

      this.$comlink.$emit("fleet-update");

      displaySuccess({
        text: this.$t("messages.fleet.invites.accept.success"),
      });

      this.$router
        .push({
          name: "fleet",
          params: { slug: invite.fleet.slug },
        })
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        .catch(() => {});
    } catch (error) {
      console.error(error);
      displayAlert({
        text: this.$t("messages.fleet.invites.accept.failure"),
      });
    }

    this.submitting = false;
  }

  async decline(invite) {
    this.submitting = true;

    displayConfirm({
      text: this.$t("messages.confirm.fleet.invites.decline"),
      onConfirm: async () => {
        try {
          await membershipService.declineMembership({
            fleetSlug: invite.fleet.slug,
          });

          this.$comlink.$emit("fleet-update");

          displaySuccess({
            text: this.$t("messages.fleet.invites.decline.success"),
          });
        } catch (error) {
          console.error(error);
          displayAlert({
            text: this.$t("messages.fleet.invites.decline.failure"),
          });
        }

        this.submitting = false;
      },
      onClose: () => {
        this.submitting = false;
      },
    });
  }

  async fetch() {
    this.loading = true;

    const response = await this.$api.get("fleets/invites");

    this.loading = false;

    if (!response.error) {
      this.invites = response.data;
    }
  }
}
</script>
