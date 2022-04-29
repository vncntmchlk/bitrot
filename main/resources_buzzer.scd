
~redBuzzer = ();
~redBuzzer.lastValue = -1;
~redBuzzer.port = SerialPort(
	"/dev/ttyUSB0",    //edit to match your port. SerialPort.listDevices
    baudrate: 9600,    //check that baudrate is the same as in arduino sketch
    crtscts: true
);

~redBuzzer.pressFunc = ~buzzerStuff[\nukePressFunction];
~redBuzzer.readValues = Routine({
    var byte, str, res;
    inf.do{|i|
        if(~redBuzzer.port.read==10, {
            str = "";
            while({byte = ~redBuzzer.port.read; byte !=13 }, {
                str= str++byte.asAscii;
            });
            res= str.asInteger;
			if(~redBuzzer.lastValue != res and: {res==0}){ ~redBuzzer.pressFunc.value };
			~redBuzzer.lastValue = res;
        });
    };
});

~redBuzzer.readValues.play;



// ~redBuzzer.readValues.stop;
// ~redBuzzer.port.close;