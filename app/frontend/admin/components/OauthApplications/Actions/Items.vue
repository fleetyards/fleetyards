<script lang="ts">
export default {
  name: "OauthApplicationActionItems",
};
</script>

<script lang="ts" setup>
import {
  type OauthApplication,
  useApproveOauthApplication,
  useDestroyOauthApplication,
  getOauthApplicationsQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  oauthApplication: OauthApplication;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm } = useAppNotifications();
const { extend } = useBreadCrumbs();

const comlink = useComlink();
const queryClient = useQueryClient();

const approveMutation = useApproveOauthApplication();

// Approving is offered whenever the application is not already approved, so a
// refusal can be taken back without a separate control.
const canApprove = computed(() => props.oauthApplication.state !== "approved");
const canReject = computed(() => props.oauthApplication.state !== "rejected");

const approve = async () => {
  await approveMutation.mutateAsync({ id: props.oauthApplication.id });
  void queryClient.invalidateQueries({
    queryKey: getOauthApplicationsQueryKey(),
  });
};

const reject = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/admin/components/OauthApplications/RejectModal/index.vue"),
    props: {
      oauthApplication: props.oauthApplication,
    },
  });
};

const destroyMutation = useDestroyOauthApplication();

const destroy = () => {
  displayConfirm({
    text: t("messages.confirm.oauthApplication.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.oauthApplication.id });
      void queryClient.invalidateQueries({
        queryKey: getOauthApplicationsQueryKey(),
      });
    },
  });
};
</script>

<template>
  <Btn
    v-if="canApprove"
    v-tooltip="!withLabels && t('actions.oauthApplications.approve')"
    :loading="approveMutation.isPending.value"
    @click="approve"
  >
    <i class="fa-duotone fa-circle-check" />
    <span v-if="withLabels">{{ t("actions.oauthApplications.approve") }}</span>
  </Btn>
  <Btn
    v-if="canReject"
    v-tooltip="!withLabels && t('actions.oauthApplications.reject')"
    @click="reject"
  >
    <i class="fa-duotone fa-circle-xmark" />
    <span v-if="withLabels">{{ t("actions.oauthApplications.reject") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :to="
      extend({
        name: 'admin-oauth-application-edit',
        params: { id: props.oauthApplication.id },
      })
    "
  >
    <i class="fa-duotone fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.delete')"
    @click="destroy"
    :tone="BtnTonesEnum.DANGER"
  >
    <i class="fa-duotone fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
