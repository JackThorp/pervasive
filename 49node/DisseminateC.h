#ifndef DISSEMINATE_H 
#define DISSEMINATE_H

typedef nx_struct radio_count_msg {
  nx_uint16_t msg_data;
} radio_count_msg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif
