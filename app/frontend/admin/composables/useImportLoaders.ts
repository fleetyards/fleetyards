import { computed, ref, watch } from "vue";
import { useImportsStore } from "@/admin/stores/imports";
import {
  type Import,
  ImportLoaderEnum,
  ImportLoadInputEnvironment,
  ImportTypeEnum,
  useStartImportLoad,
} from "@/services/fyAdminApi";

export type ImportLoaderGroup = "shipMatrix" | "scData";

export type ImportLoaderOption = {
  id: string;
  loader: ImportLoaderEnum;
  group: ImportLoaderGroup;
  environment?: ImportLoadInputEnvironment;
  // The import a run of it writes, which is how the page knows it is running.
  // Loaners and trade routes write none: they show as running only while the
  // request to start them is out.
  types: ImportTypeEnum[];
};

const SC_DATA_ENVIRONMENTS = Object.values(ImportLoadInputEnvironment);

export const IMPORT_LOADERS: ImportLoaderOption[] = [
  {
    id: "ship_matrix",
    loader: ImportLoaderEnum.SHIP_MATRIX,
    group: "shipMatrix",
    types: [ImportTypeEnum.IMPORTS_MODELS_IMPORT],
  },
  {
    id: "modules",
    loader: ImportLoaderEnum.MODULES,
    group: "shipMatrix",
    types: [ImportTypeEnum.IMPORTS_MODULES_IMPORT],
  },
  {
    id: "paints",
    loader: ImportLoaderEnum.PAINTS,
    group: "shipMatrix",
    types: [ImportTypeEnum.IMPORTS_PAINTS_IMPORT],
  },
  {
    id: "loaners",
    loader: ImportLoaderEnum.LOANERS,
    group: "shipMatrix",
    types: [],
  },
  {
    id: "uex_vehicle_prices",
    loader: ImportLoaderEnum.UEX_VEHICLE_PRICES,
    group: "shipMatrix",
    types: [ImportTypeEnum.IMPORTS_UEX_PRICES_IMPORT],
  },
  ...SC_DATA_ENVIRONMENTS.map((environment) => ({
    id: `sc_data_${environment}`,
    loader: ImportLoaderEnum.SC_DATA,
    group: "scData" as const,
    environment,
    types: [ImportTypeEnum.IMPORTS_SC_DATA_ALL_IMPORT],
  })),
  {
    id: "sc_data_models",
    loader: ImportLoaderEnum.SC_DATA_MODELS,
    group: "scData",
    types: [ImportTypeEnum.IMPORTS_SC_DATA_MODELS_IMPORT],
  },
  {
    id: "uex_commodity_prices",
    loader: ImportLoaderEnum.UEX_COMMODITY_PRICES,
    group: "scData",
    types: [ImportTypeEnum.IMPORTS_UEX_COMMODITY_PRICES_IMPORT],
  },
  {
    id: "uex_component_prices",
    loader: ImportLoaderEnum.UEX_COMPONENT_PRICES,
    group: "scData",
    types: [ImportTypeEnum.IMPORTS_UEX_COMPONENT_PRICES_IMPORT],
  },
  {
    id: "uex_equipment_prices",
    loader: ImportLoaderEnum.UEX_EQUIPMENT_PRICES,
    group: "scData",
    types: [ImportTypeEnum.IMPORTS_UEX_EQUIPMENT_PRICES_IMPORT],
  },
  {
    id: "uex_trade_routes",
    loader: ImportLoaderEnum.UEX_TRADE_ROUTES,
    group: "scData",
    types: [],
  },
];

// Every load of a group at once, where the group has one: the whole ship
// matrix after an RSI patch. Game data already loads every catalogue per row.
export const LOAD_ALL: Partial<Record<ImportLoaderGroup, ImportLoaderOption>> =
  {
    shipMatrix: {
      id: "ship_matrix_all",
      loader: ImportLoaderEnum.SHIP_MATRIX_ALL,
      group: "shipMatrix",
      types: IMPORT_LOADERS.filter(
        (option) => option.group === "shipMatrix",
      ).flatMap((option) => option.types),
    },
  };

const ALL_OPTIONS = [
  ...IMPORT_LOADERS,
  ...Object.values(LOAD_ALL).filter(
    (option): option is ImportLoaderOption => !!option,
  ),
];

// How long a started load counts as running before its import shows up: a
// job can wait in the queue, and the button should not look idle meanwhile.
const QUEUED_GRACE_MS = 60_000;

// Shared between the page's buttons and the modals, so both say the same.
// Each request is held under its own token.
const requested = ref<Record<string, number>>({});
let lastToken = 0;

// An sc_data build names its environment: `4.10.1-ptu.12578875`.
const matches = (option: ImportLoaderOption, imp: Import) =>
  option.types.includes(imp.type) &&
  (!option.environment ||
    (imp.version ?? "").includes(`-${option.environment}.`));

export const useImportLoaders = () => {
  const importsStore = useImportsStore();
  const mutation = useStartImportLoad();

  const isRunning = (option: ImportLoaderOption) =>
    option.id in requested.value ||
    importsStore.activeImports.some((imp) => matches(option, imp));

  const isGroupRunning = (group: ImportLoaderGroup) =>
    computed(() =>
      ALL_OPTIONS.filter((option) => option.group === group).some(isRunning),
    );

  // With a token, only that request is settled: a timer left over from an
  // earlier run must not clear a later one still waiting in the queue.
  const settle = (option: ImportLoaderOption, token?: number) => {
    if (token !== undefined && requested.value[option.id] !== token) return;

    const { [option.id]: _settled, ...rest } = requested.value;
    requested.value = rest;
  };

  // A load whose import has arrived is the import's to report from here on.
  watch(
    () => importsStore.activeImports,
    (active) => {
      ALL_OPTIONS.filter((option) => option.id in requested.value).forEach(
        (option) => {
          if (active.some((imp) => matches(option, imp))) settle(option);
        },
      );
    },
  );

  const start = async (option: ImportLoaderOption) => {
    const token = (lastToken += 1);
    requested.value = { ...requested.value, [option.id]: token };

    try {
      await mutation.mutateAsync({
        data: { loader: option.loader, environment: option.environment },
      });
    } catch (error) {
      settle(option, token);
      throw error;
    }

    if (!option.types.length) {
      settle(option, token);
      return;
    }

    window.setTimeout(() => settle(option, token), QUEUED_GRACE_MS);
  };

  return { isRunning, isGroupRunning, start };
};
