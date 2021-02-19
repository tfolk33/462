<template>
  <q-page>
    <div>
      <q-banner class="bg-grey-3">
        <div> Current Temperature:</div>
        {{ this.currentTemperature }}
      </q-banner>

      <q-banner>
        <div> Recent Temperature Readings:</div>
        <temp-reading
          v-for="(temp, key) in temperatures"
            :key="key"
            :reading="temp"
        >
        </temp-reading>
      </q-banner>

      <q-banner class="bg-grey-3">
        <div> Threshold Violations:</div>
        <temp-reading
          v-for="(temp, key) in thresholdViolations"
            :key="key"
            :reading="temp"
        >
        </temp-reading>
      </q-banner>
    </div>
  </q-page>
</template>

<script>
import { axiosInstance } from 'boot/axios'
import TempReading from '../components/TempReading.vue'

export default {
  components: { TempReading },
  name: 'PageIndex',
  methods: {
    loadData () {
      axiosInstance.get('/temperature_store/temperatures')
        .then((response) => {
          this.temperatures = response.data.reverse()
          this.currentTemperature = response.data[0].Temperature
        })
      axiosInstance.get('/temperature_store/threshold_violations')
        .then((response) => {
          this.thresholdViolations = response.data
        })
    },
    intervalLoadData () {
      setInterval(() => {
        this.loadData()
      }, 1000)
    }
  },
  data () {
    return {
      currentTemperature: null,
      temperatures: null,
      thresholdViolations: null,
      components: {
        tempReading: require('components/TempReading.vue').default
      }
    }
  },
  created () {
    this.loadData()
    this.intervalLoadData()
  }
}
</script>
