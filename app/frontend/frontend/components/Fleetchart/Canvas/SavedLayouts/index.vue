<script lang="ts">
export default {
  name: "FleetchartCanvasSavedLayouts",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import { shortUrl } from "@/frontend/utils/shortUrl";
import { firstErrorMessageFrom } from "@/shared/utils/ApiErrors";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnConfirm from "@/shared/components/base/BtnConfirm/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormInputGroup from "@/shared/components/base/FormInputGroup/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import {
  getFleetchartLayoutsQueryKey,
  useCreateFleetchartLayout,
  useDestroyFleetchartLayout,
  useFleetchartLayouts,
  useShareFleetchartLayout,
  useUnshareFleetchartLayout,
  useUpdateFleetchartLayout,
  type FleetchartCataloguePlacement,
  type FleetchartLayout,
  type FleetchartPlacement,
} from "@/services/fyApi";

interface Props {
  placements: FleetchartPlacement[];
  cataloguePlacements?: FleetchartCataloguePlacement[];
  colored: boolean;
  // False while the fleet is loading, when there is nothing yet that could be saved
  // and overwriting a layout would empty it.
  ready?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  cataloguePlacements: () => [],
  ready: true,
});

const emit = defineEmits<{ open: [layout: FleetchartLayout] }>();

const { t } = useI18n();

const router = useRouter();

const { displayAlert, displaySuccess } = useAppNotifications();

const queryClient = useQueryClient();

const root = ref<HTMLElement>();

const name = ref("");

const { data: layouts } = useFleetchartLayouts();

const refresh = () =>
  queryClient.invalidateQueries({ queryKey: getFleetchartLayoutsQueryKey() });

const showFailure = (error: unknown) => {
  displayAlert({
    text:
      firstErrorMessageFrom(error) ||
      t("labels.fleetchartApp.savedLayoutFailed"),
  });
};

const mutation = { mutation: { onSuccess: refresh, onError: showFailure } };

const createLayout = useCreateFleetchartLayout(mutation);
const updateLayout = useUpdateFleetchartLayout(mutation);
const destroyLayout = useDestroyFleetchartLayout(mutation);
const shareLayout = useShareFleetchartLayout(mutation);
const unshareLayout = useUnshareFleetchartLayout(mutation);

const save = () => {
  const trimmed = name.value.trim();

  if (!trimmed || !props.ready) {
    return;
  }

  createLayout.mutate(
    {
      data: {
        name: trimmed,
        colored: props.colored,
        placements: props.placements,
        cataloguePlacements: props.cataloguePlacements,
      },
    },
    {
      onSuccess: () => {
        name.value = "";
      },
    },
  );
};

const overwrite = (layout: FleetchartLayout) => {
  updateLayout.mutate(
    {
      id: layout.id,
      data: {
        colored: props.colored,
        placements: props.placements,
        cataloguePlacements: props.cataloguePlacements,
      },
    },
    {
      onSuccess: () => {
        displaySuccess({ text: t("labels.fleetchartApp.savedLayoutUpdated") });
      },
    },
  );
};

const shareUrl = (token: string) => {
  const { href } = router.resolve({
    name: "fleetchart-layout",
    params: { token },
  });

  return shortUrl(`/fc/${token}`) ?? new URL(href, window.location.origin).href;
};
</script>

<template>
  <section
    ref="root"
    class="fleetchart-canvas-saved-layouts"
    :aria-label="t('labels.fleetchartApp.savedLayouts')"
    data-test="fleetchart-saved-layouts-panel"
  >
    <form @submit.prevent="save">
      <FormInputGroup inline>
        <FormInput
          v-model="name"
          name="fleetchart-layout-name"
          :label="t('labels.fleetchartApp.layoutName')"
          no-label
          :placeholder="t('labels.fleetchartApp.layoutName')"
        />
        <Btn
          type="submit"
          :disabled="!name.trim() || !ready"
          :loading="createLayout.isPending.value"
          data-test="fleetchart-save-layout"
        >
          {{ t("labels.fleetchartApp.saveLayout") }}
        </Btn>
      </FormInputGroup>
    </form>

    <ul v-if="layouts?.length" class="fleetchart-canvas-saved-layouts__list">
      <li
        v-for="layout in layouts"
        :key="layout.id"
        class="fleetchart-canvas-saved-layouts__row"
        data-test="fleetchart-saved-layout"
      >
        <span class="fleetchart-canvas-saved-layouts__name">
          {{ layout.name }}
        </span>
        <Btn
          v-tooltip="t('labels.fleetchartApp.openLayout')"
          :aria-label="t('labels.fleetchartApp.openLayout')"
          data-test="fleetchart-open-layout"
          @click="emit('open', layout)"
        >
          <i class="fa-duotone fa-folder-open" />
        </Btn>
        <Btn
          v-tooltip="t('labels.fleetchartApp.updateLayout')"
          :aria-label="t('labels.fleetchartApp.updateLayout')"
          :disabled="!ready"
          data-test="fleetchart-update-layout"
          @click="overwrite(layout)"
        >
          <i class="fa-duotone fa-floppy-disk" />
        </Btn>
        <template v-if="layout.shareToken">
          <ShareBtn
            :url="shareUrl(layout.shareToken)"
            :title="layout.name"
            :container="root"
            no-label
          />
          <Btn
            v-tooltip="t('labels.fleetchartApp.stopSharingLayout')"
            :aria-label="t('labels.fleetchartApp.stopSharingLayout')"
            data-test="fleetchart-unshare-layout"
            @click="unshareLayout.mutate({ id: layout.id })"
          >
            <i class="fa-duotone fa-link-slash" />
          </Btn>
        </template>
        <Btn
          v-else
          v-tooltip="t('labels.fleetchartApp.shareLayout')"
          :aria-label="t('labels.fleetchartApp.shareLayout')"
          data-test="fleetchart-share-layout"
          @click="shareLayout.mutate({ id: layout.id })"
        >
          <i class="fa-duotone fa-link" />
        </Btn>
        <BtnConfirm
          hide-question
          data-test="fleetchart-delete-layout"
          @confirm="destroyLayout.mutate({ id: layout.id })"
        >
          <i class="fa-duotone fa-trash" />
        </BtnConfirm>
      </li>
    </ul>
  </section>
</template>

<style lang="scss" scoped>
@import "index.scss";
</style>
