#pragma once
#include "PersonDetectionModule.cuh"

class CamHandler {
public:
	map<int, map<uchar, int>> greyColorVals;

	CamHandler(std::string path, int id) :_id(id){
		vid = cv::VideoCapture(path);
		std::cout << "Loading Stream " << id << endl;
		imgCount = 0;
	}
	void send_frame(Mat frame) {
		std::vector<uchar> buf;
		imencode(".jpg", frame, buf);
		std::string frame_str(buf.begin(), buf.end());

        for (auto it : connections) {
            s.send(it, frame_str, websocketpp::frame::opcode::binary);
        }
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
			send_frame(segment.getMaskFrame());
			waitKey(10);
		}
		return false;
	}
	void destroy() {
		segment.finilize();
		vid.release();
	}
private:
	int _id;
	VideoCapture vid;
	Mat img;
	PersonDetection segment;
	short int imgCount;
};

