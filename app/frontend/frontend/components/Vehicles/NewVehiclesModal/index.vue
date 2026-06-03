<script lang="ts">
export default {
  name: "NewVehiclesModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import ListGroup from "@/shared/components/ListGroup/index.vue";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import {
  type ModelOption,
  type ModelQuery,
  useModelOptions,
} from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import debounce from "lodash.debounce";

type Props = {
  wanted?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  wanted: false,
});

const { t } = useI18n();

const submitting = ref(false);

const comlink = useComlink();

const { useCreateBulkMutation } = useVehicleMutations();

const mutation = useCreateBulkMutation();

const search = ref<string>("");
const debouncedSearch = ref<string>("");
const page = ref(1);
const records = ref<ModelOption[]>([]);
const selectedIds = ref<string[]>([]);

const PER_PAGE = "15";

const queryParams = computed(() => {
  const q: ModelQuery = {};
  if (debouncedSearch.value) {
    q.nameCont = debouncedSearch.value;
  }

  return {
    page: String(page.value),
    perPage: PER_PAGE,
    q,
  };
});

const { data, isFetching, isLoading } = useModelOptions(queryParams, {
  query: {
    refetchOnWindowFocus: false,
  },
});

watch(
  data,
  (response) => {
    if (!response) return;

    if (page.value === 1) {
      records.value = response.items;
    } else {
      const existing = new Set(records.value.map((item) => item.id));
      records.value = [
        ...records.value,
        ...response.items.filter((item) => !existing.has(item.id)),
      ];
    }
  },
  { immediate: true },
);

const totalPages = computed(() => {
  return data.value?.meta.pagination?.totalPages ?? 1;
});

const hasMore = computed(() => {
  return page.value < totalPages.value;
});

const loading = computed(() => {
  return isLoading.value || isFetching.value;
});

const applySearch = debounce((value: string) => {
  debouncedSearch.value = value;
  page.value = 1;
}, 300);

watch(search, (value) => {
  applySearch(value);
});

const loadMore = () => {
  if (!hasMore.value || loading.value) return;
  page.value += 1;
};

const toggle = (id: string) => {
  if (selectedIds.value.includes(id)) {
    selectedIds.value = selectedIds.value.filter((item) => item !== id);
  } else {
    selectedIds.value = [...selectedIds.value, id];
  }
};

const save = async () => {
  if (!selectedIds.value.length) return;

  submitting.value = true;

  await mutation
    .mutateAsync({
      data: {
        vehicles: selectedIds.value.map((id) => ({
          wanted: props.wanted,
          modelId: id,
        })),
      },
    })
    .then(() => {
      comlink.emit("hangar-change");
    })
    .finally(() => {
      submitting.value = false;
      comlink.emit("close-modal");
    });
};
</script>

<template>
  <Modal :title="t('headlines.newVehicles')">
    <form id="new-vehicles" class="new-vehicles" @submit.prevent="save">
      <div class="new-vehicles__search">
        <FormInput
          v-model="search"
          name="new-vehicles-search"
          :label="t('labels.findModel')"
          :placeholder="t('labels.findModel')"
          no-label
          clearable
        />
      </div>

      <ListGroup
        :items="records"
        :loading="loading"
        :empty-name="t('models.name')"
        hide-empty
      >
        <template #display="{ item }">
          <FormCheckbox
            v-model="selectedIds"
            name="new-vehicles-item"
            no-label
            inline
            :checkbox-value="item.id"
            @click.stop
          />
          <button
            type="button"
            class="new-vehicles__row"
            @click="toggle(item.id)"
          >
            <ViewImage
              :image="item.media.storeImage"
              size="small"
              alt="image"
              :variant="LazyImageVariantsEnum.EXTRA_SMALL"
              shadow
            />
            <span class="new-vehicles__name">{{ item.name }}</span>
          </button>
        </template>
      </ListGroup>

      <Empty
        v-if="!loading && !records.length"
        :variant="EmptyVariantsEnum.DEFAULT"
        :name="t('models.name')"
        inline
        hide-actions
      />

      <Btn
        v-if="hasMore"
        :variant="BtnVariantsEnum.LINK"
        :disabled="loading"
        inline
        class="new-vehicles__load-more"
        @click="loadMore"
      >
        {{ t("filterGroup.actions.fetchMore") }}
      </Btn>
    </form>
    <template #footer>
      <div class="new-vehicles__footer">
        <span class="new-vehicles__count">
          {{
            t("filteredTable.labels.selected", { count: selectedIds.length })
          }}
        </span>
        <Btn
          :loading="submitting"
          :disabled="!selectedIds.length"
          :size="BtnSizesEnum.LARGE"
          :inline="true"
          @click="save"
        >
          {{ t("actions.add") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.new-vehicles {
  &__search {
    position: sticky;
    top: 0;
    z-index: 2;
    background: $panel-bg;
    padding-bottom: 0.5rem;
  }

  &__row {
    display: flex;
    align-items: center;
    gap: 12px;
    flex: 1;
    min-width: 0;
    padding: 0;
    background: none;
    border: none;
    color: inherit;
    text-align: left;
    cursor: pointer;
  }

  &__name {
    flex: 1;
    min-width: 0;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
  }

  &__load-more {
    width: 100%;
    margin-top: 0.5rem;
  }

  &__footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    gap: 0.75rem;
  }

  &__count {
    padding-left: 0.5rem;
    color: $text-color;
    font-weight: 600;
  }
}
</style>
