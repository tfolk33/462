<template>
  <q-card>
    <modal-header>Add Task</modal-header>
    <form @submit.prevent="submitEdit">
      <q-card-section>
        <modal-sensor-name
          :name.sync="editToSubmit.name"
          ref="modalTaskName"/>
        <modal-due-date
          :dueDate.sync="taskToSubmit.dueDate"/>
        <modal-due-time
          :dueTime.sync="taskToSubmit.dueTime"
          v-if="taskToSubmit.dueDate" />
        </q-card-section>
      <modal-buttons/>
    </form>
  </q-card>
</template>

<script>
import { axiosPostInstance } from 'boot/axios'

export default {
  data () {
    return {
      editsToSubmit: {
        sensorName: '',
        sensorLocation: '',
        contactNumber: '',
        thresholdTemp: false
      }
    }
  },
  methods: {
    submitEdit () {
      this.editStore(this.editsToSubmit)
      this.$emit('close')
    },
    editStore () {
      axiosPostInstance.post('/sensor/profile_updated', {params: editsToSubmit})
        .then((response) => {
          console.log(response)
          this.load
        })
    }
  },
  components: {
    'modal-sensor-name': require('components/Modals/SensorName.vue').default
  }
}
</script>
