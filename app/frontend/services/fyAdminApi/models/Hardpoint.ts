/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Component } from './Component';
import type { HardpointCategoryEnum } from './HardpointCategoryEnum';
import type { HardpointGroupEnum } from './HardpointGroupEnum';
import type { HardpointSourceEnum } from './HardpointSourceEnum';
export type Hardpoint = {
    id: string;
    group?: HardpointGroupEnum;
    groupKey?: string;
    category?: HardpointCategoryEnum;
    name: string;
    minSize?: number;
    maxSize?: number;
    source?: HardpointSourceEnum;
    types?: Array<string>;
    component?: Component;
    hardpoints?: Array<Hardpoint>;
    createdAt: string;
    updatedAt: string;
};

