// https://docs.sheetjs.com/docs/
// https://cdn.sheetjs.com/
import * as XLSX from 'xlsx'

export const json2Excel = (
  initData: Array<{[key: string]: string}>,
  workSheetColumnName: string[],
  workSheetName: string,
  workFileName: string,
  workFileType: string
) => {
  const iData: Array<{[key: string]: string}> = initData
  const data = iData.map(e => {
    return Object.values(e)
  })
  const workBook = XLSX.utils.book_new()
  const workSheetData = [workSheetColumnName, ...data]

  const workSheet = XLSX.utils.aoa_to_sheet(workSheetData)
  XLSX.utils.book_append_sheet(workBook, workSheet, workSheetName)

  XLSX.writeFile(workBook, `${workFileName}.${workFileType}`)
}

export const readFile = (fileName: string) => {
  return XLSX.readFile(fileName)
}
