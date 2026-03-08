import { defineStore } from "pinia";
import {
  type Import,
  type ImportTypeEnum,
  ImportStatusEnum,
} from "@/services/fyAdminApi";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type ImportInput = Record<string, any>;

interface ImportsState {
  imports: Record<string, Import>;
}

export const useImportsStore = defineStore("adminImports", {
  state: (): ImportsState => ({
    imports: {},
  }),
  getters: {
    isImporting:
      (state) =>
      (
        types: ImportTypeEnum | ImportTypeEnum[],
        inputMatch?: ImportInput,
      ): boolean => {
        const typeArray = Array.isArray(types) ? types : [types];
        return Object.values(state.imports).some((imp) => {
          if (!typeArray.includes(imp.type)) return false;
          if (imp.status !== ImportStatusEnum.STARTED) return false;

          if (inputMatch) {
            const impInput = imp.input as unknown as ImportInput | undefined;
            if (!impInput) return false;
            return Object.entries(inputMatch).some(
              ([key, value]) => impInput[key] === value,
            );
          }

          return true;
        });
      },
    activeImports: (state): Import[] =>
      Object.values(state.imports).filter(
        (imp) =>
          imp.status === ImportStatusEnum.CREATED ||
          imp.status === ImportStatusEnum.STARTED,
      ),
  },
  actions: {
    upsertImport(importData: Import) {
      this.imports[importData.id] = importData;

      if (
        importData.status === ImportStatusEnum.FINISHED ||
        importData.status === ImportStatusEnum.FAILED
      ) {
        setTimeout(() => {
          delete this.imports[importData.id];
        }, 30_000);
      }
    },
    seedImports(imports: Import[]) {
      for (const imp of imports) {
        this.imports[imp.id] = imp;
      }
    },
  },
});
