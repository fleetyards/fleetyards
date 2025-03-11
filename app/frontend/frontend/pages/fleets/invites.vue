<script lang="ts">
export default {
  name: "FleetInvites",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/Panel/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { type FleetMember } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useFleetInvites as useFleetInvitesQuery,
  useAcceptFleetMembership as useAcceptFleetMembershipMutation,
  useDeclineFleetMembership as useDeclineFleetMembershipMutation,
} from "@/services/fyApi";

const { t } = useI18n();

const { displayAlert, displaySuccess } = useAppNotifications();

const submitting = ref(false);

const invited = (invite: FleetMember) => {
  return invite.status === "invited";
};

const requested = (invite: FleetMember) => {
  return invite.status === "requested";
};

const comlink = useComlink();

const router = useRouter();

const acceptMutation = useAcceptFleetMembershipMutation();

const accept = async (invite: FleetMember) => {
  submitting.value = true;

  await acceptMutation
    .mutateAsync({
      fleetSlug: invite.fleetSlug,
    })
    .then(async () => {
      comlink.emit("fleet-update");

      displaySuccess({
        text: t("messages.fleet.invites.accept.success"),
      });

      await router
        .push({
          name: "fleet",
          params: { slug: invite.fleetSlug },
        })
        .catch(() => {});
    })
    .catch((error) => {
      console.error(error);
      displayAlert({
        text: t("messages.fleet.invites.accept.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
};

const declineMutation = useDeclineFleetMembershipMutation();

const decline = async (invite: FleetMember) => {
  submitting.value = true;

  displayConfirm({
    text: t("messages.confirm.fleet.invites.decline"),
    onConfirm: async () => {
      await declineMutation
        .mutateAsync({
          fleetSlug: invite.fleetSlug,
        })
        .then(() => {
          comlink.emit("fleet-update");

          displaySuccess({
            text: t("messages.fleet.invites.decline.success"),
          });
        })
        .catch((error) => {
          console.error(error);
          displayAlert({
            text: t("messages.fleet.invites.decline.failure"),
          });
        })
        .finally(() => {
          submitting.value = false;
        });
    },
    onClose: () => {
      submitting.value = false;
    },
  });
};

const { data: invites, isLoading } = useFleetInvitesQuery();
</script>

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
                    :size="BtnSizesEnum.SMALL"
                    :disabled="submitting"
                    :inline="true"
                    @click="accept(invite)"
                  >
                    <i class="fal fa-check" />
                    {{ t("actions.fleet.acceptInvite") }}
                  </Btn>
                  <Btn
                    :size="BtnSizesEnum.SMALL"
                    :variant="BtnVariantsEnum.DANGER"
                    :disabled="submitting"
                    :inline="true"
                    @click="decline(invite)"
                  >
                    <i class="fal fa-times" />
                    {{ t("actions.fleet.declineInvite") }}
                  </Btn>
                </div>
                <div v-else-if="requested(invite)">
                  <Btn
                    :size="BtnSizesEnum.SMALL"
                    :disabled="true"
                    :inline="true"
                  >
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
