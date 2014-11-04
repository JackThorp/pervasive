#include "DisseminateC.h"
configuration DisseminateAppC {}
implementation {

  components MainC, DisseminateC as App;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC();
  components ActiveMessageC;
  components RandomC;

  App.Boot -> MainC.Boot;

  App.Receive     ->  AMReceiverC;
  App.AMSend      ->  AMSenderC;
  App.AMControl   ->  ActiveMessageC;
  App.MilliTimer  ->  TimerMilliC;
  App.Packet      ->  AMSenderC;
  App.Random      ->  RandomC;
}


