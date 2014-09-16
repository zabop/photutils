# Licensed under a 3-clause BSD style license - see LICENSE.rst

from __future__ import (absolute_import, division, print_function,
                        unicode_literals)
import numpy as np
cimport numpy as np

__all__ = ['rectangular_overlap_grid']

cdef extern from "math.h":

    double asin(double x)
    double sin(double x)
    double cos(double x)
    double sqrt(double x)
    double fabs(double x)

from cpython cimport bool

DTYPE = np.float64
ctypedef np.float64_t DTYPE_t

cimport cython

from .core import distance, area_triangle, overlap_area_triangle_unit_circle


def rectangular_overlap_grid(double xmin, double xmax, double ymin, double ymax,
                            int nx, int ny, double width, double height, double theta,
                            int use_exact, int subpixels):
    """
    rectangular_overlap_grid(x, y, dx, dy, theta)

    Area of overlap between an rectangle and a pixel grid. Given a grid, find
    the fraction of overlap in each with a rectangle with dimensions ``width``
    and ``height``, position angle ``theta``. The rectangle is centered on the
    origin.

    Parameters
    ----------
    xmin, xmax, ymin, ymax : float
        Extent of the grid in x and y direction.
    nx, ny : int
        Dimension of grid.
    width : float
        The width of the rectangle
    height : float
        The height of the rectangle
    theta : float
        The position angle of the rectangle in radians (counterclockwise)
    use_exact : 0 or 1
        If ``1`` calculates exact overlap, if ``0`` uses ``subpixel`` number
        of subpixels to calculate the overlap.
    subpixels : int
        Each pixel resampled by this factor in each dimension, thus each
        pixel is devided into ``subpixels ** 2`` subpixels.

    Returns
    -------
    frac : `~numpy.ndarray`
        2-d array giving the fraction of the overlap.
    """

    cdef unsigned int i, j
    cdef double x, y, dx, dy
    cdef double pxmin, pxmax, pymin, pymax

    # Define output array
    cdef np.ndarray[DTYPE_t, ndim=2] frac = np.zeros([ny, nx], dtype=DTYPE)

    if use_exact == 1:
        raise NotImplementedError("Exact mode has not been implemented for rectangular apertures")

    # Find the width of each element in x and y
    dx = (xmax - xmin) / nx
    dy = (ymax - ymin) / ny

    # TODO: can implement a bounding box here for efficiency (as for the
    # circular and elliptical aperture photometry)

    for i in range(nx):
        pxmin = xmin + i * dx  # lower end of pixel
        pxmax = pxmin + dx  # upper end of pixel
        for j in range(ny):
            pymin = ymin + j * dy
            pymax = pymin + dy
            frac[j, i] = rectangular_overlap_single_subpixel(pxmin, pymin, pxmax, pymax, width, height, theta, subpixels) / (dx * dy)

    return frac


cdef double rectangular_overlap_single_subpixel(double x0, double y0,
                                                double x1, double y1,
                                                double width, double height,
                                                double theta, int subpixels):
    """
    Return the fraction of overlap between a rectangle and a single pixel with
    given extent, using a sub-pixel sampling method.
    """

    cdef unsigned int i, j
    cdef double x, y
    cdef double frac = 0.  # Accumulator.
    cdef double cos_theta = cos(theta)
    cdef double sin_theta = sin(theta)
    cdef double half_width, half_height

    half_width = width / 2.
    half_height = height / 2.
    
    dx = (x1 - x0) / subpixels
    dy = (y1 - y0) / subpixels
    
    x = x0 - 0.5 * dx
    for i in range(subpixels):
        x += dx
        y = y0 - 0.5 * dy
        for j in range(subpixels):
            y += dy
            
            # Transform into frame of rotated rectangle
            x_tr = y * sin_theta + x * cos_theta
            y_tr = y * cos_theta - x * sin_theta

            if fabs(x_tr) < half_width and fabs(y_tr) < half_height:
                frac += 1.

    return frac / (subpixels * subpixels)

