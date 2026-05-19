// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Namespace for math-related functions.
class tt_Math
{
  static bool isInEffectiveRange(vector3 p1, vector3 p2)
  {
    double distance = (p1 - p2).length();
    bool   inRange  = distance < MAX_DISTANCE;

    return inRange;
  }

  // Max effective distance.
  const MAX_DISTANCE = 700;
}
