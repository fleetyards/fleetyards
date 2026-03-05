<script lang="ts">
export default {
  name: "AdminLinkUpgradeModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelImage from "@/shared/components/base/Panel/Image/index.vue";
import { PanelAlignmentsEnum } from "@/shared/components/base/Panel/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type ModelUpgrade,
  listModelUpgrades,
  useLinkModelUpgrade as useLinkModelUpgradeMutation,
  getListModelUpgradesQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  modelId: string;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const queryClient = useQueryClient();

const PER_PAGE = 8;

const searchQuery = ref("");
const currentPage = ref(1);
const totalPages = ref(1);
const allItems = ref<ModelUpgrade[]>([]);
const loading = ref(false);
const selectedIds = ref<Set<string>>(new Set());
const linking = ref(false);

const hasMore = computed(() => currentPage.value < totalPages.value);

const fetchPage = async (page: number, reset = false) => {
  loading.value = true;

  try {
    const q: Record<string, string> = {};

    if (searchQuery.value.length >= 2) {
      q.nameCont = searchQuery.value;
    }

    const params: Record<string, unknown> = {
      perPage: String(PER_PAGE),
      page: String(page),
      q,
    };

    const result = await listModelUpgrades(params);

    if (reset) {
      allItems.value = result.items || [];
    } else {
      allItems.value = [...allItems.value, ...(result.items || [])];
    }

    totalPages.value = result.meta?.pagination?.totalPages ?? 1;
    currentPage.value = page;
  } finally {
    loading.value = false;
  }
};

const loadMore = () => {
  if (hasMore.value && !loading.value) {
    void fetchPage(currentPage.value + 1);
  }
};

let searchTimeout: ReturnType<typeof setTimeout> | null = null;

watch(searchQuery, () => {
  if (searchTimeout) clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    currentPage.value = 1;
    selectedIds.value = new Set();
    void fetchPage(1, true);
  }, 300);
});

onMounted(() => {
  void fetchPage(1, true);
});

const storeImage = (upgrade: ModelUpgrade) => {
  return upgrade.media?.storeImage?.smallUrl;
};

const isSelected = (id: string) => selectedIds.value.has(id);

const toggleSelect = (id: string) => {
  const next = new Set(selectedIds.value);
  if (next.has(id)) {
    next.delete(id);
  } else {
    next.add(id);
  }
  selectedIds.value = next;
};

const linkMutation = useLinkModelUpgradeMutation({
  mutation: {
    onSettled: async () => {
      await queryClient.invalidateQueries({
        queryKey: getListModelUpgradesQueryKey(),
      });
    },
  },
});

const onConfirm = async () => {
  if (!selectedIds.value.size) return;

  linking.value = true;

  try {
    for (const upgradeId of selectedIds.value) {
      await linkMutation.mutateAsync({
        id: upgradeId,
        data: { modelId: props.modelId },
      });
    }

    comlink.emit("close-modal");
  } finally {
    linking.value = false;
  }
};
</script>

<template>
  <Modal :title="t('headlines.admin.models.edit.linkUpgrade')">
    <div class="row">
      <div class="col-12">
        <FormInput
          v-model="searchQuery"
          name="link-upgrade-search"
          :placeholder="t('placeholders.search')"
          no-label
          clearable
        />
      </div>
    </div>
    <div class="row mt-2">
      <div class="col-12">
        <div class="row">
          <div
            v-for="upgrade in allItems"
            :key="upgrade.id"
            class="col-12 col-md-6 link-upgrade-item"
          >
            <Panel
              :alignment="PanelAlignmentsEnum.LEFT"
              slim
              class="link-upgrade-panel"
              @click.capture="toggleSelect(upgrade.id)"
            >
              <PanelImage
                v-if="storeImage(upgrade)"
                :image="storeImage(upgrade)"
                image-size="auto"
                rounded="left"
                class="link-upgrade-image"
                :alt="upgrade.name"
              />
              <div>
                <PanelHeading
                  :level="HeadingLevelEnum.H3"
                  title-align="right"
                  multiline
                >
                  {{ upgrade.name }}
                </PanelHeading>
                <div
                  v-if="isSelected(upgrade.id)"
                  v-tooltip="t('labels.selected')"
                  class="link-upgrade-selected"
                >
                  <i class="fa fa-check" />
                </div>
              </div>
            </Panel>
          </div>
        </div>

        <p v-if="!loading && !allItems.length" class="text-muted">
          {{ t("empty.headlines.forName", { name: "Upgrades" }) }}
        </p>

        <div v-if="hasMore" class="text-center mt-2">
          <Btn
            :size="BtnSizesEnum.SMALL"
            :variant="BtnVariantsEnum.TRANSPARENT"
            :loading="loading"
            @click="loadMore"
          >
            {{ t("actions.loadMore") }}
          </Btn>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :size="BtnSizesEnum.SMALL"
          :inline="true"
          :loading="linking"
          :disabled="!selectedIds.size"
          @click="onConfirm"
        >
          {{ t("actions.add") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.link-upgrade-item {
  .link-upgrade-panel {
    cursor: pointer;
    margin-bottom: 4px;

    .link-upgrade-selected {
      position: absolute;
      bottom: 0;
      left: 0;
      width: 40px;
      height: 40px;
      display: flex;
      justify-content: center;
      align-items: center;
      background-color: $success;
      border-radius: 0 10px 0 $panelContentBorderRadius;

      i,
      svg {
        color: #fff;
      }
    }
  }
}

.link-upgrade-image {
  width: 80px;
  flex-shrink: 0;
}
</style>
