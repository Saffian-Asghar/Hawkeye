#pragma once
#include "opencv2/opencv.hpp"
#include<vector>
struct Person {
	int id;
	int CamId;
	cv::Rect boundingRect;
	cv::Point2f centroid;
	std::deque<cv::Point2f> positions;
	std::map<float, float > meanDiffpos;
};

struct PersonDCT {
	int id;
	std::vector<double> dct;
};

struct Location {
	float locX, locY;			// location
	int pid;		       // person id
	int camId;				// camera Id
	time_t time;			// sec time
};
