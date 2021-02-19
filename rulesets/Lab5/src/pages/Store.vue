<template>
  <div>
    <q-banner class="bg-grey-3 q-pa-md">
      <div>Sensor Name:</div>
      {{ this.sensorInfo.SensorName }}
    </q-banner>

    <q-banner class="q-pa-md">
      <div>Sensor Location:</div>
      {{ this.sensorInfo.SensorLocation }}
    </q-banner>

    <q-banner class="bg-grey-3 q-pa-md">
      <div>Contact Number:</div>
      {{ this.sensorInfo.ContactNumber }}
    </q-banner>

    <q-banner class="q-pa-md">
      <div>Threshold Temperature:</div>
      {{ this.sensorInfo.ThresholdTemp }}
    </q-banner>

    <q-btn
      @click="showEdit = true"
      filled
      class="all-pointer-events"
      color="primary"
      size="24px"
      label="Edit Settings"
      v-if="!showEdit"
    />

    <q-dialog v-model="showEdit">
      <q-card>
      <form class="bg-grey-3">
        <div>
            <div class="row q-mb-sm">
                <q-input
                    clickable
                    outlined
                    v-model="sensorInfo.SensorName"
                    class="col"
                    autofocus
                    label="Sensor Name"
                    clearable/>
            </div>

            <div class="row q-mb-sm">
                <q-input
                    clickable
                    outlined
                    v-model="sensorInfo.SensorLocation"
                    class="col"
                    label="Sensor Location"
                    clearable/>
            </div>

            <div class="row q-mb-sm">
                <q-input
                    clickable
                    outlined
                    v-model="sensorInfo.ContactNumber"
                    class="col"
                    label="Contact Number"
                    clearable/>
            </div>

            <div class="row q-mb-sm">
                <q-input
                    clickable
                    outlined
                    v-model="sensorInfo.ThresholdTemp"
                    class="col"
                    label="Threshold Temperature"
                    clearable/>
            </div>

            <div class="row q-mb-sm">
                <q-btn
                    @click="editStore"
                    filled
                    class="all-pointer-events col"
                    color="primary"
                    size="24px"
                    label="Make Edit"
                />
            </div>
        </div>
      </form>
      </q-card>
    </q-dialog>

  </div>
</template>

<script>
import { axiosInstance, axiosPostInstance } from 'boot/axios'

export default {
  name: 'PageIndex',
  methods: {
    loadData () {
      axiosInstance.get('/sensor_profile/sensor_name')
        .then((response) => {
          this.sensorInfo.SensorName = response.data
        })
      axiosInstance.get('/sensor_profile/sensor_location')
        .then((response) => {
          this.sensorInfo.SensorLocation = response.data
        })
      axiosInstance.get('/sensor_profile/contact_number')
        .then((response) => {
          this.sensorInfo.ContactNumber = response.data
        })
      axiosInstance.get('/sensor_profile/threshold_temp')
        .then((response) => {
          this.sensorInfo.ThresholdTemp = response.data
        })
    },
    editStore () {
      axiosPostInstance.post('/sensor/profile_updated',
        {
          SensorName: this.sensorInfo.SensorName,
          SensorLocation: this.sensorInfo.SensorLocation,
          ContactNumber: this.sensorInfo.ContactNumber,
          ThresholdTemp: this.sensorInfo.ThresholdTemp
        })
        .then((response) => {
          console.log(response)
          this.loadData()
          this.showEdit = false
        })
    }
  },
  data () {
    return {
      sensorInfo: {
        SensorName: null,
        SensorLocation: null,
        ContactNumber: null,
        ThresholdTemp: null
      },
      showEdit: false
    }
  },
  created () {
    this.loadData()
  }
  // components: {
  //  'edit-settings': require('components/EditSettings.vue').default
  // }
}
</script>
