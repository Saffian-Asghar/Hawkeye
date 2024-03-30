#pragma once
#include "HawkCams.cuh"

void working_code() {
    const short int camsCount = 3;
    string paths[camsCount] = { "videos\\v1.mp4",  "videos\\v2.mp4",  "videos\\v3.mp4"};
    /*const short int camsCount = 1;
    string paths[camsCount] = { "videos\\c4.mp4"};*/
    HawkCam cams(paths, camsCount);
    cams.loadStreams();
    cams.setupStreams();
    cams.loop();
    cams.finalize();
}

int main() {

    working_code();

    return 0;
}