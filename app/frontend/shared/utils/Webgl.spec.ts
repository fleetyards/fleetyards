import { afterEach, describe, expect, it, vi } from "vitest";
import { webglAvailable } from "./Webgl";

const stubContext = (
  context: unknown,
  { throws = false }: { throws?: boolean } = {},
) =>
  vi.spyOn(HTMLCanvasElement.prototype, "getContext").mockImplementation(() => {
    if (throws) {
      throw new Error("nope");
    }

    return context as ReturnType<HTMLCanvasElement["getContext"]>;
  });

const loseContext = () => {
  const lose = vi.fn();

  return {
    lose,
    context: { getExtension: vi.fn(() => ({ loseContext: lose })) },
  };
};

afterEach(() => {
  vi.restoreAllMocks();
});

describe("webglAvailable", () => {
  it("reports a context it could get", () => {
    stubContext(loseContext().context);

    expect(webglAvailable()).toBe(true);
  });

  it("reports no context when the canvas gives none", () => {
    stubContext(null);

    expect(webglAvailable()).toBe(false);
  });

  it("reports no context when asking for one throws", () => {
    stubContext(null, { throws: true });

    expect(webglAvailable()).toBe(false);
  });

  /*
   * The point of the whole function: a probe that keeps its context spends one
   * of the few the browser allows, so the renderer built next is the one that
   * fails.
   */
  it("hands the probe context back", () => {
    const { lose, context } = loseContext();
    stubContext(context);

    webglAvailable();

    expect(context.getExtension).toHaveBeenCalledWith("WEBGL_lose_context");
    expect(lose).toHaveBeenCalledOnce();
  });

  it("survives a context that cannot be released", () => {
    stubContext({ getExtension: vi.fn(() => null) });

    expect(webglAvailable()).toBe(true);
  });
});
