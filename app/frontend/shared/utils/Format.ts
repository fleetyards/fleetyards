export const formatSize = (size: number) => {
  if (size > 1024 * 1024 * 1024 * 1024) {
    return `${(size / 1024 / 1024 / 1024 / 1024).toFixed(2)} TB`;
  }
  if (size > 1024 * 1024 * 1024) {
    return `${(size / 1024 / 1024 / 1024).toFixed(2)} GB`;
  }
  if (size > 1024 * 1024) {
    return `${(size / 1024 / 1024).toFixed(2)} MB`;
  }
  if (size > 1024) {
    return `${(size / 1024).toFixed(2)} KB`;
  }
  return `${size.toString()} B`;
};
