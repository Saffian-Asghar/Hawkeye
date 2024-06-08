#pragma once
#include "HawkCam.cuh"
#include <websocketpp/config/asio_no_tls.hpp>
#include <websocketpp/server.hpp>

typedef websocketpp::server<websocketpp::config::asio> server;

void on_open(websocketpp::connection_hdl hdl) {
    connections.insert(hdl);
}

void on_close(websocketpp::connection_hdl hdl) {
    connections.erase(hdl);
}

int main() {
    server s;

    s.set_open_handler(&on_open);
    s.set_close_handler(&on_close);

    s.init_asio();
    s.listen(5892);
    s.start_accept();

    const short int camsCount = 3;
    string paths[camsCount] = { "videos\\v1.mp4",  "videos\\v2.mp4",  "videos\\v3.mp4"};
    HawkCam cams(paths, camsCount);
    cams.loadStreams();
    cams.setupStreams();
    cams.loop();
    cams.finalize();

    s.run();
}