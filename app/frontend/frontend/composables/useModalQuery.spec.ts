import { afterEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import { useComlink } from "@/shared/composables/useComlink";

const route = ref<{
  path: string;
  query: Record<string, unknown>;
  hash: string;
}>({ path: "/hangar/", query: {}, hash: "" });

const replace = vi.fn(() => Promise.resolve());

vi.mock("vue-router", () => ({
  useRoute: () => route.value,
  useRouter: () => ({ replace }),
}));

const { useModalQuery, MODAL_QUERY_PARAM, QUERY_MODALS } =
  await import("./useModalQuery");

const comlink = useComlink();

describe("useModalQuery", () => {
  const unsubscribes: (() => void)[] = [];

  const onModalOpen = () => {
    const spy = vi.fn();
    unsubscribes.push(comlink.on("open-modal", spy));
    return spy;
  };

  afterEach(() => {
    unsubscribes.splice(0).forEach((unsubscribe) => unsubscribe());
    replace.mockClear();
    route.value = { path: "/hangar/", query: {}, hash: "" };
  });

  it("opens the modal the address names", () => {
    route.value.query = { [MODAL_QUERY_PARAM]: "support" };
    const opened = onModalOpen();

    useModalQuery().openFromQuery();

    expect(opened).toHaveBeenCalledWith(QUERY_MODALS.support);
  });

  // A name in an address is typed by hand as often as it is clicked, and one
  // the app does not know is a typo rather than an instruction.
  it("ignores a name it does not know", () => {
    route.value.query = { [MODAL_QUERY_PARAM]: "nope" };
    const opened = onModalOpen();

    useModalQuery().openFromQuery();

    expect(opened).not.toHaveBeenCalled();
  });

  it("takes the first of a repeated parameter", () => {
    route.value.query = { [MODAL_QUERY_PARAM]: ["support", "nope"] };
    const opened = onModalOpen();

    useModalQuery().openFromQuery();

    expect(opened).toHaveBeenCalled();
  });

  it("does nothing for an address that names none", () => {
    const opened = onModalOpen();

    useModalQuery().openFromQuery();

    expect(opened).not.toHaveBeenCalled();
  });

  // Opening writes the name and stops there: the app opens what the address
  // names, so a button and a link are the same path.
  it("opens by writing the name into the address", async () => {
    route.value.query = { tab: "ships" };
    const opened = onModalOpen();

    await useModalQuery().openModal("support");

    expect(replace).toHaveBeenCalledWith({
      path: "/hangar/",
      query: { tab: "ships", [MODAL_QUERY_PARAM]: "support" },
      hash: "",
    });
    expect(opened).not.toHaveBeenCalled();
  });

  it("writes nothing when the address already names it", async () => {
    route.value.query = { [MODAL_QUERY_PARAM]: "support" };

    await useModalQuery().openModal("support");

    expect(replace).not.toHaveBeenCalled();
  });

  it("takes the name back out when the modal closes", async () => {
    route.value.query = { [MODAL_QUERY_PARAM]: "support", tab: "ships" };

    await useModalQuery().clearModalQuery();

    expect(replace).toHaveBeenCalledWith({
      path: "/hangar/",
      query: { tab: "ships" },
      hash: "",
    });
  });

  // Every modal reports its closing, not only the ones that can be named.
  it("leaves an address that names none alone on close", async () => {
    route.value.query = { tab: "ships" };

    await useModalQuery().clearModalQuery();

    expect(replace).not.toHaveBeenCalled();
  });

  it("names the modal in the route a login comes back to", () => {
    route.value.query = { tab: "ships" };

    expect(useModalQuery().modalRoute("support")).toEqual({
      path: "/hangar/",
      query: { tab: "ships", [MODAL_QUERY_PARAM]: "support" },
      hash: "",
    });
  });
});
