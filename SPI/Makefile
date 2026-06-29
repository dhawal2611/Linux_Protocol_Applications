CC      := gcc
TARGET  := dspiAHT20

SRCS    := dspi.c \
           dspiAHT20.c

OBJS    := $(SRCS:.c=.o)
CFLAGS  := -Wall -Wextra -O2

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

rebuild: clean all

.PHONY: all clean rebuild
