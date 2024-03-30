#pragma once
#include "CameraHandler.cuh"


class HawkCam {
public:
	HawkCam(string* paths,int count):_paths(paths),_count(count) {
		handlers = vector<CamHandler>();
		checker = vector<bool>();
	}
	void loadStreams() {
		for (int i = 0; i < _count; i++) {
			handlers.push_back(CamHandler(_paths[i], i));
			checker.push_back(false);
		}
			
		bool goOn = false;
		while (true) {
			for (int j = 0; j < _count; j++) {
				if (handlers[j].load()) {
					checker[j] = true;
				}
			}
			for (int j = 0; j < _count; j++) {
				if (checker[j]) {
					goOn = true;
				}
				else {
					goOn = false;
					break;
				}
			}
			if (goOn)
				break;
		}
	}
	void setupStreams() {
		for (int i = 0; i < _count; i++) {
			handlers[i].setup();
		}
	}

	void loop() {
		bool goOn = false;
		for (int j = 0; j < _count; j++) {
			handlers[j].preloop();
		}

		while (true) {
			for (int j = 0; j < _count; j++) {
				if (handlers[j].loop()) {
					checker[j] = false;
				}
			}
			for (int j = 0; j < _count; j++) {
				if (!checker[j]) {
					goOn = true;
				}
				else {
					goOn = false;
					break;
				}
			}
			if (goOn)
				break;
		}
	}
	void finalize() {
		for (int i = 0; i < _count; i++) {
			handlers[i].destroy();
		}
		handlers.clear();
		_paths = NULL;
	}


private:
	string* _paths;
	vector<CamHandler> handlers;
	vector<bool> checker;
	int _count = 0;
};