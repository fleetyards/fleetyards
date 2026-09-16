// `?modal=<name>` is what opens a modal that belongs to no record; see
// useModalQuery, which writes and reads it. The name lives here because the
// router needs it too: a navigation that only opens or closes a modal must
// leave the page under it where it stands.
export const MODAL_QUERY_PARAM = "modal";

type ModalRoute = {
  path: string;
  hash: string;
  query: Record<string, unknown>;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

// A query value is a string, a repeated parameter's array of them, or -- the
// router parses with qs, so `q[s]=name+asc` arrives as one -- a nested object.
// Compared as what it is rather than as its text: `["a,b"]` and `["a", "b"]`
// are one string either way, and calling those two addresses the same page
// would leave the scroll position alone for a navigation that did change it.
function sameQueryValue(value: unknown, otherValue: unknown): boolean {
  if (value === otherValue) return true;

  if (Array.isArray(value) || Array.isArray(otherValue)) {
    return (
      Array.isArray(value) &&
      Array.isArray(otherValue) &&
      value.length === otherValue.length &&
      value.every((entry, index) => sameQueryValue(entry, otherValue[index]))
    );
  }

  if (isRecord(value) && isRecord(otherValue)) {
    const keys = Object.keys(value);

    return (
      keys.length === Object.keys(otherValue).length &&
      keys.every(
        (key) =>
          key in otherValue && sameQueryValue(value[key], otherValue[key]),
      )
    );
  }

  return false;
}

function keysApartFromModal(query: Record<string, unknown>) {
  return Object.keys(query).filter((key) => key !== MODAL_QUERY_PARAM);
}

// Two addresses that ask for the same page, differing at most in which modal
// is open.
export function sameApartFromModalQuery(to: ModalRoute, from: ModalRoute) {
  if (to.path !== from.path || to.hash !== from.hash) return false;

  const keys = keysApartFromModal(to.query);

  return (
    keys.length === keysApartFromModal(from.query).length &&
    keys.every((key) => sameQueryValue(to.query[key], from.query[key]))
  );
}
