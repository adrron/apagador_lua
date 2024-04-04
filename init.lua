rele=1
button=5
leds=7
min=''
estado=gpio.LOW
duration=500
tiempoDeRetraso = 2000000  -- 1 segundo
estadoFoco='OFF'

-- wifi_config = dofile("eus_params.lua")
-- wifi.setmode(wifi.STATION)
-- local ssid = wifi_config.wifi_ssid
-- local password = wifi_config.wifi_password
-- local save= true
-- wifi.sta.config({ssid = ssid, password = password,save = save})
-- wifi.sta.connect()

gpio.mode(button, gpio.INT);
gpio.mode(leds, gpio.OUTPUT);
gpio.write(rele, gpio.LOW);
gpio.write(leds, estado);
enduser_setup.manual(false)

-- tmr.create():alarm(1800, tmr.ALARM_SINGLE, function()
        gpio.mode(rele, gpio.OUTPUT);
-- end)


-- tmr.delay(15000000)
-- print("WiFi:",wifi.sta.status(), wifi.sta.getip())
function switch_rele()
        if gpio.read(rele) == gpio.LOW   then 
                estadoFoco = "ON";    
                gpio.write(rele, gpio.HIGH);    
        elseif gpio.read(rele) == gpio.HIGH  then 
                estadoFoco = "OFF";    
                gpio.write(rele, gpio.LOW);  
        end
end
tmr.create():alarm(duration, tmr.ALARM_AUTO,function()
        if gpio.read(rele) == gpio.LOW  then
	        gpio.write(leds, gpio.HIGH);
        elseif gpio.read(rele) == gpio.HIGH then
        gpio.write(leds, gpio.LOW);
        end
end)

local function levantarEndUserSetup()

    print("entrando a levantarEndUserSetup..")

            if wifi.sta.getip() then
                print("Conectado a la red WiFi:", wifi.sta.getip())
            else
                print("No se pudo conectar a la red WiFi. Iniciando configuración Enduser Setup...")
                -- enduser_setup.manual(true)
                enduser_setup.start("LamparaConfig",
                    function()
                        print("Configuración de red WiFi completada. Conectado a la red:", wifi.sta.getip())
                        ChecarPuerto80()
                    end,
                    function(err, str)
                        print("Error durante la configuración:", str)
                    end
                )
           
            end
          
end

tmr.create():alarm(2800, tmr.ALARM_SINGLE, function()
levantarEndUserSetup();
end)


local function startServer()
    tmr.delay(tiempoDeRetraso)
    if (srv ~= nil) then
        srv:close();
    else
            srv=net.createServer(net.TCP, 1);
    end
    local srv = net.createServer(net.TCP)
    -- srv=net.createServer(net.TCP, 1);
   
    srv:listen(80,function(conn)

    conn:on("receive", function(client,request)
    local buf = "";
    local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
    if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
    end
    local _GET = {}
    if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                    _GET[k] = v;
            end
    end

    buf = [[
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>FOCO</title>
<script>
function load() {
let EstadoLampara = localStorage.getItem('Estado');
foco = document.getElementById('estadoDelFoco').textContent;
if (foco === "ON") {
document.getElementById("bOn").style.backgroundColor = "gray";
} else if (foco === "OFF") {
document.getElementById("bOff").style.backgroundColor = "gray";
}
}
window.onload = load;
function cON() {
localStorage.setItem('Estado', 'ON');
document.getElementById("bOn").style.backgroundColor = "gray";
document.getElementById("bOff").style.backgroundColor = "#1883ba";
}
function cOFF() {
localStorage.setItem('Estado', 'OFF');
document.getElementById("bOff").style.backgroundColor = "gray";
document.getElementById("bOn").style.backgroundColor = "#1883ba";
}
function capturarMinutos() {
minutos = document.forms["formMinutos"].elements[0].value;
window.location.href = "?pin=" + minutos;
}
</script>
<style type="text/css">
html, body {
height: 100%;
color: #1a2938;
text-shadow: 0px 0px 15px #ffffff;
margin: 0;
padding: 0;
background: linear-gradient(180deg, #778598, #385574);
background-size: cover;
}
.b {
text-decoration: none;
font-weight: 600;
font-size: 60px;
color: #ffffff;
background-color: #1883ba;
margin: 2px;
border-radius: 10px;
padding-top: 50px;
padding-bottom: 50px;
padding-left: 150px;
padding-right: 150px;
border: 4px solid #666c73;
width: 100%;
box-shadow: inset 0 4px 0 #ffffff33, 0 4px 4px #00000030;
}
.b:hover {
color: #a5bfcc;
border: 4px solid #0faeff;
background-color: #043c58;
}
.centrar {
width: 100%;
margin: 0 auto;
text-align: center;
justify-content: center;
align-items: center;
}
#sTime {
padding: 1%;
}
</style>
</head>
<body>
<div class="centrar">
<h1>Prender Lampara</h1>
<p>
<a href="?pin=ON"><button type="button" id="bOn" onclick="cON()" class="b centrar">ON</button></a><br>
<a href="?pin=OFF"><button type="button" id="bOff" onclick="cOFF()" class="b centrar">OFF</button></a><br>
<a href="?pin=BLOCK"><button class="b centrar">Bloquear</button></a><br>
<a href="?pin=UNBLOCK"><button class="b centrar">Desbloquear</button></a><br>
<a href="javascript: if (document.getElementById('sTime').style.display=='none'){ document.getElementById('sTime').style.display='block'; void(0)} else {document.getElementById('sTime').style.display='none'; void(0)}">
<button class="b centrar ">TIMER</button>
</a>
</p>
<form id="formMinutos">
<p id="sTime" class="centrar" style="display:none;"><br><br><input min="1" max="3000" type="number">minutos&nbsp;&nbsp;&nbsp;<input type="button" value="Enviar" onclick="capturarMinutos()"><br><br></p>
</form>]]

    local _on,_off = "",""
    local num = tonumber(_GET.pin)
    if(_GET.pin == "ON")then      
            print("On")
            estadoFoco = "ON";
            gpio.write(rele, gpio.HIGH);  
    elseif(_GET.pin == "OFF")then
        print("Off")
            estadoFoco = "OFF";
            gpio.write(rele, gpio.LOW);
    elseif(_GET.pin == "BLOCK")then
            button = "";
    elseif(_GET.pin == "UNBLOCK")then
            button = 5;
    elseif(num and num > 0 and num <3001 ) then
            local tiempo=num*1000*60;
            tmr.create():alarm(tiempo, tmr.ALARM_SINGLE, function()   
    
                    switch_rele();
            end) 
    end

    buf = buf..[[<h1><p>Foco:: <b id="estadoDelFoco">]].. estadoFoco ..[[</b></h1></p></div></body></html>]]


    client:send(buf);
    end)
    conn:on("sent", function(client)
            client:close();
        --     collectgarbage();
            end)
    end)

end

function ChecarPuerto80()
    print("Comprobando disponibilidad del puerto 80...")
    local wifi_sta_connected = false 
    local temporizador = tmr.create()
    local function checkEnduserServer()
      
        if wifi.sta.getip() ~= nil and wifi.sta.getip() ~= false and  wifi_sta_connected ~= false then
            print("El servidor enduser no está en ejecución. Iniciando tu propio servidor... ", wifi.sta.getip(),wifi_sta_connected)
            wifi_sta_connected = false
            startServer()
           
        end
        if wifi.ap.getip() then
            print("El servidor enduser está en ejecución. No iniciar tu propio servidor. ",wifi.ap.getip())
            wifi_sta_connected = true
        end

    end

    temporizador:alarm(6500, tmr.ALARM_AUTO, function()
        checkEnduserServer()
    end)
end




tmr.create():alarm(400, tmr.ALARM_SINGLE, function()
        print("Comenzando a escuchar boton o switch fisico...");
        dofile("button.lua");
end)