# Define the compiler and compiler flags
CC = gcc
CFLAGS = -Wall -Wextra -O2 -pthread -Wno-unused-parameter
# Added -pthread for linking the POSIX threads library
LDFLAGS = -pthread

# Automatically grab all .c files in the current directory
SRCS = $(wildcard *.c)

# Transform the list of .c files into .o (object) files
OBJS = $(SRCS:.c=.o)

# Define the final executable name
TARGET = dcan

# Default rule: builds the target executable
all: $(TARGET)

# Rule to link object files into the final executable
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

# Rule to compile .c files to .o files (Implicit rule handles this, 
# but writing it explicitly clarifies the process)
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean rule to wipe out built binaries and object files
clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean

