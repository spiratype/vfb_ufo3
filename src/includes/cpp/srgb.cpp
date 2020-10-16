// srgb.cpp

#include <fenv.h>
#include <cmath>

struct RGB {
	double r;
	double g;
	double b;
	};

RGB mark_to_srgb_1_0(const int mark_color) {

	/*
	The FontLab `mark` color attribute for a single glyph can refer to either
	the glyph cell itself or the glyph title cell directly above it; the title
	cell is darker than the glyph cell. All 255 possibilities are mapped into
	`MARK_COLORS` located @ `mark.hpp`. FontLab will allow a user to set an
	integer larger than 255 to the glyph `mark` attribute via the Python
	interpreter; these are ignored.

	double s = 0.466; // dark colors
	double v = 0.910; // dark colors
	double s = 0.302; // light colors
	double v = 1.000; // light colors
	*/

	const double s = 0.302; // light colors
	const double v = 1.000; // light colors

	const double hue = std::ceil((mark_color / 255.0) * 360.0);

	double r = 0.0;
	double g = 0.0;
	double b = 0.0;

	const double h = hue / 60.0;
	double c = v * s;
	double x = c * (1 - std::fabs(std::fmod(h, 2) - 1));
	const double m = v - c;
	x += m;
	c += m;

	switch ((int) h) {
		case 0:
			r = c;
			g = x;
			b = m;
			break;
		case 1:
			r = x;
			g = c;
			b = m;
			break;
		case 2:
			r = m;
			g = c;
			b = x;
			break;
		case 3:
			r = m;
			g = x;
			b = c;
			break;
		case 4:
			r = x;
			g = m;
			b = c;
			break;
		case 5:
			r = c;
			g = m;
			b = x;
			break;
		}

	return RGB(r, g, b);
	}
