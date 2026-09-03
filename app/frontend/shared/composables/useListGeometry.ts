import { useListGeometryStore } from "@/shared/stores/listGeometry";
import { useMobile } from "@/shared/composables/useMobile";
import type {
  ComponentPublicInstance,
  ComputedRef,
  InjectionKey,
  MaybeRefOrGetter,
  Ref,
} from "vue";

// One list can be drawn more than one way - the ships list is a card grid or a
// table, on the reader's say - and a card is not as tall as a row. Each shape
// remembers its own height.
export type ListGeometryKindType = "row" | "card";

export type ListGeometry = {
  // How many records the answer on its way is expected to hold.
  count: Ref<number> | ComputedRef<number>;
  // What one of them was as tall as the last time this list drew any, which is
  // the only honest source for it: the height comes from the content - a name
  // that wraps, a thumbnail, a cell of buttons - and no rule written ahead of
  // time knows which of those wins in a given list at a given width.
  heightFor: (kind: ListGeometryKindType) => number | undefined;
  report: (kind: ListGeometryKindType, height: number) => void;
  // Whether the frame is showing a spinner of its own already, so a list that
  // has one too can hold it back rather than put up the second.
  spinnerVisible: Ref<boolean> | ComputedRef<boolean>;
};

const listGeometryKey = Symbol("listGeometry") as InjectionKey<ListGeometry>;

// One list can be drawn as a card grid or as a table, and a row that wraps on a
// phone is not the row it is on a desktop: each shape is remembered apart, and
// each viewport class apart again.
const keyFor = (name: string, kind: ListGeometryKindType, mobile: boolean) =>
  `${name}:${kind}:${mobile ? "mobile" : "desktop"}`;

// Offered by whatever frames a list - FilteredList - and picked up by the list
// that renders inside it, so a table or a grid needs to be told neither how
// many placeholders to draw nor how tall.
export const provideListGeometry = (
  name: MaybeRefOrGetter<string>,
  count: Ref<number> | ComputedRef<number>,
  spinnerVisible: Ref<boolean> | ComputedRef<boolean>,
): ListGeometry => {
  const store = useListGeometryStore();
  const mobile = useMobile();

  const ownKeyFor = (kind: ListGeometryKindType) =>
    keyFor(toValue(name), kind, mobile.value);

  const geometry: ListGeometry = {
    count,
    spinnerVisible,
    heightFor: (kind) => store.findByKey(ownKeyFor(kind)),
    report: (kind, measured) => {
      const key = ownKeyFor(kind);

      if (measured > 0 && measured !== store.findByKey(key)) {
        store.setByKey(key, measured);
      }
    },
  };

  provide(listGeometryKey, geometry);

  return geometry;
};

export const useListGeometry = () => inject(listGeometryKey, undefined);

// The reporting half, for whatever actually drew the records: a table, a grid,
// or a page with a list of its own. `pick` names the element to measure, since
// only the caller knows which of its children stands for one record.
//
// `name` is for a page that draws its list inside a frame's slot. The provide
// then happens in a child of that page - FilteredList is rendered by it - and
// inject only ever looks upwards, so such a page has nothing to report to and
// its measurements were going nowhere. Naming the list writes to the same key
// the frame reads back, which is the list's own name.
export const useReportListGeometry = (
  kind: ListGeometryKindType,
  root: Ref<HTMLElement | ComponentPublicInstance | undefined>,
  options: {
    ready: () => boolean;
    pick: (host: HTMLElement) => Element | null | undefined;
    name?: MaybeRefOrGetter<string>;
  },
) => {
  const geometry = useListGeometry();
  const store = useListGeometryStore();
  const mobile = useMobile();

  const record = (measured: number) => {
    if (geometry) {
      geometry.report(kind, measured);

      return;
    }

    const name = toValue(options.name);

    if (!name) {
      return;
    }

    const key = keyFor(name, kind, mobile.value);

    if (measured > 0 && measured !== store.findByKey(key)) {
      store.setByKey(key, measured);
    }
  };

  const report = async () => {
    if ((!geometry && !toValue(options.name)) || !options.ready()) {
      return;
    }

    await nextTick();

    const element = root.value;
    // A ref on a component - a transition group, say - holds the instance, and
    // the element it rendered hangs off it.
    const host = (element && "$el" in element ? element.$el : element) as
      HTMLElement | undefined;

    const measured = host ? options.pick(host) : undefined;

    if (measured) {
      record(Math.round(measured.getBoundingClientRect().height));
    }
  };

  watch(() => options.ready(), report);
  // A row that wraps on a phone is not the row it is on a desktop, and the two
  // are remembered apart - so crossing the breakpoint has to take a new reading.
  watch(mobile, report);

  onMounted(report);

  return { report };
};
