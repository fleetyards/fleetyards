<script lang="ts">
export default {
  name: "HangarShareLink",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import copyText from "@/frontend/utils/CopyText";
import { useMobile } from "@/shared/composables/useMobile";
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

const mobile = useMobile();

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

const copyShareUrl = () => {
  if (!shareUrl.value) return;

  copyText(shareUrl.value).then(
    () => displaySuccess({ text: t("messages.hangarShare.copy.success") }),
    () => displayAlert({ text: t("messages.hangarShare.copy.failure") }),
  );
};
</script>

<template>
  <section class="hangar-share-link" data-test="hangar-share-link">
    <Heading level="h2" size="lg">{{ t("headlines.hangarShare") }}</Heading>

    <p class="hangar-share-link__intro">{{ t("labels.hangarShare.intro") }}</p>

    <Loader v-if="isPending" :loading="isPending" />

    <Btn
      v-else-if="!enabled"
      :size="BtnSizesEnum.SM"
      :loading="createMutation.isPending.value"
      data-test="hangar-share-enable"
      @click="enable"
    >
      <i class="fa-light fa-link" />
      <span>{{ t("actions.hangarShare.enable") }}</span>
    </Btn>

    <template v-else>
      <div class="hangar-share-link__url" data-test="hangar-share-url">
        <FormInput
          id="hangar-share-url"
          :model-value="shareUrl"
          name="hangarShareUrl"
          readonly
          no-label
          inline
          standalone
          class="hangar-share-link__field"
          @click="copyShareUrl"
        />
        <ShareBtn
          v-if="mobile"
          :url="shareUrl"
          :title="t('headlines.hangarShare')"
          no-label
        />
        <Btn v-else :size="BtnSizesEnum.SM" @click="copyShareUrl">
          <i class="fa-light fa-copy" />
          <span>{{ t("actions.copy") }}</span>
        </Btn>
      </div>

      <p class="hangar-share-link__hint">{{ t("labels.hangarShare.howTo") }}</p>

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
.hangar-share-link__intro,
.hangar-share-link__hint {
  color: var(--color-text-dim);
}

.hangar-share-link__hint {
  font-size: 0.85em;
}

.hangar-share-link__url {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0.5rem 0;
}

.hangar-share-link__field {
  flex: 1;
  min-width: 0;
}

.hangar-share-link__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}
</style>
