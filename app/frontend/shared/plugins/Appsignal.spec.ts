import type Appsignal from "@appsignal/javascript";
import { reportError, setupAppsignal } from "./Appsignal";

const client = vi.hoisted(() => ({ current: undefined as unknown }));

vi.mock("@appsignal/vue", () => ({
  errorHandler: (appsignal: Appsignal) => {
    client.current = appsignal;

    return (error: Error) => appsignal.sendError(error);
  },
}));

const WEBGL_MESSAGES = [
  "THREE.WebGLRenderer: Error creating WebGL context.",
  "THREE.WebGLRenderer: Error creating WebGL context with your selected attributes.",
];

const setup = () => {
  const app = createApp({});

  window.APPSIGNAL_KEY = "key";
  setupAppsignal(app);

  const { _api: transport } = client.current as unknown as {
    _api: { push: (span: unknown) => Promise<unknown> };
  };
  const push = vi.spyOn(transport, "push").mockResolvedValue(undefined);

  return { app, push };
};

describe("setupAppsignal", () => {
  beforeEach(() => {
    vi.spyOn(console, "warn").mockImplementation(() => undefined);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it.each(WEBGL_MESSAGES)("does not send %s", async (message) => {
    const { app, push } = setup();

    app.config.errorHandler?.(new Error(message), null, "setup function");
    await flushPromises();

    expect(push).not.toHaveBeenCalled();
  });

  it.each(WEBGL_MESSAGES)(
    "does not send %s from a handled error",
    async (message) => {
      const { push } = setup();

      reportError(new Error(message), "SomeComponent");
      await flushPromises();

      expect(push).not.toHaveBeenCalled();
    },
  );

  it("sends any other error", async () => {
    const { app, push } = setup();

    app.config.errorHandler?.(
      new Error("Cannot read properties of null"),
      null,
      "setup function",
    );
    await flushPromises();

    expect(push).toHaveBeenCalledOnce();
  });

  it("tags the route and whether the page was translated", async () => {
    const { app, push } = setup();
    app.config.globalProperties.$router = {
      currentRoute: { value: { name: "hangar" } },
    } as never;
    document.documentElement.className = "translated-ltr";

    app.config.errorHandler?.(new Error("boom"), null, "render function");
    await flushPromises();

    document.documentElement.className = "";

    const span = push.mock.calls[0][0] as {
      serialize: () => { tags: Record<string, string> };
    };
    expect(span.serialize().tags).toMatchObject({
      route: "hangar",
      page_translated: "true",
    });
  });

  it("tags an untranslated page as such", async () => {
    const { app, push } = setup();

    app.config.errorHandler?.(new Error("boom"), null, "render function");
    await flushPromises();

    const span = push.mock.calls[0][0] as {
      serialize: () => { tags: Record<string, string> };
    };
    expect(span.serialize().tags).toMatchObject({
      route: "",
      page_translated: "false",
    });
  });
});

const flushPromises = () => new Promise((resolve) => setTimeout(resolve));
