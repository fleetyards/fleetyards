import {
  FALLBACK_TITLE,
  notificationOptions,
  parsePushPayload,
  pickClient,
  safeUrl,
} from "./push";

const ORIGIN = "https://fleetyards.net";

describe("parsePushPayload", () => {
  it("reads the payload the server sends", () => {
    const payload = parsePushPayload(
      JSON.stringify({
        title: "Invited",
        body: "Join us",
        url: `${ORIGIN}/fleets/invites`,
        tag: "fleet_invite:1",
        notificationId: "abc",
      }),
    );

    expect(payload).toEqual({
      title: "Invited",
      body: "Join us",
      url: `${ORIGIN}/fleets/invites`,
      tag: "fleet_invite:1",
      notificationId: "abc",
    });
  });

  it.each([null, undefined, "", "not json", "{}", '{"title":""}', "[]"])(
    "still has a title for %j",
    (text) => {
      expect(parsePushPayload(text).title).toBe(FALLBACK_TITLE);
    },
  );
});

describe("safeUrl", () => {
  it("keeps a link on this origin", () => {
    expect(safeUrl(`${ORIGIN}/hangar`, ORIGIN)).toBe(`${ORIGIN}/hangar`);
  });

  it("resolves a path against this origin", () => {
    expect(safeUrl("/hangar", ORIGIN)).toBe(`${ORIGIN}/hangar`);
  });

  it.each([
    "https://evil.example/hangar",
    "javascript:alert(1)",
    undefined,
    42,
  ])("sends %j to the site instead", (url) => {
    expect(safeUrl(url, ORIGIN)).toBe(`${ORIGIN}/`);
  });
});

describe("notificationOptions", () => {
  it("carries the body, the tag and a safe link", () => {
    const options = notificationOptions(
      {
        title: "Invited",
        body: "Join us",
        url: "https://evil.example",
        tag: "fleet_invite:1",
        notificationId: "abc",
      },
      ORIGIN,
      "/vite/assets/icon.png",
    );

    expect(options).toEqual({
      body: "Join us",
      icon: "/vite/assets/icon.png",
      tag: "fleet_invite:1",
      data: { url: `${ORIGIN}/`, notificationId: "abc" },
    });
  });
});

describe("pickClient", () => {
  const onPage = { url: `${ORIGIN}/fleets/invites` };
  const elsewhere = { url: `${ORIGIN}/hangar` };
  const foreign = { url: "https://other.example/" };

  it("focuses a tab already on the page without navigating it", () => {
    expect(
      pickClient([elsewhere, onPage], `${ORIGIN}/fleets/invites`, ORIGIN),
    ).toEqual({ client: onPage, navigate: false });
  });

  it("sends another tab of the site to the page", () => {
    expect(
      pickClient([foreign, elsewhere], `${ORIGIN}/fleets/invites`, ORIGIN),
    ).toEqual({ client: elsewhere, navigate: true });
  });

  it("finds nothing when no tab of the site is open", () => {
    expect(
      pickClient([foreign], `${ORIGIN}/fleets/invites`, ORIGIN),
    ).toBeUndefined();
  });
});
