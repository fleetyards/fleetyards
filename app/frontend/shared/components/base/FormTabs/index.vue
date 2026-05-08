<script lang="ts">
export default {
  name: "FormTabs",
};
</script>

<script lang="ts" setup>
import { shallowRef } from "vue";
import { useFormErrors } from "vee-validate";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewAnchorItems from "@/shared/components/TabNavView/AnchorItems/index.vue";
import {
  formTabsContextKey,
  type FormTabRegistration,
} from "@/shared/components/base/FormTabs/types";

type Props = {
  activeTab?: string;
  defaultTab?: string;
  queryKey?: string;
  syncUrl?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  activeTab: undefined,
  defaultTab: undefined,
  queryKey: "tab",
  syncUrl: true,
});

const emit = defineEmits<{
  "update:activeTab": [value: string];
}>();

const route = useRoute();
const router = useRouter();

const tabs = shallowRef<FormTabRegistration[]>([]);

const visibleTabs = computed(() =>
  tabs.value.filter((tab) => !tab.hidden.value),
);

const internalActive = ref<string | undefined>(undefined);

const initialFromUrl = (): string | undefined => {
  if (!props.syncUrl) return undefined;
  const fromQuery = route.query[props.queryKey];
  return typeof fromQuery === "string" ? fromQuery : undefined;
};

const activeId = computed<string | undefined>(() => {
  const candidate =
    props.activeTab ??
    internalActive.value ??
    initialFromUrl() ??
    props.defaultTab;
  if (
    candidate &&
    visibleTabs.value.some((tab) => tab.id === candidate && !tab.disabled.value)
  ) {
    return candidate;
  }
  return visibleTabs.value.find((tab) => !tab.disabled.value)?.id;
});

const setActive = (id: string) => {
  const tab = visibleTabs.value.find((t) => t.id === id);
  if (!tab || tab.disabled.value) return;

  internalActive.value = id;
  emit("update:activeTab", id);

  if (props.syncUrl) {
    void router.replace({
      query: { ...route.query, [props.queryKey]: id },
    });
  }
};

const isActive = (id: string) => activeId.value === id;

const registerTab = (tab: FormTabRegistration) => {
  if (tabs.value.some((t) => t.id === tab.id)) return;
  tabs.value = [...tabs.value, tab];
};

const unregisterTab = (id: string) => {
  tabs.value = tabs.value.filter((t) => t.id !== id);
};

provide(formTabsContextKey, {
  activeId,
  registerTab,
  unregisterTab,
  isActive,
});

const formErrors = useFormErrors();

const tabHasErrors = (tab: FormTabRegistration) => {
  if (!tab.fields.value.length) return false;
  const errs = formErrors.value;
  return tab.fields.value.some((name) => !!errs[name]);
};

const items = computed(() =>
  visibleTabs.value.map((tab) => ({
    id: tab.id,
    label: tab.label.value,
    disabled: tab.disabled.value,
    invalid: tabHasErrors(tab),
  })),
);

watch(
  () => route.query[props.queryKey],
  (next) => {
    if (!props.syncUrl) return;
    if (typeof next === "string" && next !== internalActive.value) {
      internalActive.value = next;
    }
  },
);

watch(
  () => props.activeTab,
  (next) => {
    if (next !== undefined) {
      internalActive.value = next;
    }
  },
);
</script>

<template>
  <TabNavView :active-key="activeId">
    <template #nav>
      <TabNavViewAnchorItems
        :items="items"
        :active-id="activeId"
        @update:active-id="setActive"
      />
    </template>
    <template #content>
      <slot />
    </template>
  </TabNavView>
</template>
