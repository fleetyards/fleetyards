/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { RoadmapItem } from '../models/RoadmapItem';
import type { RoadmapItemQuery } from '../models/RoadmapItemQuery';
import type { RoadmapWeek } from '../models/RoadmapWeek';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class RoadmapService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * Roadmap Items
     * @returns RoadmapItem successful
     * @throws ApiError
     */
    public roadmapItems({
        q,
    }: {
        q?: RoadmapItemQuery,
    }): CancelablePromise<Array<RoadmapItem>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/roadmap',
            query: {
                'q': q,
            },
        });
    }

    /**
     * Roadmap Weeks
     * @returns RoadmapWeek successful
     * @throws ApiError
     */
    public roadmapWeeks(): CancelablePromise<Array<RoadmapWeek>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/roadmap/weeks',
        });
    }

}
