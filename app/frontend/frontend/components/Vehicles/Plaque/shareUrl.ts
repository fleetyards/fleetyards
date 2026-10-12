// A shared plaque is the public hangar with the plaque open; the server reads
// the same `plaque` parameter to give the link the plaque as its preview.
export const plaqueShareUrl = (
  username: string,
  vehicleId: string,
  share?: string,
) => {
  const url = new URL(
    `/hangar/${encodeURIComponent(username)}/`,
    window.location.origin,
  );
  url.searchParams.set("plaque", vehicleId);
  if (share) {
    url.searchParams.set("share", share);
  }

  return url.toString();
};
