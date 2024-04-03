<script setup lang="ts">
import { ref, computed, onMounted } from 'vue' 
import Dropdown from 'primevue/dropdown';
import Button from 'primevue/button';
import Textarea from 'primevue/textarea';
import SerialMonitor from '@ridge18/web-serial-monitor';
//import Chart from 'primevue/chart';
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  type ChartData
} from 'chart.js'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
)

const serial = new SerialMonitor({mode: "text", parseLines: true});

const accel_x = ref<Array<Number>>([])
const accel_y = ref<Array<Number>>([])
const accel_z = ref<Array<Number>>([])


const gyro_x = ref<Array<Number>>([])
const gyro_y = ref<Array<Number>>([])
const gyro_z = ref<Array<Number>>([])

const temperature = ref<number>(NaN);
const celsius = computed(() => temperature.value / 340 + 36.53)
const cnt = ref<Array<Number>>([])

const messages = ref<Array<String>>([])
const messages_str = computed(() => {return messages.value.toString()}) 
const re_acc = /accel_xout:(-?[0-9]+).;accel_yout:(-?[0-9]+).;accel_zout:(-?[0-9]+).;gyro_xout:(-?[0-9]+).;gyro_yout:(-?[0-9]+).;gyro_zout:(-?[0-9]+).;temp:(-?[0-9]+).;cnt:([0-9]+)/;

function update_chartData() {
}
const chartData = ref<ChartData<'line'>>({
        datasets: [
        ]
    });

const chartData_gyro = ref<ChartData<'line'>>({
        datasets: [
        ]
    });
const setChartData = (label, ac_x, ac_y, ac_z, label_x, label_y, label_z) => {
    const documentStyle = getComputedStyle(document.documentElement);

    return {
        labels: label,
        datasets: [
            {
                label: label_x,
                data: ac_x, 
                fill: false,
                borderColor: documentStyle.getPropertyValue('--cyan-500'),
                tension: 0.4
            },
            {
                label: label_y,
                data: ac_y, 
                fill: false,
                borderColor: documentStyle.getPropertyValue('--blue-500'),
                tension: 0.4
            },
            {
                label: label_z,
                data: ac_z, 
                fill: false,
                borderColor: documentStyle.getPropertyValue('--red-500'),
                tension: 0.4
            }
        ]
    };
};

const handleSerialEvent = (ev) => {
    
    const MAX_LEN = 1000;
    messages.value.push(ev.detail);
    const diff_messages = messages.value.length - MAX_LEN;
    if (diff_messages > 0) {
        messages.value.splice(0, diff_messages)
    }
    if (re_acc.test(ev.detail)) {
        // console.log(ev.detail);
        const match = ev.detail.match(re_acc);

        accel_x.value.push(Number(match[1]))
        accel_y.value.push(Number(match[2]))
        accel_z.value.push(Number(match[3]))
        gyro_x.value.push(Number(match[4]))
        gyro_y.value.push(Number(match[5]))
        gyro_z.value.push(Number(match[6]))
        temperature.value = Number(match[7])
        cnt.value.push(Number(match[8]))
        const diff = cnt.value.length - MAX_LEN;
        if (diff > 0) {
            accel_x.value.splice(0, diff)
            accel_y.value.splice(0, diff)
            accel_z.value.splice(0, diff)
            gyro_x.value.splice(0, diff)
            gyro_y.value.splice(0, diff)
            gyro_z.value.splice(0, diff)
            cnt.value.splice(0, diff)
        }

        const span = 100
        chartData.value = setChartData(
            cnt.value.slice(-span), 
            accel_x.value.slice(-span),
            accel_y.value.slice(-span),
            accel_z.value.slice(-span),
            "accel_x",
            "accel_y",
            "accel_z"
        )

        chartData_gyro.value = setChartData(
            cnt.value.slice(-span), 
            gyro_x.value.slice(-span),
            gyro_y.value.slice(-span),
            gyro_z.value.slice(-span),
            "gyro_x",
            "gyro_y",
            "gyro_z"
        )
        //console.log(chartData.value)
        //console.log("match: " + match[1].toString() + " " + match[2].toString())
    } else {
        console.log("No match");
    }

}

serial.addEventListener('serial-connected', handleSerialEvent);

serial.addEventListener('serial-disconnected', handleSerialEvent);

serial.addEventListener('serial-error', handleSerialEvent);

serial.addEventListener('serial-data', handleSerialEvent);

const baud_rate = ref(115200)

const baud_rates = ref([9600, 19200, 38400, 57600, 115200]);

const port_open = ref(false)
const port_open_str = computed(() => {return port_open.value? "close": "open"})


onMounted(() => {
});

        

const setChartOptions = () => {
    const documentStyle = getComputedStyle(document.documentElement);
    const textColor = documentStyle.getPropertyValue('--text-color');
    const textColorSecondary = documentStyle.getPropertyValue('--text-color-secondary');
    const surfaceBorder = documentStyle.getPropertyValue('--surface-border');

    return {
        maintainAspectRatio: false,
        aspectRatio: 0.6,
        plugins: {
            legend: {
                labels: {
                    color: textColor
                }
            }
        },
        scales: {
            x: {
                ticks: {
                    color: textColorSecondary
                },
                grid: {
                    color: surfaceBorder
                }
            },
            y: {
                ticks: {
                    color: textColorSecondary
                },
                grid: {
                    color: surfaceBorder
                }
            }
        }
    };
}


const documentStyle = getComputedStyle(document.documentElement);
const chartOptions = computed(setChartOptions);

function open_close() {
    if (port_open.value) {
        serial.disconnect();
    } else {
        serial.connect(baud_rate.value).then(() => { // connect at 57600 bauds rate.
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
        Baud Rate: <Dropdown v-model="baud_rate" :options="baud_rates" placeholder="Select a baud rate" class="w-full md:w-14rem" />
         <Button v-bind:label="port_open_str" @click="open_close"/>
    </div>
    <div class="card">
        <p>Temperature: {{celsius.toFixed(2)}} °C</p>
    </div>
    <Textarea v-model="messages_str" rows="20" cols="90" disabled/>
    <div class="card">
        <Line :data="chartData" :options="chartOptions" />
        <!-- <Chart type="line" :data="chartData" :options="chartOptions" class="h-30rem" /> -->
    </div>
    <div class="card">
        <Line :data="chartData_gyro" :options="chartOptions" />
        <!-- <Chart type="line" :data="chartData" :options="chartOptions" class="h-30rem" /> -->
    </div>

</template>

