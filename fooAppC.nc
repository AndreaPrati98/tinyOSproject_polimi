 
#include "foo.h"
#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration fooAppC {}

implementation {
  components MainC, fooC as App, LedsC;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC();
  components ActiveMessageC;
  components PrintfC;
  components SerialStartC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.Timer -> TimerMilliC;
  App.Packet -> AMSenderC;
}


