#include "Timer.h"
#include "TrickleC.h"
#include "initial.h"

module TrickleC @safe() {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as IntervalTimer;
    interface Timer<TMilli> as TransmitTimer;
    interface SplitControl as AMControl;
    interface Packet;
    interface Random;
  }
}
implementation {

  message_t packet;
  uint16_t  counter       = 0;
  uint32_t  Imin          = 500; 
  uint8_t   Imax          = 16;
  uint32_t  time_out      = 0;
  uint32_t  cur_interval  = 500;
  uint8_t   REDUNDANCY    = 2;
  
  radio_count_msg_t known_msg;
  //known_msg.msg_data = 0;
  //known_msg.version = 0;

  bool locked;
  
  uint32_t getNewTimeOut() {
    uint16_t rand_16 = call Random.rand32();
    double my_rand = (rand_16 / pow(2,16));
    return (uint32_t)((cur_interval/2) + ((cur_interval/2) * my_rand));
  }

  event void Boot.booted() {
    dbg("Boot", "Application booted.\n");
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      known_msg.version = 0;
      known_msg.msg_data = 0;

      time_out = getNewTimeOut();
      if ( TOS_NODE_ID == INITIAL_NODE) {
        known_msg.version = 1;
        known_msg.msg_data = TOS_NODE_ID;
      }

      dbg("TrickleC", "timeout value is %u \n", time_out);
      call TransmitTimer.startOneShot(time_out);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }

  event void TransmitTimer.fired() {

    // Don't send if havn't yet recieved first version. 
    if (locked || known_msg.version == 0 ) {
      return;
    }
    else if (counter < REDUNDANCY) {
      
  
      // Extract appropriate section of packet for us to fill with payload.
      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t)); 
      
      // dbg("TrickleC", "known_version for %hu = %hu \n", TOS_NODE_ID, known_msg.version);

      // If message is null (there was no packet?) 
      if (rcm == NULL) {
        return;
      }
      
      // Set value of packet contents (rcm points to packet payload). 
      rcm->msg_data = known_msg.msg_data;
      rcm->version  = known_msg.version;

      // Try to send packet, lock AMSender until successful transmission. 
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
        dbg("TrickleC", "%s SND %i\n", sim_time_string(), TOS_NODE_ID);
        locked = TRUE;
      }
    }
  }
  

  event void IntervalTimer.fired() {
    // If interval expires then new interval = min (2*I, Imax)
    cur_interval = cur_interval*2;
    if( cur_interval > (Imax^2 * Imin)) {
      cur_interval = Imax;
    }
    time_out = getNewTimeOut();
    call IntervalTimer.startOneShot(cur_interval);
    call TransmitTimer.startOneShot(time_out);
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
   
    if (len != sizeof(radio_count_msg_t)) {
      
      return bufPtr;
    }
    else {
      radio_count_msg_t* rcm = (radio_count_msg_t*)payload;
      dbg("TrickleC", "%s RCV %i %i\n", sim_time_string(), TOS_NODE_ID, rcm->msg_data);
      // dbg("TrickleC", "RCV %i MSG %i VERS %i \n", TOS_NODE_ID, rcm->msg_data, rcm->version);
      // dbg("TrickleC", "NODE %i KVERS %i \n", TOS_NODE_ID, known_msg.version) ;

      // If trickle data (rcm->sender) is inconsistent with seen data. 
      if (known_msg.version != rcm->version && cur_interval != Imin) {
        if (known_msg.version < rcm->version) {
          known_msg.version = rcm->version;
          known_msg.msg_data = rcm->msg_data;
        }
        counter = 0;
        cur_interval = Imin;
        time_out = getNewTimeOut();
        call TransmitTimer.startOneShot(time_out);
        call IntervalTimer.startOneShot(cur_interval);
      } 
      // If data is consistent.
      else if (known_msg.version == rcm->version) {
        counter++;
      }
      return bufPtr;
    }

  }
  
  
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }
}

