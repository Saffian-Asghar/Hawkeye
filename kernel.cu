#pragma once
#include "HawkCams.cuh"
#include "crow_all.h"  // Include Crow library

// Global pointer to Crow WebSocket server
crow::SimpleApp* ws_server;

// WebSocket route handler function to broadcast image frames
void handleWebSocketImageFrame(const crow::websocket::connection& conn, const std::string& data) {
    // Broadcast the received image frame to all connected clients
    // Here, you need to implement logic to broadcast 'data' to all connected clients
    // Example: You might send the image data received from 'data' to all connected clients
    // Hint: Use ws_server->broadcast_binary(data) to broadcast data to all clients
}

void working_code() {
    const short int camsCount = 3;
    string paths[camsCount] = { "videos\\v1.mp4",  "videos\\v2.mp4",  "videos\\v3.mp4"};
    HawkCam cams(paths, camsCount);
    cams.loadStreams();
    cams.setupStreams();
    cams.loop();
    cams.finalize();
}

int main() {
    // Start the WebSocket server
    crow::SimpleApp app;
    ws_server = &app;

    // Define WebSocket route to handle image frame messages
    CROW_ROUTE(app, "/image_frame")
        .websocket()
        .onmessage(handleWebSocketImageFrame);

    // Start the server on port 8080
    app.port(8080).multithreaded().run();

    // Start the main functionality of your project
    working_code();

    return 0;
}
