<script setup lang="ts">
import { ref, computed } from 'vue' 
import Dropdown from 'primevue/dropdown';
import Button from 'primevue/button';
import Textarea from 'primevue/textarea';
import SerialMonitor from '@ridge18/web-serial-monitor';

const serial = new SerialMonitor({mode: "text", parseLines: true});

const messages = ref("")

const handleSerialEvent = (ev) => {
    messages.value += ev.detail;
    console.log(ev.detail);
}

serial.addEventListener('serial-connected', handleSerialEvent);

serial.addEventListener('serial-disconnected', handleSerialEvent);

serial.addEventListener('serial-error', handleSerialEvent);

serial.addEventListener('serial-data', handleSerialEvent);

const baud_rate = ref(115200)

const baud_rates = ref([9600, 19200, 38400, 57600, 115200]);

const port_open = ref(false)
const port_open_str = computed(() => {return port_open.value? "close": "open"})

function open_close() {
    if (port_open.value) {
        serial.disconnect();
    } else {
        serial.connect(115200).then(() => { // connect at 57600 bauds rate.
            console.log("connect")
            //serial.send("Hello serial\n");
        })
            .catch((error) => {
            console.error(error);
        }); 
    }
    port_open.value = !port_open.value;
}

</script>

<template>
    <div class="card flex justify-content-center">
        <Dropdown v-model="baud_rate" :options="baud_rates" placeholder="Select a baud rate" class="w-full md:w-14rem" />
        <Button v-bind:label="port_open_str" @click="open_close"/>
    </div>

    <Textarea v-model="messages" rows="20" cols="90" disabled/>

</template>

