// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

class tt_TextColors
{
  enum _
  {
    Base = Font.CR_WHITE,
  }
}

// See https://zdoom.org/wiki/Print#Colors for possible colors.
class tt_TextColorCodes
{
  enum _
  {
    WrongAnswer = tt_su_Ascii.LATIN_SMALL_LETTER_G, // red
  }
}

class tt_RgbColors
{
  enum _
  {
    Dim      = 0x000000, // Dims the background for text boxes.

    Question = 0xF4AF31, // Base color for question boxes.

    AnswerCombat      = 0xFF0000, // Base color for answer boxes in Combat mode.
    AnswerExploration = 0x999999, // Base color for answer boxes in Exploration mode.
  }
}
