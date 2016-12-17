#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import sys
import numpy as np

from utils import EnviReader

def remove_continuum(data):
    """
    data is two dimension array, np.array([(x1, y1), (x2, y2), ...])
    """
    _data = np.array(data)
    wave = _data[:, 0]
    refl = _data[:, 1]
    tmp_wav = [wave[0]]
    tmp_ref = [refl[0]]
    tmp_idx = [0]
    e_len = len(refl) - 1

    flag_i = 1
    i = 0
    while i < e_len and flag_i:
        if i > e_len:
            break
        j = i + 1
        flag_j = 1
        while j <= e_len and flag_j:
            if j == e_len:
                tmp_wav.append(wave[j])
                tmp_ref.append(refl[j])
                tmp_idx.append(j)
                flag_i = 0
                break
            m = j + 1
            while m <= e_len:
                if m == e_len:
                    tmp_wav.append(wave[j])
                    tmp_ref.append(refl[j])
                    tmp_idx.append(j)
                    i = j
                    flag_j = 0
                    break
                else:
                    a = np.array([
                            [wave[i], 1],
                            [wave[j], 1]
                        ])
                    b = np.array([refl[i], refl[j]])
                    inv_a = np.linalg.inv(a)
                    xx = np.dot(inv_a, b)
                    y1 = xx[0] * wave[m] + xx[1]

                    if y1 < refl[m]:
                        j = j + 1
                        break
                    else:
                        m = m + 1
                        continue
    # print tmp_idx
    # print tmp_ref

    interp_ref = [refl[0]]
    cr_points_len = len(tmp_ref)

    # each time calculate the (x0, x1]
    for i in xrange(1, cr_points_len):
        span = tmp_idx[i] - tmp_idx[i - 1]
        if span == 1:
            # interp_ref.append(tmp_ref[i])
            interp_ref.append(refl[tmp_idx[i]])
        else:
            x = np.array([
                    [tmp_wav[i],     1],
                    [tmp_wav[i - 1], 1]
                ])
            # y = np.array([tmp_ref[i], tmp_ref[i - 1]])
            y = np.array([
                refl[tmp_idx[i]    ],
                refl[tmp_idx[i - 1]]
            ])
            inv_x = np.linalg.inv(x)
            p = np.dot(inv_x, y)
            interp_res = p[0] * wave[tmp_idx[i - 1] + 1: tmp_idx[i] + 1] + p[1]
            interp_ref.extend(interp_res)

    assert len(interp_ref) == len(refl)
    cr_ref = map(lambda e: e[0]/e[1], zip(refl, interp_ref))

    return zip(wave, cr_ref), zip(wave, interp_ref)

def scipy_hull(points):
    """
    example for the usage of scipy of ConvexHull function
    """
    import matplotlib.pyplot as plt
    from scipy.spatial import ConvexHull

    hull = ConvexHull(points)
    plt.plot(points[:,0], points[:,1], 'o')
    data = []
    for simplex in hull.simplices:
        plt.plot(points[simplex, 0], points[simplex, 1], 'k-')
        # print simplex
        # print points[simplex], points[simplex, 0], points[simplex, 1]
        data.append((points[simplex, 0], points[simplex, 1]))
    plt.plot(points[hull.vertices,0], points[hull.vertices,1], 'r--', lw=2)
    plt.plot(points[hull.vertices[0],0], points[hull.vertices[0],1], 'ro')
    # print points[hull.vertices, 0]
    # print points[hull.vertices, 1]
    # print hull.vertices[::-1]
    plt.show()

def find_minimum(points, smooth_width = 1):
    """
    data is two dimension array, np.array([[x1, y1], [x2, y2], ...])
    """
    points = np.array(points)
    sm_w = 1
    st_p = sm_w
    ed_p = len(points) - sm_w

    ret = []
    for p in xrange(st_p, ed_p):
        prev_avg_y = sum(points[p - sm_w: p        , 1]) / sm_w
        next_avg_y = sum(points[p + 1: p + 1 + sm_w, 1]) / sm_w
        curr_p_y = points[p, 1]
        if curr_p_y < prev_avg_y and curr_p_y < next_avg_y:
            ret.append(points[p])
        # if points[p, 0] < 600:
        #     print prev_avg_y, next_avg_y, curr_p_y
        #     # print points[p-sm_w:p]
        #     # print points[p+1:p+1+sm_w]

    # filter the span is too small points

    return np.array(ret)

def draw_graph(points_array, points):
    """
    array of points, [
      np.array([[x11, y11], [x12, y12], ...]),
      np.array([[x21, y21], [x22, y22], ...])
    ]
    """
    import matplotlib.pyplot as plt

    plt.figure(1)
    for ps in points_array:
        ps = np.array(ps)
        plt.plot(ps[:, 0], ps[:, 1])

    plt.plot(points[:, 0], points[:, 1], 'ro')

    plt.show()


if __name__ == '__main__':
    if len(sys.argv) == 1:
        print "Usage: %s <HDR path>" % sys.argv[0]
        sys.exit(-1)

    path = sys.argv[1]
    envi_r = EnviReader(path)
    orig_d = envi_r.get_data()
    wave = map(lambda e: round(e[0]), orig_d)
    refl = map(lambda e: e[1] / 10000, orig_d)
    d = zip(wave, refl)
    cr_ref, interp_ref = remove_continuum(d)

    min_points = find_minimum(cr_ref)
    draw_graph([d, cr_ref, interp_ref], min_points)
    # scipy_hull(np.array(d))
