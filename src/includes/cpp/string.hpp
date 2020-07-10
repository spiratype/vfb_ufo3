// string.hpp

std::string float_str(const double n, const int precision=1) {
	return fmt::format("{:.{}f}", n, precision);
	}

std::string number_str(const double n) {
	const double k = std::nearbyint(n);
	const double l = std::fabs(n - k);

	if (l < 0.05)
		return std::to_string((long) k);
	return float_str(n);
	}

std::string attr(const std::string name, const std::string value) {
	return fmt::format("{}='{}' ", name, value);
	}

std::string attrs_str(const std::vector<std::string> attrs) {
	std::string out;
	out.reserve(140);
	for (const auto &str : attrs)
		out += str;
	out.pop_back();
	return out;
	}
