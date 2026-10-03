<script lang="ts">
export default {
  name: "ImportsLoadModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  IMPORT_LOADERS,
  LOAD_ALL,
  type ImportLoaderGroup,
  type ImportLoaderOption,
  useImportLoaders,
} from "@/admin/composables/useImportLoaders";

type Props = {
  group: ImportLoaderGroup;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const { isRunning, isGroupRunning, start } = useImportLoaders();

const loadAll = computed(() => LOAD_ALL[props.group]);
const groupRunning = isGroupRunning(props.group);

const options = computed(() =>
  IMPORT_LOADERS.filter((option) => option.group === props.group),
);

const title = computed(() =>
  props.group === "shipMatrix"
    ? t("actions.admin.imports.loadShipMatrix")
    : t("actions.admin.imports.loadScData"),
);

const name = (option: ImportLoaderOption) =>
  t(`labels.admin.importLoaders.${option.loader}.name`, {
    environment: option.environment
      ? t(`labels.admin.importLoaders.environments.${option.environment}`)
      : "",
  });

const run = async (option: ImportLoaderOption) => {
  try {
    await start(option);
    displaySuccess({
      text: t("messages.admin.importLoaders.started", { name: name(option) }),
    });
  } catch {
    displayAlert({
      text: t("messages.admin.importLoaders.failed", { name: name(option) }),
    });
  }
};
</script>

<!-- Every load of one kind, each started on its own. A load already running
     shows as loading here and on the button that opened this. -->
<template>
  <Modal :title="title">
    <ul class="import-loaders" :data-test="`import-loaders-${group}`">
      <li
        v-for="option in options"
        :key="option.id"
        class="import-loaders__row"
        :data-test="`import-loader-${option.id}`"
      >
        <div class="import-loaders__text">
          <span class="import-loaders__name">{{ name(option) }}</span>
          <span class="import-loaders__description">
            {{ t(`labels.admin.importLoaders.${option.loader}.description`) }}
          </span>
        </div>
        <Btn
          class="import-loaders__start"
          :size="BtnSizesEnum.SM"
          :loading="isRunning(option)"
          :disabled="isRunning(option)"
          :data-test="`import-loader-start-${option.id}`"
          @click="run(option)"
        >
          {{ t("actions.admin.imports.load") }}
        </Btn>
      </li>
    </ul>

    <template v-if="loadAll" #footer>
      <div class="modal-actions">
        <Btn
          :size="BtnSizesEnum.LG"
          :loading="groupRunning"
          :disabled="groupRunning"
          data-test="import-loader-start-all"
          @click="run(loadAll)"
        >
          {{ t("actions.admin.imports.loadAll") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.import-loaders {
  margin: 0;
  padding: 0;
  list-style: none;

  &__row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    padding: 10px 0;
    border-bottom: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));

    &:last-child {
      border-bottom: 0;
    }
  }

  &__text {
    display: flex;
    flex-direction: column;
    gap: 2px;
    min-width: 0;
  }

  &__name {
    font-weight: 600;
  }

  &__description {
    font-size: 13px;
    color: var(--color-text-dim, #959595);
  }

  // Its own width, whatever the description beside it needs: squeezed, the
  // label was cut to "Loa".
  &__start {
    flex: none;
    white-space: nowrap;
  }
}
</style>
