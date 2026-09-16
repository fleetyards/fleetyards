// `?modal=<name>` is what opens a modal that belongs to no record; see
// useModalQuery, which writes and reads it. The name lives here because the
// router needs it too: a navigation that only opens or closes a modal must
// leave the page under it where it stands.
export const MODAL_QUERY_PARAM = "modal";

type ModalQuery = Record<string, unknown>;

const keysApartFromModal = (query: ModalQuery) =>
  Object.keys(query).filter((key) => key !== MODAL_QUERY_PARAM);

// Two addresses that ask for the same page, differing at most in which modal
// is open.
export const sameApartFromModalQuery = (
  a: { path: string; hash: string; query: ModalQuery },
  b: { path: string; hash: string; query: ModalQuery },
) => {
  if (a.path !== b.path || a.hash !== b.hash) return false;

  const aKeys = keysApartFromModal(a.query);
  const bKeys = keysApartFromModal(b.query);

  return (
    aKeys.length === bKeys.length &&
    aKeys.every((key) => String(a.query[key]) === String(b.query[key]))
  );
};
