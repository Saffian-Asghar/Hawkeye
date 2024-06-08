#pragma once
#include "PersonDetectionModule.cuh"
#include "crow_all.h"  // Include Crow library

class CamHandler {
public:
	map<int, map<uchar, int>> greyColorVals;
	crow::SimpleApp* ws_server;  // Pointer to Crow WebSocket server

	CamHandler(std::string path, int id, crow::SimpleApp* server) : _id(id), ws_server(server) {
        vid = cv::VideoCapture(path);
        std::cout << "Loading Stream " << id << endl;
        imgCount = 0;
    }
	bool load() {
		return vid.isOpened();
	}
	void setup() {
		vid.read(img);
		segment = PersonDetection(_id);
		segment.showDetectedPerson(false);
		segment.prepare(img);
	}
	void preloop() {
		for (int i = 0; i < 100; i++) {
				vid.read(img);
				segment.learning(img);
		}
	}
	bool loop() {
        if (segment.shouldEnd())
            return true;
        vid.read(img);
        if (segment.learning(img)) {
            if (imgCount++ >= 1000) {
                segment.extraction(greyColorVals, true);
                imgCount = 0;
            }
            else
                segment.extraction(greyColorVals, false);
            
            string str = "mask";
            str += _id;
            string str1 = "segment";
            str1 += _id;
            imshow(str, segment.getMaskFrame());
            imshow(str1, segment.getOrignalFrame());
            waitKey(10);

            // Broadcast the image frame to all connected clients
            cv::Mat frame = segment.getOrignalFrame(); // or segment.getMaskFrame() depending on your requirement
            std::vector<uchar> buffer;
            cv::imencode(".jpg", frame, buffer);
            std::string imageData(buffer.begin(), buffer.end());
            ws_server->broadcast_binary(imageData);
        }
        return false;
    }
	void destroy() {
		segment.finilize();
		vid.release();
	}
private:
    int _id;
    cv::VideoCapture vid;
    cv::Mat img;
    PersonDetection segment;
    short int imgCount;
};

