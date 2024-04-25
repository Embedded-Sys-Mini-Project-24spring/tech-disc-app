<script setup lang="ts">
import { ref, computed, onMounted, onUpdated} from 'vue' 
import Dropdown from 'primevue/dropdown';
import Button from 'primevue/button';
import Textarea from 'primevue/textarea';
import InputText from 'primevue/inputtext';
import FloatLabel from 'primevue/floatlabel';
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

import {
  AmbientLight,
  PointLight,
  Camera,
  GltfModel,
  Renderer,
  Scene,
  Object3D,
  type RendererPublicInterface
} from 'troisjs';

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

const accel_x = ref<Array<number>>([])
const accel_y = ref<Array<number>>([])
const accel_z = ref<Array<number>>([])


const gyro_x = ref<Array<number>>([])
const gyro_y = ref<Array<number>>([])
const gyro_z = ref<Array<number>>([])

const angle_xs = ref<Array<number>>([])
const angle_ys = ref<Array<number>>([])
const angle_zs = ref<Array<number>>([])

const temperature = ref<number>(NaN);
const celsius = computed(() => temperature.value)
const cnt = ref<Array<Number>>([])
const rpm = ref(0)

const messages = ref<Array<String>>([])
const messages_str = computed(() => {return messages.value.join("\n")}) 
const regex_float = /[+-]?\d+(\.\d+)?/
const re_acc = /accel_xout:([+-]?\d+(\.\d+)?).;accel_yout:([+-]?\d+(\.\d+)?).;accel_zout:([+-]?\d+(\.\d+)?).;gyro_xout:([+-]?\d+(\.\d+)?).;gyro_yout:([+-]?\d+(\.\d+)?).;gyro_zout:([+-]?\d+(\.\d+)?).;temp:([+-]?\d+(\.\d+)?).;cnt:([0-9]+).;angle_x:([+-]?\d+(\.\d+)?).;angle_y:([+-]?\d+(\.\d+)?).;rpm:([+-]?\d+(\.\d+)?)/;

function reading_16bit_to_range(reading: number) {
    return reading / (32_767 + (reading >= 0? 0: 1))
}

function readings_to_float(reading: string) {
    return Number(reading)
    // return reading_16bit_to_range(Number(reading))
}

const chartData = ref<ChartData<'line'>>({
        datasets: [
        ]
    });

const chartData_gyro = ref<ChartData<'line'>>({
        datasets: [
        ]
    });

const chartData_angle = ref<ChartData<'line'>>({
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

const MAX_LEN = 500;

function truncate_msgs() {
    const diff_messages = messages.value.length - MAX_LEN;
    if (diff_messages > 0) {
        messages.value.splice(0, diff_messages)
    }
}

const process_message = (msg) => {

    messages.value.push(msg);
    truncate_msgs()
    if (re_acc.test(msg)) {
        // console.log(ev.detail);
        const match = msg.match(re_acc);

        accel_x.value.push(readings_to_float(match[1]))
        accel_y.value.push(readings_to_float(match[3]))
        accel_z.value.push(readings_to_float(match[5]))
        gyro_x.value.push(readings_to_float(match[7]))
        gyro_y.value.push(readings_to_float(match[9]))
        gyro_z.value.push(readings_to_float(match[11]))
        temperature.value = Number(match[13])
        cnt.value.push(Number(match[15]))
        let angle_x = readings_to_float(match[16])
        let angle_y = readings_to_float(match[18])
        let angle_z = readings_to_float(match[18])
        let rpm_val = readings_to_float(match[20])
        rpm.value = rpm_val

        angle_xs.value.push(angle_x)
        angle_ys.value.push(angle_y)
        angle_zs.value.push(angle_z)

        const diff = cnt.value.length - MAX_LEN;
        if (diff > 0) {
            accel_x.value.splice(0, diff)
            accel_y.value.splice(0, diff)
            accel_z.value.splice(0, diff)
            gyro_x.value.splice(0, diff)
            gyro_y.value.splice(0, diff)
            gyro_z.value.splice(0, diff)
            cnt.value.splice(0, diff)
            angle_xs.value.splice(0, diff)
            angle_ys.value.splice(0, diff)
            angle_zs.value.splice(0, diff)
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

        chartData_angle.value = setChartData(
            cnt.value.slice(-span), 
            angle_xs.value.slice(-span),
            angle_ys.value.slice(-span),
            angle_zs.value.slice(-span),
            "angle_x",
            "angle_y",
            "angle_z"
        )
        // console.log(chartData.value)
        //console.log("match: " + match[1].toString() + " " + match[2].toString())
    } else {
        console.log("No match");
    }
}

const handleSerialEvent = (ev) => {
    process_message(ev.detail)
}

serial.addEventListener('serial-connected', handleSerialEvent);

serial.addEventListener('serial-disconnected', handleSerialEvent);

serial.addEventListener('serial-error', handleSerialEvent);

serial.addEventListener('serial-data', handleSerialEvent);

const baud_rate = ref(115200)

const baud_rates = ref([9600, 19200, 38400, 57600, 115200]);

const port_open = ref(false)
const port_open_str = computed(() => {return port_open.value? "close": "open"})

function calculate_angles() {
    if (accel_x.value.length >= 1) {
        const index = accel_x.value.length - 1;
        const acc_x = accel_x.value[index]
        const acc_y = accel_y.value[index]
        const acc_z = accel_z.value[index]

        const roll = Math.atan(acc_y / Math.sqrt(acc_x ** 2 + acc_z ** 2))
        const pitch = Math.atan(-acc_x / Math.sqrt(acc_y ** 2 + acc_z ** 2))
        return [roll, pitch]
    } else {
        return [0, 0]
    }
}

        

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


const rendererC = ref()
const model_path = import.meta.env.BASE_URL + "/assets/models/mpu_6050_free_download.glb"
const model_ref = ref()
function onLoad(obj) {
    const model = obj.scene;
    model_ref.value = model;
}

onUpdated(() => {
  let textarea = document.getElementById('ta')
    if (textarea != null) {
        textarea.scrollTop = textarea.scrollHeight
    }
})

onMounted(() => {
  const renderer = rendererC.value as RendererPublicInterface
  renderer.onBeforeRender(() => {
      if (model_ref.value != null) {
        const [roll, pitch ] = calculate_angles()
          console.log(`roll: ${roll} pitch: ${pitch}`)
        model_ref.value.rotation.x = roll
        model_ref.value.rotation.z = -pitch
      }
  })
});

function on_open(event) {
      console.log(event);
      console.log("Successfully connected to the echo websocket server...");
};


const source = ref("serial")
const sources = ref(["serial", "ws"])
const url = ref("192.168.4.1/ws")
let socket;

const cmd = ref("")

function on_message(event) {
      // console.log("look, I got something from server");
      console.log(event.data);
      process_message(event.data)
      // socket.send("dfsdfd\n")
};

function open_close_ws() {
    if (port_open.value) {
        socket.close()
    } else {
        socket = new WebSocket("ws://" + url.value);
        socket.onmessage = on_message
        socket.onopen = on_open
    }
    port_open.value = !port_open.value;
}

function send_msg() {
    let msg = cmd.value
    console.log(msg)
    messages.value.push("> " + msg);
    if (port_open.value) {
        if (source.value == 'ws') {
            socket.send(msg)
        } else if (source.value == 'serial') {
            serial.send(msg + "\n");
        }
    }
    cmd.value = ""
}

</script>

<template>
    <div class="flex flex-column gap-6">
    <div class="card flex justify-content-center">
        Source: <Dropdown v-model="source" :options="sources" placeholder="Select a data source" class="w-full md:w-14rem" />
    </div>

    <div v-if="source == 'serial'" class="card flex justify-content-center">
        Baud Rate: <Dropdown v-model="baud_rate" :options="baud_rates" placeholder="Select a baud rate" class="w-full md:w-14rem" />
         <Button v-bind:label="port_open_str" @click="open_close"/>
    </div>
    <div v-if="source == 'ws'" class="card flex justify-content-center">
        URL: <Textarea v-model="url" autoResize rows="1" cols="16" />
         <Button v-bind:label="port_open_str" @click="open_close_ws"/>
    </div>
    <Textarea id="ta" v-model="messages_str" rows="10" cols="70" disabled/>
    <div class="card flex justify-content-center">
        <FloatLabel>
            <InputText id="CMD" v-model="cmd" @keyup.enter="send_msg"/>
            <label for="CMD">CMD</label>
        </FloatLabel>
    </div>
    <div class="card">
        <p>Temperature: {{celsius.toFixed(2)}} °C</p>
        <p>RPM: {{rpm.toFixed(2)}}</p>
    </div>
    <div class="card">
        <Line :data="chartData" :options="chartOptions" />
    </div>
    <div class="card">
        <Line :data="chartData_gyro" :options="chartOptions" />
    </div>
    <div class="card">
        <Line :data="chartData_angle" :options="chartOptions" />
    </div>
    <div class="card">
      <Renderer ref="rendererC" antialias :orbit-ctrl="{ enableDamping: true }" 
      resize="true"
      >
        <Camera :position="{ z: 10 }" />
        <Scene>
          <AmbientLight></AmbientLight>
          <PointLight :position="{ x: 10, y: 10, z: 10 }" />
          <GltfModel :src="model_path" @load="onLoad"/>
        </Scene>
      </Renderer>
    </div>
    </div>
</template>

