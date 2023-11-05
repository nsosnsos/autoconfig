#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

int main() {
    int busyTime = 0.1;
    int idleTime = 0.1;
    while (1) {
        clock_t startTime = clock();
        while ((clock() - startTime) <= busyTime * CLOCKS_PER_SEC);
        sleep(idleTime);
    }
    return 0;
}

