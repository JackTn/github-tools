import * as dotenv from 'dotenv' // see https://github.com/motdotla/dotenv#how-do-i-use-dotenv-with-import
dotenv.config()

import {Octokit} from '@octokit/core'
import {throttling} from '@octokit/plugin-throttling'
import {paginateRest, composePaginateRest} from '@octokit/plugin-paginate-rest'
import {restEndpointMethods} from '@octokit/plugin-rest-endpoint-methods'
import {flat} from './utils'

const MyOctokit = Octokit.plugin(throttling, paginateRest, restEndpointMethods)

const octokit = new MyOctokit({
  auth: process.env.GITHUB_TOKEN,
  throttle: {
    onRateLimit: (
      retryAfter: any,
      options: {method: any; url: any; request: {retryCount: number}},
      octokit: {
        log: {warn: (arg0: string) => void; info: (arg0: string) => void}
      }
    ) => {
      octokit.log.warn(
        `Request quota exhausted for request ${options.method} ${options.url}`
      )

      if (options.request.retryCount === 0) {
        // only retries once
        octokit.log.info(`Retrying after ${retryAfter} seconds!`)
        return true
      }
    },
    onSecondaryRateLimit: (
      retryAfter: any,
      options: {method: any; url: any},
      octokit: {log: {warn: (arg0: string) => void}}
    ) => {
      // does not retry, only logs a warning
      octokit.log.warn(
        `SecondaryRateLimit detected for request ${options.method} ${options.url}`
      )
    }
  }
})

const response = async () => {
  const {data} = await octokit.request('GET /repos/{owner}/{repo}/branches', {
    owner: 'JackTn',
    repo: 'github-tools'
  })
  console.log(data)
  return data
}

export const issues = async () => {
  const issues = await octokit.paginate('GET /repos/{owner}/{repo}/issues', {
    owner: 'octocat',
    repo: 'hello-world',
    since: '2010-10-01',
    per_page: 100
  })
  console.log(issues.length)
  return issues
}

export const branches = async () => {
  const branch = await octokit.paginate('GET /repos/{owner}/{repo}/branches', {
    owner: 'microsoftdocs',
    repo: 'AzureRestPreview',
    per_page: 100
  })
  console.log(branch.length)
  return branch
}

export const getBranchesInfo = async () => {
  const {data} = await octokit.request(
    'GET /repos/{owner}/{repo}/branches/{branch}',
    {
      owner: 'microsoftdocs',
      repo: 'AzureRestPreview',
      branch: '8bc8fd05-acce-4293-b2dd-64b6a40b5756'
    }
  )
  console.log(flat(data))
  console.log(data.commit?.commit?.committer?.date)
  console.log(data.commit?.commit?.author?.name)
}

export const deleteRef = async () => {
  const data = await octokit.request(
    'DELETE /repos/{owner}/{repo}/git/refs/{ref}',
    {
      owner: 'microsoftdocs',
      repo: 'AzureRestPreview',
      ref: `heads/0a0aa6b1-e8ff-4018-83ab-860c57c7ab89`
    }
  )
  console.log(data)
}
