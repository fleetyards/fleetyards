/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { HangarClassificationMetric } from './HangarClassificationMetric';
import type { HangarGroupMetric } from './HangarGroupMetric';
import type { HangarMetrics } from './HangarMetrics';
export type HangarStats = {
    total: number;
    wishlistTotal: number;
    classifications: Array<HangarClassificationMetric>;
    groups: Array<HangarGroupMetric>;
    metrics: HangarMetrics;
};

