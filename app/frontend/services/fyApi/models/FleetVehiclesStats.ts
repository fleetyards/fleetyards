/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { HangarClassificationMetric } from './HangarClassificationMetric';
import type { HangarMetrics } from './HangarMetrics';

export type FleetVehiclesStats = {
    total: number;
    classifications: Array<HangarClassificationMetric>;
    metrics: HangarMetrics;
};

