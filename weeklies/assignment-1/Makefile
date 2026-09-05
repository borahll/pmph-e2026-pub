NVCC = nvcc
TARGET = wa1-task3
SRC = wa1-task3.cu

all: $(TARGET)

$(TARGET): $(SRC)
	$(NVCC) -O3 -o $(TARGET) $(SRC)

clean:
	rm -f $(TARGET)