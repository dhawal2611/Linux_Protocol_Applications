CC      ?= gcc
TARGET  := dspiw25qxx

SRCS    := dspi.c 
           #dspiw25qxx.c

OBJS    := $(SRCS:.c=.o)
CFLAGS  ?= -Wall -Wextra -O2 -fcommon

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

rebuild: clean all

.PHONY: all clean rebuild

