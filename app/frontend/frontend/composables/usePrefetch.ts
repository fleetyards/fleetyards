const getByKey = function getByKey(key: string) {
  return (window.DATA_PREFETCH || {})[key];
};

const cleanData = function cleanData(key: string) {
  if (!window.DATA_PREFETCH || !window.DATA_PREFETCH[key]) {
    return;
  }
  window.DATA_PREFETCH[key] = null;
};

export const usePrefetch = <T>(key: string): T | undefined => {
  const json = getByKey(key);
  cleanData(key);

  if (!json) {
    return undefined;
  }

  const element = JSON.parse(json);

  if (Array.isArray(element)) {
    return element.map((item) => JSON.parse(item)) as T;
  }

  return element;
};
