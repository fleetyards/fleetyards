import { computed, type ComputedRef, type MaybeRef, unref } from "vue";
import { useImportsStore, type ImportInput } from "@/admin/stores/imports";
import { type ImportTypeEnum } from "@/services/fyAdminApi";

export const useImportLoading = (
  types: ImportTypeEnum | ImportTypeEnum[],
  inputMatch?: MaybeRef<ImportInput | undefined>,
): { isImporting: ComputedRef<boolean> } => {
  const importsStore = useImportsStore();

  const isImporting = computed(() =>
    importsStore.isImporting(types, unref(inputMatch)),
  );

  return { isImporting };
};
