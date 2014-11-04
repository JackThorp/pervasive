#ifndef SEND_MESSAGE_H 
#define SEND_MESSAGE_H

typedef nx_struct radio_count_msg {
  nx_uint16_t counter;
  nx_uint16_t sender_id;
} radio_count_msg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif
