import axios from 'axios'
const axiosInstance = axios.create({
  baseURL: 'http://localhost:8010/proxy/sky/cloud/ckkq3njrp001doouac74ugnu4/'
})

const axiosPostInstance = axios.create({
  baseURL: 'http://localhost:8010/proxy/sky/event/ckkq3njrp001doouac74ugnu4/temp/'
})
export default ({ Vue }) => {
  Vue.prototype.$axios = axiosInstance
}
export { axiosInstance, axiosPostInstance }
