<template>
  <section class="container">
    <div class="row justify-content-lg-center">
      <div class="col-12 col-lg-6">
        <h1>
          {{ t("headlines.fleets.invites") }}
        </h1>
      </div>
    </div>
    <div class="row justify-content-lg-center">
      <div class="col-12 col-lg-6">
        <Panel slim>
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
                  {{ t("labels.actions") }}
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
                  {{ invite.fleetName }}
                </div>
                <div v-if="invited(invite)" class="actions">
                  <Btn
                    size="small"
                    :disabled="submitting"
                    :inline="true"
                    @click="accept(invite)"
                  >
                    <i class="fal fa-check" />
                    {{ t("actions.fleet.acceptInvite") }}
                  </Btn>
                  <Btn
                    size="small"
                    variant="danger"
                    :disabled="submitting"
                    :inline="true"
                    @click="decline(invite)"
                  >
                    <i class="fal fa-times" />
                    {{ t("actions.fleet.declineInvite") }}
                  </Btn>
                </div>
                <div v-else-if="requested(invite)">
                  <Btn size="small" :disabled="true" :inline="true">
                    <i class="fal fa-clock" />
                    {{ t("labels.fleet.awaitingConfirmation") }}
                  </Btn>
                </div>
              </div>
            </div>
            <div
              v-if="!invites?.length && !isLoading"
              key="empty"
              class="fade-list-item col-12 flex-list-item"
            >
              <div class="flex-list-row">
                <div class="empty">
                  {{ t("labels.blank.fleetInvites") }}
                </div>
              </div>
            </div>
          </transition-group>
        </Panel>

        <Loader :loading="isLoading" :fixed="true" />
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { type FleetMember } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useNoty } from "@/shared/composables/useNoty";
import { useQuery } from "@tanstack/vue-query";

const { t } = useI18n();

const { displayAlert, displayConfirm, displaySuccess } = useNoty();

const submitting = ref(false);

const invited = (invite: FleetMember) => {
  return invite.status === "invited";
};

const requested = (invite: FleetMember) => {
  return invite.status === "requested";
};

const comlink = useComlink();

const { fleetMembership: membershipService, fleets: fleetsService } =
  useApiClient();

const router = useRouter();

const accept = async (invite: FleetMember) => {
  submitting.value = true;

  try {
    await membershipService.acceptMembership({
      fleetSlug: invite.fleetSlug,
    });

    comlink.emit("fleet-update");

    displaySuccess({
      text: t("messages.fleet.invites.accept.success"),
    });

    router
      .push({
        name: "fleet",
        params: { slug: invite.fleetSlug },
      })
      .catch(() => {});
  } catch (error) {
    console.error(error);
    displayAlert({
      text: t("messages.fleet.invites.accept.failure"),
    });
  }

  submitting.value = false;
};

const decline = async (invite: FleetMember) => {
  submitting.value = true;

  displayConfirm({
    text: t("messages.confirm.fleet.invites.decline"),
    onConfirm: async () => {
      try {
        await membershipService.declineMembership({
          fleetSlug: invite.fleetSlug,
        });

        comlink.emit("fleet-update");

        displaySuccess({
          text: t("messages.fleet.invites.decline.success"),
        });
      } catch (error) {
        console.error(error);
        displayAlert({
          text: t("messages.fleet.invites.decline.failure"),
        });
      }

      submitting.value = false;
    },
    onClose: () => {
      submitting.value = false;
    },
  });
};

const { data: invites, isLoading } = useQuery({
  queryKey: ["myFleetInvites"],
  queryFn: () => fleetsService.fleetInvites(),
});
</script>

<script lang="ts">
export default {
  name: "FleetInvites",
};
</script>
