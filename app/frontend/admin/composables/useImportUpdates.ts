import {
  useSubscription,
  ChannelsEnum,
} from "@/shared/composables/useSubscription";

export const useImportUpdates = (importerName: string) => {
  const checkImportStatus = (data: string) => {
    const importData = JSON.parse(data);

    if (importData.type === importerName) {
      console.info(importData);
    }
  };

  useSubscription({
    channelName: ChannelsEnum.IMPORTS,
    received: checkImportStatus,
  });
};
