# Define the compiler and compiler flags
CC = gcc
CFLAGS = -Wall -Wextra -O2

# Automatically grab all .c files in the current directory
SRCS = $(wildcard *.c)

# Transform the list of .c files into .o (object) files
OBJS = $(SRCS:.c=.o)

# Define the final executable name
TARGET = duart_rw

# Default rule: builds the target executable
all: $(TARGET)

# Rule to link object files into the final executable
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

# Rule to compile .c files to .o files (Implicit rule handles this, 
# but writing it explicitly clarifies the process)
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean rule to wipe out built binaries and object files
clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean

