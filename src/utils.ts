export function flat(obj: any, key = '', res: any = {}, isArray = false) {
  for (let [k, v] of Object.entries(obj)) {
    if (Array.isArray(v)) {
      let tmp = isArray ? key + '[' + k + ']' : key + k
      flat(v, tmp, res, true)
    } else if (typeof v === 'object' && v !== null) {
      let tmp = isArray ? key + '[' + k + '].' : key + k + '.'
      flat(v, tmp, res)
    } else {
      let tmp = isArray ? key + '[' + k + ']' : key + k
      res[tmp] = v
    }
  }
  return res
}

//   作者：兔子公主
//   链接：https://juejin.cn/post/6844904103609368589
//   来源：稀土掘金
//   著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

export function delay(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms))
}
