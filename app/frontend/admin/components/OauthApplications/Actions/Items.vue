<script lang="ts">
export default {
  name: "OauthApplicationActionItems",
};
</script>

<script lang="ts" setup>
import {
  type OauthApplication,
  useDestroyOauthApplication,
  getOauthApplicationsQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";

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

const queryClient = useQueryClient();

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
