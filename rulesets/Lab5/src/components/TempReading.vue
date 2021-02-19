<template>
  <form>
    <q-field outined>
        <q-item-section>
            <q-item-label>Temperature</q-item-label>
            <q-item-label>{{ reading.Temperature }}</q-item-label>
        </q-item-section>
        <q-item-section>
            <q-item-label>Time</q-item-label>
            <q-item-label>{{ reading.Timestamp }}</q-item-label>
        </q-item-section>
    </q-field>
  </form>
</template>

<script>
export default {
  props: ['reading']
}
</script>
