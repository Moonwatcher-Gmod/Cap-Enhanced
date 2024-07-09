# Created by AlexALX (c) 2011
# For addon Stargate Carter Addon Pack
# http://sg-carterpack.com/
@name stargate fast-slow dial
@inputs Stargate:wirelink Address:string Start
@persist Address:string Stop Dialling
@trigger
if (!Address) {
    Address = "SPAWN0#"
}
interval(10)
Stargate["Ring Speed Mode",number] = 10
Stargate["Chevron Encode",number] = 0
Stargate["Chevron 7 Lock",number] = 0
I = Stargate["Chevron",number]+1
if (Start == 1) {
    Dialling = 1
    if (clk("delay")) {
        Stargate["Chevron Encode",number] = 1
        timer("delay2", 2600)
    }
    if (clk("delay2")) {
        Stop = 0
    }
    if (clk("delay3")) {
        Stargate["Chevron 7 Lock",number] = 1
    }
    if (Stop == 0) {
        Stargate["Rotate Ring",number] = 1
    }
    if (I < Address:length() & Stargate["Ring Symbol",string] == Address[I] && Stop == 0) {
        Stargate["Rotate Ring",number] = 0
        Stop = 1
        timer("delay", 50)
    } elseif (I == Address:length() & Stargate["Ring Symbol",string] == Address[I] && Stop == 0) {
        Stargate["Rotate Ring",number] = 0
        Stop = 1
        timer("delay3", 50)
    }
} elseif (!Start) {
    if (Stargate["Active",number] & Dialling) {
        Close = 1
    }
    Stargate["Rotate Ring",number] = 0
    Stop = 0
    Dialling = 0
    timer("close", 1000)
    if (clk("close")) {
        Stargate["Close",number] = 0
    }
}
