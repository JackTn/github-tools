import {RestEndpointMethodTypes} from '@octokit/plugin-rest-endpoint-methods'

export type GetBranchParameters =
  RestEndpointMethodTypes['repos']['getBranch']['parameters']
export type GetBranchResponse =
  RestEndpointMethodTypes['repos']['getBranch']['response']

export type Branches = GetBranchResponse['data']

export type UpdateLabelParameters =
  RestEndpointMethodTypes['issues']['updateLabel']['parameters']
export type UpdateLabelResponse =
  RestEndpointMethodTypes['issues']['updateLabel']['response']

export type DeleteRefParameters =
  RestEndpointMethodTypes['git']['deleteRef']['parameters']
export type DeleteRefResponse =
  RestEndpointMethodTypes['git']['deleteRef']['response']
