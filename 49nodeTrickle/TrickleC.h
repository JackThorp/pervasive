#ifndef TRICKLE_H 
#define TRICKLE_H

typedef nx_struct radio_count_msg {
  nx_uint16_t msg_data;
  nx_uint16_t version;
} radio_count_msg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif
