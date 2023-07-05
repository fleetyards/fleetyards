/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { Component } from './Component';
import type { ModelHardpointCategoryEnum } from './ModelHardpointCategoryEnum';
import type { ModelHardpointGroupEnum } from './ModelHardpointGroupEnum';
import type { ModelHardpointLoadout } from './ModelHardpointLoadout';
import type { ModelHardpointSizeEnum } from './ModelHardpointSizeEnum';
import type { ModelHardpointSourceEnum } from './ModelHardpointSourceEnum';
import type { ModelHardpointSubCategoryEnum } from './ModelHardpointSubCategoryEnum';
import type { ModelHardpointTypeEnum } from './ModelHardpointTypeEnum';

export type ModelHardpoint = {
    id: string;
    category?: ModelHardpointCategoryEnum | null;
    categoryLabel?: string | null;
    component?: Component | null;
    details?: string | null;
    group: ModelHardpointGroupEnum;
    itemSlots?: string | null;
    key: string;
    loadoutIdentifier?: string | null;
    loadouts?: Array<ModelHardpointLoadout>;
    mount?: string | null;
    name?: string | null;
    size?: ModelHardpointSizeEnum | null;
    sizeLabel?: string | null;
    source?: ModelHardpointSourceEnum;
    subCategory?: ModelHardpointSubCategoryEnum | null;
    subCategoryLabel?: string | null;
    type: ModelHardpointTypeEnum;
};

