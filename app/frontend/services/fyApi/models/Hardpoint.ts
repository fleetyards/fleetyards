/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Component } from './Component';
import type { HardpointGroupEnum } from './HardpointGroupEnum';
import type { HardpointSourceEnum } from './HardpointSourceEnum';
export type Hardpoint = {
    id: string;
    component?: Component;
    group?: HardpointGroupEnum;
    name: string;
    minSize?: number;
    maxSize?: number;
    source?: HardpointSourceEnum;
    types?: Array<string>;
    createdAt: string;
    updatedAt: string;
};

