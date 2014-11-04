#include "TrickleC.h"
configuration TrickleAppC {}
implementation {

  components MainC, TrickleC as App;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC();
  components ActiveMessageC;
  components RandomC;

  App.Boot -> MainC.Boot;

  App.Receive       ->  AMReceiverC;
  App.AMSend        ->  AMSenderC;
  App.AMControl     ->  ActiveMessageC;
  App.IntervalTimer ->  TimerMilliC;
  App.TransmitTimer ->  TimerMilliC;
  App.Packet        ->  AMSenderC;
  App.Random        ->  RandomC;
}

