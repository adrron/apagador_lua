function amortigua(func)
  
        local antes = 0
        local espera = 60000
        return function(nivel, ahora)
        local delta = ahora - antes
  
        if delta < 0 then delta = delta + 2147483647 end;
  
        if delta < espera then return end
  
        	antes = ahora
        	return func(nivel,ahora)
	end

end

function si_cambia(nivel, tiempo)

        print("Entrando Trigger")
        print(gpio.read(rele))

        if gpio.read(button) == gpio.HIGH and gpio.read(rele) == gpio.HIGH  then 
                print("Apagare RELE")       
                gpio.write(rele, gpio.LOW);
                estadoFoco = "OFF";
        elseif gpio.read(button) == gpio.LOW and gpio.read(rele) == gpio.LOW   then 
                print("Prendere RELE")
                gpio.write(rele, gpio.HIGH);
                estadoFoco = "ON";
        elseif gpio.read(button) == gpio.HIGH and gpio.read(rele) == gpio.LOW   then 
                print("Prendere RELE")
                gpio.write(rele, gpio.HIGH);
                estadoFoco = "ON";
        elseif gpio.read(button) == gpio.LOW and gpio.read(rele) == gpio.HIGH   then 
                print("Apagare RELE")
                gpio.write(rele, gpio.LOW);
                estadoFoco = "OFF";

        end

        print(gpio.read(rele))

end

gpio.trig(button,"both", amortigua(si_cambia))

