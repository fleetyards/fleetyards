import { computed, ref, watch } from "vue";
import { useImportsStore } from "@/admin/stores/imports";
import {
  type Import,
  ImportLoaderEnum,
  ImportLoadInputEnvironment,
  ImportStatusEnum,
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
  // Trade routes write none: they show as running only while the request to
  // start them is out.
  types: ImportTypeEnum[];
  // Loads the backend starts by itself once this one's run is in. They count
  // as running from the start: started by hand meanwhile, they would run twice.
  followUps?: string[];
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
    types: [ImportTypeEnum.IMPORTS_LOANERS_IMPORT],
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
      types: [ImportTypeEnum.IMPORTS_MODELS_IMPORT],
      followUps: IMPORT_LOADERS.filter(
        (option) =>
          option.group === "shipMatrix" && option.id !== "ship_matrix",
      ).map((option) => option.id),
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

// A load with follow-ups, from its request until its own run has finished.
// Its run is the first matching import that was not already active at the
// request (`skip`): another run of the same type finishing must not release
// the rows while this one still waits in the queue. Held under the request's
// token, like `requested`.
const chains = ref<
  Record<string, { token: number; skip: string[]; importId?: string }>
>({});

// How long a chain waits for its import to show up at all. Once it has, the
// chain lasts as long as the import does, however long the run takes.
const CHAIN_LIMIT_MS = 30 * 60_000;

// An sc_data build names its environment: `4.10.1-ptu.12578875`.
const matches = (option: ImportLoaderOption, imp: Import) =>
  option.types.includes(imp.type) &&
  (!option.environment ||
    (imp.version ?? "").includes(`-${option.environment}.`));

export const useImportLoaders = () => {
  const importsStore = useImportsStore();
  const mutation = useStartImportLoad();

  const inChain = (option: ImportLoaderOption) =>
    ALL_OPTIONS.some(
      (chain) =>
        chain.id in chains.value &&
        (chain.id === option.id || !!chain.followUps?.includes(option.id)),
    );

  const isRunning = (option: ImportLoaderOption) =>
    option.id in requested.value ||
    inChain(option) ||
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

  const endChain = (option: ImportLoaderOption, token?: number) => {
    if (token !== undefined && chains.value[option.id]?.token !== token) return;

    const { [option.id]: _ended, ...rest } = chains.value;
    chains.value = rest;
  };

  // A finished run has just queued its follow-ups, whose imports show up only
  // once their jobs start: each is held like a request of its own meanwhile.
  // A failed run queues none.
  const handOff = (option: ImportLoaderOption, active: Import[]) => {
    option.followUps?.forEach((id) => {
      const followUp = ALL_OPTIONS.find((candidate) => candidate.id === id);
      if (
        !followUp?.types.length ||
        active.some((imp) => matches(followUp, imp))
      ) {
        return;
      }

      const token = (lastToken += 1);
      requested.value = { ...requested.value, [id]: token };
      window.setTimeout(() => settle(followUp, token), QUEUED_GRACE_MS);
    });
  };

  // A load whose import has arrived is the import's to report from here on.
  // A chain ends when its own run's import is gone again.
  watch(
    () => importsStore.activeImports,
    (active) => {
      ALL_OPTIONS.forEach((option) => {
        const running = active.some((imp) => matches(option, imp));

        if (option.id in requested.value && running) settle(option);

        const chain = chains.value[option.id];
        if (!chain) return;

        if (chain.importId) {
          if (!active.some((imp) => imp.id === chain.importId)) {
            endChain(option);

            if (
              importsStore.imports[chain.importId]?.status ===
              ImportStatusEnum.FINISHED
            ) {
              handOff(option, active);
            }
          }
          return;
        }

        const own = active.find(
          (imp) => matches(option, imp) && !chain.skip.includes(imp.id),
        );
        if (own) {
          chains.value = {
            ...chains.value,
            [option.id]: { ...chain, importId: own.id },
          };
        }
      });
    },
  );

  const start = async (option: ImportLoaderOption) => {
    const token = (lastToken += 1);
    requested.value = { ...requested.value, [option.id]: token };

    if (option.followUps?.length) {
      chains.value = {
        ...chains.value,
        [option.id]: {
          token,
          skip: importsStore.activeImports
            .filter((imp) => matches(option, imp))
            .map((imp) => imp.id),
        },
      };
      window.setTimeout(() => {
        if (!chains.value[option.id]?.importId) endChain(option, token);
      }, CHAIN_LIMIT_MS);
    }

    try {
      await mutation.mutateAsync({
        data: { loader: option.loader, environment: option.environment },
      });
    } catch (error) {
      settle(option, token);
      endChain(option, token);
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
