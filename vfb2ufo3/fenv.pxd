# fenv.pxd

cdef extern from 'fenv.h' nogil:
  const int FE_TONEAREST
  void fesetround(int)

cdef inline void set_nearest():
  fesetround(FE_TONEAREST)
