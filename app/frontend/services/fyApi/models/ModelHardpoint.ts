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
    category?: ModelHardpointCategoryEnum;
    categoryLabel?: string;
    component?: Component;
    details?: string;
    group: ModelHardpointGroupEnum;
    itemSlots?: number;
    key: string;
    loadoutIdentifier?: string;
    loadouts?: Array<ModelHardpointLoadout>;
    mount?: string;
    name?: string;
    size?: ModelHardpointSizeEnum;
    sizeLabel?: string;
    source?: ModelHardpointSourceEnum;
    subCategory?: ModelHardpointSubCategoryEnum;
    subCategoryLabel?: string;
    type: ModelHardpointTypeEnum;
    createdAt: string;
    updatedAt: string;
};

