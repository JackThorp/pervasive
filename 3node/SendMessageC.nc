#include "Timer.h"
#include "SendMessageC.h"

module SendMessageC @safe() {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  message_t packet;
  
  bool locked;
  uint16_t counter = 0;

  event void Boot.booted() {
    dbg("Boot", "Application booted.\n");
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call MilliTimer.startPeriodic(250);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }

  event void MilliTimer.fired() {

    if (TOS_NODE_ID == 1) {

      counter++;
      dbg("SendMessageC", "SendMessageC: timer fired, counter is %hu.\n", counter);
     
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
        rcm->counter = counter;
        rcm->sender_id = TOS_NODE_ID;

        // Try to send packet, lock AMSender until successful transmission. 
        if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
          dbg("SendMessageC", "SendMessageC: packet sent.\n", counter);
          locked = TRUE;
        }
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
   
    dbg("SendMessageC", "received a packet.\n");
    if (len != sizeof(radio_count_msg_t)) {
      
      return bufPtr;
    }
    else {
      radio_count_msg_t* rcm = (radio_count_msg_t*)payload;
     
      dbg("SendMessageC", "This is %u receieving packet %hu from %u.\n", TOS_NODE_ID, rcm->counter, rcm->sender_id);
      return bufPtr;
    }

  }
  
  
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }
}

