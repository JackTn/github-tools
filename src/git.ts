import * as dotenv from 'dotenv' // see https://github.com/motdotla/dotenv#how-do-i-use-dotenv-with-import
dotenv.config()

import {Octokit} from '@octokit/core'
import {throttling} from '@octokit/plugin-throttling'
import {paginateRest, composePaginateRest} from '@octokit/plugin-paginate-rest'
import {delay, flat} from './utils'
import {restEndpointMethods} from '@octokit/plugin-rest-endpoint-methods'
import * as fs from 'fs'
import moment from 'moment'
import lodash from 'lodash'
import {json2Excel, readFile} from './excel'
import {is3monthBefore, timePrefix} from './time'
import {Branches} from './types'

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

export const deleteBranches = async () => {
  console.time('getListBranches')

  const parameters = {
    owner: 'microsoftdocs',
    repo: 'AzureRestPreview',
    per_page: 100
  }
  let branches: string | any[] = []

  for await (const response of octokit.paginate.iterator(
    octokit.rest.repos.listBranches,
    parameters
  )) {
    // do whatever you want with each response, break out of the loop, etc.
    branches = [...branches, ...response.data]
    console.log('%d branches found', branches.length)
    // debug
    if (branches.length >= 10000) {
      break
    }
  }

  console.timeEnd('getListBranches')

  console.time('getBranches')
  let branchInfoList: Branches[] = []
  for (const branchName of branches) {
    // api rate limit
    await delay(500)
    const {data} = await octokit.request(
      'GET /repos/{owner}/{repo}/branches/{branch}',
      {
        owner: 'microsoftdocs',
        repo: 'AzureRestPreview',
        branch: branchName.name
      }
    )
    branchInfoList = [...branchInfoList, data]
    console.log('%d branch info found', branchInfoList.length)
  }
  console.timeEnd('getBranches')

  let deleteBranches: Branches[] = []
  let unDeleteBranches: Branches[] = []

  for (const branchInfo of branchInfoList) {
    const date = branchInfo.commit?.commit?.committer?.date
    if (date && is3monthBefore(date) > 0) {
      deleteBranches.push(branchInfo)
    } else {
      unDeleteBranches.push(branchInfo)
    }
  }

  console.log('%d will delete branch', deleteBranches.length)
  console.log('%d no delete branch', unDeleteBranches.length)

//   fs.writeFileSync('deleteBranches.json', deleteBranches);

  
  /**
  console.time('deleteBranches')
  for (const branchInfo1 of deleteBranches) {
    const data = await octokit.request(
      'DELETE /repos/{owner}/{repo}/git/refs/{ref}',
      {
        owner: 'microsoftdocs',
        repo: 'AzureRestPreview',
        ref: `heads/${branchInfo1.name}`
      }
    )
    console.log(data)
  }
  console.timeEnd('deleteBranches')
    */

  // deleteBranches excel
  const workSheetData = deleteBranches.map(i => flat(i))
  // const workSheetData = branches.map(i => lodash.pick(i, 'name'))
  const workSheetName = 'sheet1'
  const workFileName = `deleteBranches-${timePrefix}`
  const workSheetColumnName = [...Object.keys(workSheetData[0])]
  const workFileType = 'xlsx'

  json2Excel(
    workSheetData,
    workSheetColumnName,
    workSheetName,
    workFileName,
    workFileType
  )

  // unDeleteBranches excel
  const workSheetData1 = unDeleteBranches.map(i => flat(i))
  const workSheetName1 = 'sheet1'
  const workFileName1 = `unDeleteBranches-${timePrefix}`
  const workSheetColumnName1 = [...Object.keys(workSheetData[0])]
  const workFileType1 = 'xlsx'

  json2Excel(
    workSheetData1,
    workSheetColumnName1,
    workSheetName1,
    workFileName1,
    workFileType1
  )

  return branches
}
