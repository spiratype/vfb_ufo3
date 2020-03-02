// string.hpp

std::string str_vector_join(const std::vector<std::string> &str_vec, const char join_char) {
	std::stringstream out;
	for (auto &str : str_vec)
		out << str << join_char;
	std::string out_str = out.str();
	out_str.pop_back();
	return out_str;
	}

std::string float_str(const double &n, const int &precision) {
	std::stringstream stream;
	stream << std::fixed << std::setprecision(precision) << n;
	return stream.str();
	}

std::string number_str(const double &n) {
	const double k = std::nearbyint(n);
	const double l = std::fabs(n - k);

	if (l < 0.05)
		return std::to_string((long) k);
	return float_str(n, 1);
	}

std::string hex_code_point_str(const long &code_point) {
	std::stringstream stream;
	stream << std::setfill('0') << std::setw(4) << std::uppercase << std::hex << code_point;
	return stream.str();
	}

std::string attr(std::string name, std::string value) {
	return name + "=\"" + value + '\"';
	}

std::string attrs_str(const std::vector<std::string> &attrs) {
	const std::string str_attrs = str_vector_join(attrs, ' ');
	return str_attrs;
	}
