<template>
  <q-layout view="lHh Lpr lFf">
    <q-header elevated>
      <q-toolbar>
        <q-toolbar-title class="absolute-center">
          Lab 5
        </q-toolbar-title>

        <q-btn
          @click="mainPage = false"
          v-if="mainPage"
          to="/settings"
          flat
          icon-right="account_circle"
          label="Sensor Profile"
          class="absolute-right" />

        <q-btn
          @click="mainPage = true"
          v-else
          to="/"
          flat
          icon-right="thermostat"
          label="Temperature Readings"
          class="absolute-right" />
      </q-toolbar>
    </q-header>

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script>
export default {
  name: 'MainLayout',
  data () {
    return {
      mainPage: true
    }
  }
}
</script>
