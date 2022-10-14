import moment from 'moment'

export const timePrefix = moment().format('YYYY-MM-DD-HH-mm-ss')

export const is3monthBefore = (time: string) => {
  const now = moment().subtract(3, 'months').format('YYYY-MM-DD')
  const timeFormat = moment(time)
  return moment(now).diff(timeFormat, 'days')
}
