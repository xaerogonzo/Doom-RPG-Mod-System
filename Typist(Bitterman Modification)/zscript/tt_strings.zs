// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Represents a set of strings.
class tt_Strings
{
  static tt_Strings of()
  {
    let result = new("tt_Strings");
    return result;
  }

  static tt_Strings ofOne(String s)
  {
    let result = new("tt_Strings");
    result.add(s);
    return result;
  }

  uint size() const
  {
    return _strings.size();
  }

  string at(uint i) const
  {
    return _strings[i];
  }

  void set(uint i, string value)
  {
    _strings[i] = value;
  }

  bool contains(String str) const
  {
    uint foundIndex = _strings.Find(str);
    bool isFound    = (foundIndex != size());

    return isFound;
  }

  void add(String str)
  {
    _strings.push(str);
  }

  void clear() { _strings.clear(); }

  private Array<String> _strings;
}
