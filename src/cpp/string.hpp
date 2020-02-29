// string.hpp

std::string str_vector_join(const std::vector<std::string> &str_vec, std::string join_char) {

	std::string out;
	for (std::vector<std::string>::const_iterator it = str_vec.begin(); it != str_vec.end(); ++it) {
		out += *it;
		if (it != str_vec.end() - 1) out += join_char;
		}
	return out;
	}

std::string float_str(const double &n, const int &precision) {
	std::stringstream stream;
	stream << std::fixed << std::setprecision(precision) << n;
	std::string number_str = stream.str();
	return number_str;
	}

std::string number_str(const double &n) {
	std::fesetround(FE_TONEAREST);
	double k = std::nearbyint(n);
	double l = std::fabs(n - k);

	if (l < 0.05) return std::to_string((long) k);
	return float_str(n, 1);
	}

std::string hex_code_point_str(const long &code_point) {
	std::stringstream stream;
	stream << std::setfill('0') << std::setw(4) << std::uppercase << std::hex << code_point;
	return stream.str();
	}

std::string attr(std::string name, std::string value) {
	return name + "=\"" + value + "\"";
	}

std::string attrs_str(const std::vector<std::string> &attrs) {
	std::string str_attrs = str_vector_join(attrs, " ");
	return str_attrs;
	}
