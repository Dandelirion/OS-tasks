#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        perror("Invalid number of arguments! The program should have only one argument - name of output file");
        return 1;
    }

    int outputFileDescriptor = open(argv[1], O_CREAT | O_WRONLY | O_TRUNC, 00744);

    if (outputFileDescriptor < 0) {
        perror("Couldn't open output file...");
        return 1;
    }

    int BYTES_TO_READ = 2048;
    char buffer[BYTES_TO_READ];

    char* startOfChain;
    int chainSize = 0;
    bool isNotZeros;

    int countRead = read(STDIN_FILENO, buffer, BYTES_TO_READ);

    if (countRead < 0) {
        perror("Error occurred while reading input...");
        return 1;
    }

    while (countRead != 0)
    {
        startOfChain = buffer;
        chainSize = 0;
        isNotZeros = (bool) *startOfChain;

        for (char *pointer = buffer; pointer < buffer + countRead; pointer++) {
            if ((bool) *pointer != isNotZeros) {
                if (isNotZeros) write(outputFileDescriptor, startOfChain, chainSize);
                else {
                    startOfChain = pointer;
                    lseek(outputFileDescriptor, chainSize, SEEK_CUR);
                }
                chainSize = 0;
                isNotZeros = !isNotZeros;
            }

            chainSize++;
        }

        if (chainSize != 0) {
            if (isNotZeros) write(outputFileDescriptor, startOfChain, chainSize);
            else lseek(outputFileDescriptor, chainSize, SEEK_CUR);
        }

        countRead = read(STDIN_FILENO, buffer, BYTES_TO_READ);
    }

    return 0;
}
