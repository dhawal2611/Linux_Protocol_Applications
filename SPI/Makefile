CC      ?= gcc
TARGET  := dspi

SRCS    := dspi.c \
           dspiw25qxx.c

OBJS    := $(SRCS:.c=.o)
CFLAGS  ?= -Wall -Wextra -O2

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

rebuild: clean all

.PHONY: all clean rebuild

