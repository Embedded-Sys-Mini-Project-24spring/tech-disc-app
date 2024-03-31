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
  ChartData
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

const accel_x = ref([])
const accel_y = ref([])
const accel_z = ref([])
const cnt = ref([])

const messages = ref("")
const re_acc = /accel_xout:(-?[0-9]+).;accel_yout:(-?[0-9]+).;accel_zout:(-?[0-9]+);/;

function update_chartData() {
}
const chartData = ref<ChartData<'line'>>({
        datasets: [
        ]
    });

const setChartData = (label, ac_x, ac_y, ac_z) => {
    const documentStyle = getComputedStyle(document.documentElement);

    return {
        labels: label,
        datasets: [
            {
                label: 'Accel X',
                data: ac_x, 
                fill: false,
                borderColor: documentStyle.getPropertyValue('--cyan-500'),
                tension: 0.4
            },
            {
                label: 'Accel Y',
                data: ac_y, 
                fill: false,
                borderColor: documentStyle.getPropertyValue('--blue-500'),
                tension: 0.4
            },
            {
                label: 'Accel Z',
                data: ac_z, 
                fill: false,
                borderColor: documentStyle.getPropertyValue('--red-500'),
                tension: 0.4
            }
        ]
    };
};

const handleSerialEvent = (ev) => {
    if (re_acc.test(ev.detail)) {
        // console.log(ev.detail);
        const match = ev.detail.match(re_acc);
        accel_x.value.push(Number(match[1]))
        accel_y.value.push(Number(match[2]))
        accel_z.value.push(Number(match[3]))

        const span = 100
        cnt.value.push(cnt.value.length)
        chartData.value = setChartData(
            [...cnt.value.slice(-span)], 
            [...accel_x.value.slice(-span)],
            [...accel_y.value.slice(-span)],
            [...accel_z.value.slice(-span)]
        )
        //console.log(chartData.value)
        //console.log("match: " + match[1].toString() + " " + match[2].toString())
    }
    messages.value += ev.detail;

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
        <Dropdown v-model="baud_rate" :options="baud_rates" placeholder="Select a baud rate" class="w-full md:w-14rem" />
        <Button v-bind:label="port_open_str" @click="open_close"/>
    </div>
    <Textarea v-model="messages" rows="20" cols="90" disabled/>
    <div class="card">
        <Line :data="chartData" :options="chartOptions" />
        <!-- <Chart type="line" :data="chartData" :options="chartOptions" class="h-30rem" /> -->
    </div>

</template>

