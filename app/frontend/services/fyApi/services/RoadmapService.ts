/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class RoadmapService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list roadmaps
     * @returns any successful
     * @throws ApiError
     */
    public getRoadmap(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/roadmap',
        });
    }

    /**
     * weeks roadmap
     * @returns any successful
     * @throws ApiError
     */
    public getRoadmapWeeks(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/roadmap/weeks',
        });
    }

}
