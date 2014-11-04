#include "Timer.h"
#include "DisseminateC.h"
#include "initial.h"

module DisseminateC @safe() {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
    interface Random;
  }
}
implementation {

  message_t packet;
  uint32_t back_off = 100;
  uint8_t trans_count = 0;
  uint8_t trans_limit = 3;
  radio_count_msg_t known_msg;

  
  bool locked;
  uint16_t counter = 0;

  uint32_t getTimeOut() {
    uint16_t rand_16 = call Random.rand16();
    double my_rand = (rand_16 / pow(2,16));
    return (uint32_t)((back_off/2) + ((back_off/2)*my_rand));
  }

  event void Boot.booted() {
    dbg("Boot", "Application booted.\n");
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      if (TOS_NODE_ID == INITIAL_NODE) {
        call MilliTimer.startOneShot(getTimeOut());
        known_msg.msg_data = TOS_NODE_ID;
      }
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }

  event void MilliTimer.fired() {

    if (trans_count < trans_limit) {
     
      // Return if sender is already in use, don't try send again ??? 
      if (locked) {
        return;
      }
      else {
        // Extract appropriate section of packet for us to fill with payload.
        radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t)); 
        
        // If message is null (there was no packet?) 
        if (rcm == NULL) {
          return;
        }
        
        // Set value of packet contents (rcm points to packet payload). 
        rcm->msg_data = known_msg.msg_data;

        // Try to send packet, lock AMSender until successful transmission. 
        if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
          dbg("DisseminateC", "%s SND %i\n", sim_time_string(), TOS_NODE_ID);
          locked = TRUE;
        }
        
        back_off = back_off*10;
        call MilliTimer.startOneShot(getTimeOut());
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
   
    if (len != sizeof(radio_count_msg_t)) {
      
      return bufPtr;
    }
    else {
      radio_count_msg_t* rcm = (radio_count_msg_t*)payload;
      dbg("DisseminateC", "%s RCV %i %i\n", sim_time_string(), TOS_NODE_ID, rcm->msg_data);
      
      known_msg.msg_data = rcm->msg_data;
      if (trans_count == 0 ) {
        call MilliTimer.startOneShot(getTimeOut());
      }
      return bufPtr;
    }

  }
  
  
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
      trans_count++;
    }
  }
}

