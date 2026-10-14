import type { ComputedRef, InjectionKey, Ref } from "vue";

export type FormTabRegistration = {
  id: string;
  label: Ref<string>;
  fields: Ref<string[]>;
  disabled: Ref<boolean>;
  hidden: Ref<boolean>;
  icon: Ref<string | undefined>;
  hint: Ref<string | undefined>;
};

export type FormTabsContext = {
  activeId: ComputedRef<string | undefined>;
  registerTab: (tab: FormTabRegistration) => void;
  unregisterTab: (id: string) => void;
  isActive: (id: string) => boolean;
};

export const formTabsContextKey: InjectionKey<FormTabsContext> =
  Symbol("formTabsContext");
