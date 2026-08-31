<script lang="ts">
export default {
  name: "FleetInvites",
};
</script>

<script lang="ts" setup>
import BaseTable from "@/shared/components/base/Table/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
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

const { displayAlert, displaySuccess, displayConfirm } = useAppNotifications();

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

/*
 * One named column and the actions slot. The fleet's name needs no cell template
 * -- BaseTable falls back to the record's own attribute -- and the heading
 * label stays empty, as the list this replaced had it.
 */
const tableColumns = computed<BaseTableCol<FleetMember>[]>(() => [
  {
    name: "fleetName",
    label: "",
  },
]);
</script>

<template>
  <section class="container">
    <div class="row lg:justify-center">
      <div class="col-12 col-lg-6">
        <h1>
          {{ t("headlines.fleets.invites") }}
        </h1>
      </div>
    </div>
    <div class="row lg:justify-center">
      <div class="col-12 col-lg-6">
        <BaseTable
          :records="invites || []"
          primary-key="id"
          :columns="tableColumns"
          :empty-visible="!invites?.length && !isLoading"
        >
          <template #actions="{ record }">
            <template v-if="invited(record)">
              <Btn :disabled="submitting" @click="accept(record)">
                <i class="fa-light fa-check" />
                {{ t("actions.fleet.acceptInvite") }}
              </Btn>
              <Btn
                :disabled="submitting"
                :tone="BtnTonesEnum.DANGER"
                @click="decline(record)"
              >
                <i class="fa-light fa-times" />
                {{ t("actions.fleet.declineInvite") }}
              </Btn>
            </template>
            <Btn v-else-if="requested(record)" :disabled="true">
              <i class="fa-light fa-clock" />
              {{ t("labels.fleet.awaitingConfirmation") }}
            </Btn>
          </template>
          <template #empty>
            <Empty :name="t('labels.blank.fleetInvites')" inline />
          </template>
        </BaseTable>

        <Loader :loading="isLoading" :fixed="true" />
      </div>
    </div>
  </section>
</template>
