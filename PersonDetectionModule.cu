#include "PersonDetectionModule.cuh"
#include <fstream>
#include<time.h>
#include <stdlib.h>

__global__ void cuda_masking(unsigned char* cimg, unsigned char* modelImg, unsigned char* modelImg1, unsigned char* retimg, int rows, int cols, int channels, int blvl) {
	int x = getIndex(blockIdx.x, blockDim.x, threadIdx.x);
	int y = getIndex(blockIdx.y, blockDim.y, threadIdx.y);
	if (x >= rows || y >= cols || channels < 3)
		return;
	int point = pixelI(x, y, cols, 1);  // index of a pixel
	int index = point * channels;  // index of a pixel

	// grey
	double grey = get_grey(cimg[index + 0], cimg[index + 1], cimg[index + 2]); // pixel value


	// model update

	modelImg[point] = (unsigned char)(modelImg[point] * 0.85 + grey * 0.15);

	// diff
	double diff = abs((int)modelImg1[point] - grey);
	
	modelImg1[point] = (unsigned char)(modelImg1[point] * 0.15 + modelImg[point] * 0.85);

	//threshould 

	// balck and white
	retimg[point] = (unsigned char)(diff < blvl) ? 0 : 255;
	// grey scale
	retimg[point] = (unsigned char)(diff < blvl) ? 0 : grey;
}

PersonDetection::PersonDetection(int cid) : _blvl(25),camId(cid), rows(0), cols(0), channels(0) {//large
//PersonDetection::PersonDetection(int cid) : _blvl(18),camId(cid), rows(0), cols(0), channels(0) {//small
	cudaStatus = cudaSetDevice(0);
	img_no = 0;
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
		return;
	}
}
bool PersonDetection::shouldEnd() {
	return cudaStatus != cudaSuccess; 
}
bool PersonDetection::prepare(const Mat& img) {
	rows = img.rows;
	cols = img.cols;
	channels = img.channels();

	_1d_img = rows * cols * sizeof(unsigned char);
	_3d_img = _1d_img * channels;


	cudaStatus = cudaMalloc<unsigned char>(&_c_arr, _3d_img);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "prepare() cudaMalloc() _c_arr failed!");
		return false;
	}
	cudaStatus = cudaMalloc<unsigned char>(&_m_arr, _1d_img);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "prepare() cudaMalloc() _m_arr failed!");
		return false;
	}
	cudaStatus = cudaMalloc<unsigned char>(&_m_arr1, _1d_img);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "prepare() cudaMalloc() _m_arr1 failed!");
		return false;
	}
	cudaStatus = cudaMalloc<unsigned char>(&_r_arr, _1d_img);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "prepare() cudaMalloc() _r_arr failed!");
		return false;
	}

	_r_frame = Mat::zeros(img.size(), 0);

	cudaStatus = cudaMemcpy(_m_arr, _r_frame.ptr(), _1d_img, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "prepare() cudaMemcpy _m_arr cudaMemcpyHostToDevice failed!");
		return false;
	}cudaStatus = cudaMemcpy(_m_arr1, _r_frame.ptr(), _1d_img, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "prepare() cudaMemcpy _m_arr1 cudaMemcpyHostToDevice failed!");
		return false;
	}
	cudaStatus = cudaMemcpy(_r_arr, _r_frame.ptr(), _1d_img, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "prepare() cudaMemcpy _r_arr cudaMemcpyHostToDevice failed!");
		return false;
	}
	return true;
}
bool PersonDetection::learning(const Mat&img) {
	_c_frame = img.clone();
	cudaStatus = cudaMemcpy(_c_arr, img.ptr(), _3d_img, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "learning() cudaMemcpy _c_arr cudaMemcpyHostToDevice failed!");
		return false;
	}
	dim3 blockDim(1, 1);
	dim3 gridDim(rows, cols);

	cuda_masking<<<gridDim, blockDim >>>(_c_arr, _m_arr, _m_arr1, _r_arr, rows, cols, channels, _blvl);

	cudaStatus = cudaMemcpy(_r_frame.data, _r_arr, _1d_img, cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "learning() cudaMemcpy _r_frame cudaMemcpyHostToDevice failed!");
		return false;
	}

	return true;
}

//void PersonDetection::deleteUnwantedPerson() {
//	for (auto& pair : persons) {
//		if (pair.second.second == false)
//			persons.erase(pair.first);
//	}
//	for (auto& pair : persons) {
//		pair.second.second = false;
//	}
//}

void PersonDetection::extraction(map<int, map<uchar, int>> &greyColorVals, bool saveImg){
	
	// _r_frame is segmented/ foreground frame
	//imshow("mask", _r_frame);
	// waiting for background learning


	vector<std::vector<cv::Point>> contours;
	basics.findContours(_r_frame, contours);

	//iou slow
	cv::Rect boundingRectB;
	Rect interect, union_;
	double iou = 0.f;
	//double coutourArea = 200;//small
	double coutourArea = 20000;//large

	// Process each contour to detect and track persons
	for (const auto& contour : contours) {
		double area = cv::contourArea(contour);
		cv::Rect boundingRect = cv::boundingRect(contour);

		if (area > coutourArea) {
			
			Person person = getPerson(_c_frame, _r_frame, boundingRect, greyColorVals);
			Mat personImage = _c_frame(person.boundingRect).clone();
			
			save(personImage, person.id);
			log(person, true, person.boundingRect);

			// Draw bounding box with person ID on the frame
			cv::rectangle(_c_frame, person.boundingRect, cv::Scalar(0, 255, 0), 2);
			cv::putText(_c_frame, std::to_string(person.id), cv::Point(person.boundingRect.x, person.boundingRect.y - 10), cv::FONT_HERSHEY_SIMPLEX, 0.9, cv::Scalar(0, 255, 0), 2);

		}
	}
	//deleteUnwantedPerson();
}

Mat PersonDetection::getOrignalFrame() { return _c_frame; }
Mat PersonDetection::getMaskFrame() { return _r_frame; }

void PersonDetection::printloc(Location l, bool saveImg, Rect boundingRect) {
	char* time = strtok(ctime(&(l.time)), "\n");

	fprintf(stderr, "CamId: %d, PId: %d, Time: %s, loc.x: %f,  loc.y %f \n", l.camId, l.pid, time, l.locX, l.locY);

	string filePath = "objects\\" + to_string(l.pid) + "\\";

	system(("if not exist \"" + filePath + "\" mkdir " + filePath).c_str());

	fstream objectFile;
	objectFile.open(filePath + "path.csv", ios::out | ios::app);
	objectFile << l.camId << "," << l.pid << "," << time << "," << l.locX << "," << l.locX << "\n";
	objectFile.close();

	if (saveImg) {
		Mat img;
		resize(_c_frame(boundingRect), img, Size(200, 200), 0, 0);
		imwrite(filePath + "a.jpg", img);
	}
}

void PersonDetection::save(const Mat& personImage, int id) {
	// Placeholder function to save person image and ID to a database
	// Implement the logic to save the image and ID to your specific database
	if (_show) {
		string str = "ID: ";
		str += (id);
		cv::imshow(str, personImage);
	}
}
void PersonDetection::log(Person p, bool saveImg, Rect boundingRect) {
	Location loc;
	loc.pid = p.id;
	loc.camId = camId;
	loc.locX = p.centroid.x;
	loc.locY = p.centroid.y;
	loc.time = time(NULL);
	printloc(loc, saveImg, boundingRect);
	string str = "x:";
	str += loc.locX;
	str += " y: ";
	str += loc.locY;
	str += " cam: ";
	str += loc.camId;
	str += " pid";
	str += loc.pid;

	//int a = rand();
	//db.updateData(loc);
}
void PersonDetection::showDetectedPerson(bool _s) {
	_show = _s;
}

void PersonDetection::finilize() {
	if (shouldEnd())
		cout << cudaGetErrorString(cudaStatus) << endl;

	cudaStatus = cudaDeviceReset();

}

float PersonDetection::calculateCentroidDistance(const cv::Point2f& centroid1, const cv::Point2f& centroid2) {
	float x = (centroid1.x - centroid2.x);
	float y = (centroid1.y - centroid2.y);

	return sqrt(pow(x, 2.0f) + pow(y, 2.0f));
}

// Function to compare two blocks using Euclidean distance
double PersonDetection::compareBlocks(vector<double> block1Features, vector<double> block2Features) {
	double distance = 0.0;
	for (size_t i = 0; i < block1Features.size(); i++) {
		double diff = block1Features[i] - block2Features[i];
		distance += diff * diff;
	}
	return sqrt(distance);
}

std::map<uchar, int> getColorsCount(cv::Mat dimage) {
	cv::resize(dimage, dimage, cv::Size(80, 80));
	uchar temp = -1;
	//dct(dimage, dimage);
	std::map<uchar, int> chars;
	for (int i = 0; i < dimage.rows; i++)
		for (int j = 0; j < dimage.cols; j++) {
			temp = dimage.at<uchar>(i, j);
			if (temp != 0 && chars.find(temp) != chars.end())
				chars[temp]++;
			else
				chars.insert(std::pair<uchar, int>(temp, 1));
		}
	return chars;
}



bool PersonDetection::percentCompare(float n, float d) {
	if ((n / d) * 100.f > 60.f)
		return true;
	else
		return false;
}

int PersonDetection::compare(map<uchar, int> currGreyColorVals, map<int, map<uchar, int>> greyColorVals) {
	bestMatchValue = 0;
	matchId = -1;
	for (auto i : greyColorVals) {
		total = pos = percent = 0;

		for (auto e : currGreyColorVals) {
			total++;
			if (e.second > i.second[e.first])
				if (percentCompare(i.second[e.first], e.second))
					pos++;
				else if (percentCompare(e.second, i.second[e.first]))
					pos++;
		}

		percent = (pos / total) * 100.f;
		if (percent > 60 && percent > bestMatchValue) {
			bestMatchValue = percent;
			matchId = i.first;
		}
	}

	return matchId;
}

cv::Point2f PersonDetection::centroidWeightedSum(const std::deque<cv::Point2f>& values, size_t index = 0) {

	if (index + 1 == values.size())
		return values.at(index);
	else
		return 0.2 * values.at(index) + 0.8 * centroidWeightedSum(values, index + 1);
}

void PersonDetection::calculateCentrod(cv::Point2f savedCentrod, const cv::Point2f newCentroid, Person& person, bool calcDiff = false) {

	if (calcDiff) {
		person.positions.push_back(newCentroid - savedCentrod);

		if (person.positions.size() == 7) {
			person.positions.pop_front();
			person.centroid = savedCentrod + centroidWeightedSum(person.positions);
		} else
			person.centroid = newCentroid;
	} else
		person.centroid = newCentroid;
}

Person PersonDetection::getPerson(Mat& frame, Mat& gFrame, cv::Rect boundingRect, map<int, map<uchar, int>>& greyColorVals) {

	Person person, tempPerson;
	person.boundingRect = boundingRect;
	cv::Point2f objCentrod = (boundingRect.tl() + boundingRect.br()) * 0.5f;
	
	float distance = -1, smallestDistance = FLT_MAX;
	int smallestDistanceId = -1;
	for (auto& pair : persons) {
		tempPerson = pair.second.first;
		// Calculate distance between centroids
		distance = calculateCentroidDistance(tempPerson.centroid, objCentrod);
		if (distance < 1000 && distance < smallestDistance) { //large
		//if (distance < 30 && distance < smallestDistance) { //small
			smallestDistance = distance;
			smallestDistanceId = tempPerson.id; 
		}
	}

	if (smallestDistanceId > -1) {
		person.id = smallestDistanceId;
		person.positions = persons[smallestDistanceId].first.positions;
		calculateCentrod(persons[smallestDistanceId].first.centroid, objCentrod, person, true);
		persons[smallestDistanceId] = make_pair(person, true);
		Basics::convertGrey(_r_frame, _p_frame);
		return person;
	}

	map<uchar, int> currGreyColorVals = getColorsCount(gFrame(boundingRect));

	int matchValue = -1;
	if (!  greyColorVals.empty()) {
		matchValue = compare(currGreyColorVals, greyColorVals);
	}

	if (matchValue < 0) {
		cout << "=================================================== 361";
		person.id = personId;
		greyColorVals.insert(pair<int, map<uchar, int>>(personId, currGreyColorVals));
		personId++;
	}
	else {
		cout << "++++++++++++++++++++++++++++++++++++++++++++++++++++++ 367";
		person.id = matchValue;
	}
	calculateCentrod(person.centroid, objCentrod, person);
	persons[person.id].first = person;
	persons[person.id].second = true;

	_p_frame = _r_frame;
	return person;
}

//Person PersonDetection::getPerson(Mat& frame, Mat& gFrame, cv::Rect boundingRect, map<int, map<uchar, int>>& greyColorVals) {
//	cv::Point2f centroid = (boundingRect.tl() + boundingRect.br()) * 0.5f;
//	for (auto& pair : persons) {
//		Person& person = pair.second.first;
//		// Calculate distance between centroids
//		float distance = calculateCentroidDistance(person.centroid, centroid);
//		// Check if the distance is smaller than a threshold
//		cout << distance << endl;
//		if (distance < 1000) { //large
//		//if (distance < 0) { //small
//			cout << "-----------------------------------------------------   : 344 " << endl;
//			person.boundingRect = boundingRect;
//			person.centroid = centroid;
//			persons[personId] = make_pair(person, true);
//			Basics::convertGrey(_r_frame, _p_frame);
//			return person;
//		}
//	}
//
//	map<uchar, int> currGreyColorVals = getColorsCount(gFrame(boundingRect));
//
//	int matchValue = -1;
//	if (!greyColorVals.empty()) {
//		matchValue = compare(currGreyColorVals, greyColorVals);
//	}
//
//	Person Person;
//	if (matchValue < 0) {
//		cout << "=================================================== 361";
//		Person.id = personId;
//		persons[personId].first = Person;
//		persons[personId].second = true;
//		greyColorVals.insert(pair<int, map<uchar, int>>(personId, currGreyColorVals));
//		personId++;
//	}
//	else {
//		cout << "++++++++++++++++++++++++++++++++++++++++++++++++++++++ 367";
//		Person.id = matchValue;
//		persons[matchValue].first.centroid = centroid;
//		persons[matchValue].second = true;
//	}
//
//	Person.boundingRect = boundingRect;
//	Person.centroid = centroid;
//
//	_p_frame = _r_frame;
//	return Person;
//}