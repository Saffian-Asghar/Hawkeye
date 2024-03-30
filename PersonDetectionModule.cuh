#pragma once
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "opencv2/opencv.hpp"
#include<cmath>
#include "Defines.cuh"
#include "Structs.cuh"
#include "Base.h"
//#include "CSegmentation2.cuh"
//#include "DatabaseModule.h"

#include <iostream>
#include <stdio.h>
#include <cstdlib>
#include <unordered_map>
#include <vector>
#include <chrono>


using namespace cv;
using namespace std;
using namespace chrono;

class PersonDetection {
public:
	PersonDetection(int camId=-1);
	bool shouldEnd();
	bool prepare(const Mat&);
	bool learning(const Mat&);
	void extraction(map<int, map<uchar, int>> &greyColorVals, bool saveImg);

	
	void showDetectedPerson(bool _s);
	Mat getOrignalFrame();
	Mat getMaskFrame();
	void finilize();

protected:
	cv::Point2f centroidWeightedSum(const std::deque<cv::Point2f>& values, size_t index);
	void PersonDetection::calculateCentrod(cv::Point2f savedCentrod, const cv::Point2f newCentroid, Person& person, bool calcDiff);
	Person getPerson(Mat& frame, Mat& gFrame, cv::Rect boundingRect, map<int, map<uchar, int>>& greyColorVals);
	float calculateCentroidDistance(const cv::Point2f& centroid1, const cv::Point2f& centroid2);
	void save(const cv::Mat& personImage, int id);
	void log(Person p, bool saveImg, Rect boundingRect);
private:
	int _blvl;
	int rows, cols, channels;

	unsigned char* _c_arr;	// current image frame in GPU			3D
	unsigned char* _m_arr;	//   model image frame in GPU			1D
	unsigned char* _m_arr1;	//   model image frame in GPU			1D
	unsigned char* _r_arr;	//    mask image frame in GPU			1D

	Mat _r_frame,_c_frame, _p_frame;

	size_t _1d_img, _3d_img;
	cudaError_t cudaStatus = cudaSuccess;
	
	
	int camId;
	bool _show = false;
	Basics basics;

	int personId = 0;
	std::unordered_map<int, pair<Person, bool>> persons;
	bool percentCompare(float n, float d);
	int compare(std::map<uchar, int> currGreyColorVals, map<int, map<uchar, int>> greyColorVals);
	double compareBlocks(vector<double> block1Features, vector<double> block2Features);
	void printloc(Location l, bool saveImg, Rect boundingRect);
	int img_no;
	float total, pos, percent, bestMatchValue;
	int matchId;
};
