#pragma once
# include <iostream>
# include <String>
#include <vector>

#include "opencv2/opencv.hpp"

#include "Defines.cuh"

using namespace std;
using namespace cv;


class Basics {
public:
	static void convertGrey(Mat& src, Mat& dst) {
		Mat grey(src.size(), CV_8UC1);
		int rows = 0;
		Vec3b pixel;
		for(int i=0;i<src.rows-1;i++){
			for (int j = 0; j < src.cols; j++) {
				pixel = src.at<Vec3b>(i, j);
				grey.at<uchar>(i, j) = (uchar)get_grey(pixel[2], pixel[1], pixel[0]);
			}
		}

		//dst = grey.clone();

	}
	bool checkDiffrence(Mat& src, Mat& dst) {
		return checkDiffrence(src, dst, dst);
	}
	bool checkDiffrence(Mat& src1, Mat& src2, Mat& dst) {
		if (src1.empty())
			return false;
		if (src2.empty()) {
			src2 = cv::Mat::zeros(src1.size(), CV_8UC1);
		}
		if (dst.empty()) {
			dst = cv::Mat::zeros(src1.size(), CV_8UC1);
		}
		absdiff(src1, src2, dst);
		return true;
	}
	void removeNoise(Mat& img, int lvl) {
		threshold(img, img, lvl, 255, cv::THRESH_BINARY);
	}
	void findContours(Mat img, vector<vector<Point>>& contours) {
		cv::findContours(img, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_TC89_KCOS);
	}
};
