# TARGET = main

# all: $(TARGET)

# $(TARGET): main.o
# 	gcc main.o -no-pie -lm -o $(TARGET)

# main.o: main.asm
# 	nasm -f elf64 main.asm -o main.o

# clean:
# 	rm -f *.o $(TARGET)
TARGET = main

all: $(TARGET)

$(TARGET): $(TARGET).o
	gcc $(TARGET).o -no-pie -lm -o prog

$(TARGET).o: $(TARGET).asm
	nasm -f elf64 -g -F dwarf $(TARGET).asm -o $(TARGET).o

clean:
	rm -f $(TARGET).o $(TARGET) prog