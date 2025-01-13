/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CargoHoldContainerSize } from './CargoHoldContainerSize';
import type { CargoHoldDimension } from './CargoHoldDimension';
import type { CargoHoldLimit } from './CargoHoldLimit';
export type CargoHold = {
    dimensions: CargoHoldDimension;
    capacity: number;
    maxContainerSize: CargoHoldContainerSize;
    limits: {
        min: CargoHoldLimit;
        max?: CargoHoldLimit;
    };
};

