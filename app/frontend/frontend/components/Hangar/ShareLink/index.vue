<script lang="ts">
export default {
  name: "HangarShareLink",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Loader from "@/shared/components/Loader/index.vue";
import {
  useMyHangarShare,
  useCreateMyHangarShare,
  useRotateMyHangarShare,
  useDestroyMyHangarShare,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { t } = useI18n();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const { data: share, refetch, isPending } = useMyHangarShare();

const createMutation = useCreateMyHangarShare();
const rotateMutation = useRotateMyHangarShare();
const destroyMutation = useDestroyMyHangarShare();

const enabled = computed(() => share.value?.enabled === true);
const shareUrl = computed(() => share.value?.shareUrl ?? "");

const enable = async () => {
  try {
    await createMutation.mutateAsync();
    await refetch();
    displaySuccess({ text: t("messages.hangarShare.enable.success") });
  } catch {
    displayAlert({ text: t("messages.hangarShare.enable.failure") });
  }
};

const rotate = () => {
  displayConfirm({
    text: t("messages.hangarShare.rotate.confirm"),
    confirmText: t("actions.hangarShare.rotate"),
    onConfirm: async () => {
      try {
        await rotateMutation.mutateAsync();
        await refetch();
        displaySuccess({ text: t("messages.hangarShare.rotate.success") });
      } catch {
        displayAlert({ text: t("messages.hangarShare.rotate.failure") });
      }
    },
  });
};

const disable = () => {
  displayConfirm({
    text: t("messages.hangarShare.disable.confirm"),
    confirmText: t("actions.hangarShare.disable"),
    onConfirm: async () => {
      try {
        await destroyMutation.mutateAsync();
        await refetch();
        displaySuccess({ text: t("messages.hangarShare.disable.success") });
      } catch {
        displayAlert({ text: t("messages.hangarShare.disable.failure") });
      }
    },
  });
};

const copyShareUrl = async () => {
  if (!shareUrl.value) return;
  try {
    await navigator.clipboard.writeText(shareUrl.value);
    displaySuccess({ text: t("messages.hangarShare.copy.success") });
  } catch {
    displayAlert({ text: t("messages.hangarShare.copy.failure") });
  }
};
</script>

<template>
  <section class="hangar-share-link" data-test="hangar-share-link">
    <Heading level="h2" size="lg">{{ t("headlines.hangarShare") }}</Heading>

    <Loader :loading="isPending" />

    <p class="text-muted">{{ t("labels.hangarShare.intro") }}</p>

    <Btn
      v-if="!enabled"
      :size="BtnSizesEnum.SM"
      :loading="createMutation.isPending.value"
      data-test="hangar-share-enable"
      @click="enable"
    >
      <i class="fa-light fa-link" />
      <span>{{ t("actions.hangarShare.enable") }}</span>
    </Btn>

    <template v-else>
      <div class="hangar-share-link__url">
        <input
          type="text"
          readonly
          :value="shareUrl"
          class="hangar-share-link__field"
          data-test="hangar-share-url"
          @focus="($event.target as HTMLInputElement).select()"
        />
        <Btn :size="BtnSizesEnum.SM" @click="copyShareUrl">
          <i class="fa-light fa-copy" />
          <span>{{ t("actions.copy") }}</span>
        </Btn>
      </div>

      <p class="text-muted small">{{ t("labels.hangarShare.howTo") }}</p>

      <div class="hangar-share-link__actions">
        <Btn
          :size="BtnSizesEnum.SM"
          :loading="rotateMutation.isPending.value"
          data-test="hangar-share-rotate"
          @click="rotate"
        >
          <i class="fa-light fa-arrows-rotate" />
          <span>{{ t("actions.hangarShare.rotate") }}</span>
        </Btn>
        <Btn
          :size="BtnSizesEnum.SM"
          tone="danger"
          :loading="destroyMutation.isPending.value"
          data-test="hangar-share-disable"
          @click="disable"
        >
          <i class="fa-light fa-link-slash" />
          <span>{{ t("actions.hangarShare.disable") }}</span>
        </Btn>
      </div>
    </template>
  </section>
</template>

<style lang="scss" scoped>
.hangar-share-link__url {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0.5rem 0;
}
.hangar-share-link__field {
  flex: 1;
  min-width: 0;
  padding: 0.4rem 0.6rem;
  font-family: monospace;
  font-size: 0.85rem;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 3px;
  color: inherit;
}
.hangar-share-link__actions {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}
.small {
  font-size: 0.8rem;
}
</style>
