// Darkest under the text, so a bright cover never washes out a title. Shared by
// every cover card on the dashboard so they read as one treatment.
const SCRIM =
  "linear-gradient(90deg, rgb(0 0 0 / 0.8) 0%, rgb(0 0 0 / 0.45) 55%, rgb(0 0 0 / 0.35) 100%)";

export const coverStyle = (url: string) => ({
  backgroundImage: `${SCRIM}, url(${url})`,
});
