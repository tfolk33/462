<template>
    <div class="row q-mb-sm">
        <q-input
            outlined
            :value="name"
            @input="$emit('update:name', $event)"
            class="col"
            :rules="[val => !!val || 'field is required']"
            ref="name"
            autofocus
            label="Sensor Name"
            clearable/>
    </div>
</template>

<script>
export default {
  props: ['name']
}
</script>
