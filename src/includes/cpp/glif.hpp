
static const std::vector<std::string> POINT_TYPES = {
	" ", // offcurve
	"curve",
	"qcurve",
	"line"
	};

static const std::vector<std::string> HINT_TYPES = {
	"",
	"com.adobe.type.autohint",
	"com.adobe.type.autohint.v2",
	"public.postscript.hints",
	};

struct cpp_anchor;
struct cpp_contour_point;
struct cpp_component;
struct cpp_hint;
struct cpp_hint_replacement;
struct cpp_glif;

typedef std::vector<long> cpp_code_points;
typedef std::vector<cpp_anchor> cpp_anchors;
typedef std::vector<cpp_component> cpp_components;
typedef std::vector<cpp_hint> cpp_hints;
typedef std::vector<cpp_hint_replacement> cpp_hint_replacements;
typedef std::vector<cpp_contour_point> cpp_contour;
typedef std::vector<cpp_contour> cpp_contours;

struct cpp_ufo {
	std::vector<cpp_glif> glifs;
	std::unordered_map<size_t, cpp_code_points> code_points;
	std::unordered_map<size_t, cpp_anchors> anchors;
	std::unordered_map<size_t, cpp_components> components;
	std::unordered_map<size_t, cpp_hints> vhints;
	std::unordered_map<size_t, cpp_hints> hhints;
	std::unordered_map<size_t, cpp_hint_replacements> hint_replacements;
	std::unordered_map<size_t, cpp_contours> contours;
	std::unordered_map<size_t, std::string> completed_contours;
	int hint_type;
	void reserve(size_t n, size_t n_code_points, size_t n_anchors, size_t n_components, size_t n_contours);
	void hints_reserve(size_t n_vhints, size_t n_hhints, size_t n_hint_replacements);
	};
