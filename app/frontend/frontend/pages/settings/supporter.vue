<script lang="ts">
export default {
  name: "SettingsSupporterPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Loader from "@/shared/components/Loader/index.vue";
import {
  useMySupporterClaimKey,
  useCreateMySupporterClaimKey,
  useRotateMySupporterClaimKey,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const { data: claimKey, refetch, isPending } = useMySupporterClaimKey();

const createMutation = useCreateMySupporterClaimKey();
const rotateMutation = useRotateMySupporterClaimKey();

const key = computed(() => claimKey.value?.key ?? "");
const hasKey = computed(() => key.value.length > 0);

const create = async () => {
  try {
    await createMutation.mutateAsync();
    await refetch();
    displaySuccess({
      text: t("messages.account.supporterClaimKey.create.success"),
    });
  } catch {
    displayAlert({
      text: t("messages.account.supporterClaimKey.create.failure"),
    });
  }
};

const rotate = () => {
  displayConfirm({
    text: t("messages.account.supporterClaimKey.rotate.confirm"),
    confirmText: t("actions.account.supporterClaimKey.rotate"),
    onConfirm: async () => {
      try {
        await rotateMutation.mutateAsync();
        await refetch();
        displaySuccess({
          text: t("messages.account.supporterClaimKey.rotate.success"),
        });
      } catch {
        displayAlert({
          text: t("messages.account.supporterClaimKey.rotate.failure"),
        });
      }
    },
  });
};

const copyKey = async () => {
  if (!hasKey.value) return;
  try {
    await navigator.clipboard.writeText(key.value);
    displaySuccess({
      text: t("messages.account.supporterClaimKey.copy.success"),
    });
  } catch {
    displayAlert({
      text: t("messages.account.supporterClaimKey.copy.failure"),
    });
  }
};

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "settings-profile" },
    label: t("nav.settings.index"),
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading hero>{{ t("headlines.settings.supporter") }}</Heading>

  <Loader :loading="isPending" />

  <p class="text-muted">
    {{ t("labels.account.supporterClaimKey.intro") }}
  </p>

  <template v-if="!hasKey">
    <p class="text-muted small">
      {{ t("labels.account.supporterClaimKey.notCreated") }}
    </p>
    <Btn
      :size="BtnSizesEnum.SM"
      :loading="createMutation.isPending.value"
      data-test="create-claim-key"
      @click="create"
    >
      <i class="fa-light fa-key" />
      <span>{{ t("actions.account.supporterClaimKey.create") }}</span>
    </Btn>
  </template>

  <template v-else>
    <div class="supporter-settings__key">
      <input
        type="text"
        readonly
        :value="key"
        class="supporter-settings__field"
        data-test="claim-key"
        @focus="($event.target as HTMLInputElement).select()"
      />
      <Btn :size="BtnSizesEnum.SM" data-test="copy-claim-key" @click="copyKey">
        <i class="fa-light fa-copy" />
        <span>{{ t("actions.copy") }}</span>
      </Btn>
    </div>

    <p class="text-muted small">
      {{ t("labels.account.supporterClaimKey.howTo") }}
    </p>

    <hr />

    <Btn
      :size="BtnSizesEnum.SM"
      :loading="rotateMutation.isPending.value"
      data-test="rotate-claim-key"
      @click="rotate"
    >
      <i class="fa-light fa-arrows-rotate" />
      <span>{{ t("actions.account.supporterClaimKey.rotate") }}</span>
    </Btn>
  </template>
</template>

<style lang="scss" scoped>
.supporter-settings__key {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0.5rem 0;
}

.supporter-settings__field {
  flex: 1;
  padding: 0.4rem 0.6rem;
  font-family: monospace;
  font-size: 0.85rem;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 3px;
  color: inherit;
}

.small {
  font-size: 0.8rem;
}
</style>
