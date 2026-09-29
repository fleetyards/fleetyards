import { describe, expect, it } from "vitest";
import { resolveSharedLink } from "./sharedLink";

const hosts = {
  frontendEndpoint: "https://fleetyards.net",
  shortDomain: "fltyrd.net",
};

describe("resolveSharedLink", () => {
  it("opens a shared Fleetyards link in the app", () => {
    expect(
      resolveSharedLink(
        { url: "https://fleetyards.net/ships/carrack/?tab=loadout#top" },
        hosts,
      ),
    ).toEqual({ kind: "route", path: "/ships/carrack/?tab=loadout#top" });
  });

  it("finds the link in the text when the url field is empty", () => {
    expect(
      resolveSharedLink(
        {
          title: "Op Night",
          text: "Join us: https://fleetyards.net/fleets/ember/events/op-night/.",
        },
        hosts,
      ),
    ).toEqual({ kind: "route", path: "/fleets/ember/events/op-night/" });
  });

  it("hands a short link to the server to resolve", () => {
    expect(
      resolveSharedLink(
        { text: "https://fltyrd.net/fe/ember/op-night" },
        hosts,
      ),
    ).toEqual({ kind: "short", href: "https://fltyrd.net/fe/ember/op-night" });
  });

  it("ignores the short domain when none is configured", () => {
    expect(
      resolveSharedLink(
        { text: "https://fltyrd.net/fe/ember/op-night" },
        { frontendEndpoint: hosts.frontendEndpoint },
      ),
    ).toEqual({ kind: "home" });
  });

  it("searches for the words shared with a link to another site", () => {
    expect(
      resolveSharedLink(
        {
          title: "Carrack tour",
          text: "Carrack tour https://youtube.com/watch?v=1",
        },
        hosts,
      ),
    ).toEqual({ kind: "search", query: "Carrack tour" });
  });

  it("searches for plain shared text", () => {
    expect(resolveSharedLink({ text: "Hull C" }, hosts)).toEqual({
      kind: "search",
      query: "Hull C",
    });
  });

  it("does not send a link to the share page back to itself", () => {
    expect(
      resolveSharedLink({ url: "https://fleetyards.net/share/?text=x" }, hosts),
    ).toEqual({ kind: "home" });
  });

  it("does not treat a look-alike host as Fleetyards", () => {
    expect(
      resolveSharedLink(
        { url: "https://fleetyards.net.evil.test/ships/" },
        hosts,
      ),
    ).toEqual({ kind: "home" });
  });

  it("follows a shared http short link over https", () => {
    expect(
      resolveSharedLink({ url: "http://fltyrd.net/fi/abc123" }, hosts),
    ).toEqual({ kind: "short", href: "https://fltyrd.net/fi/abc123" });
  });

  it("does not search for the punctuation left after a foreign link", () => {
    expect(
      resolveSharedLink({ text: "https://example.com/page." }, hosts),
    ).toEqual({ kind: "home" });
  });

  it("opens the home page when nothing usable was shared", () => {
    expect(resolveSharedLink({}, hosts)).toEqual({ kind: "home" });
  });
});
