// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// LazyPoints customization.
class tt_lp_TypistParameters : tt_lp_Parameters
{
  override Font getFont() const { return Font.getFont("NewSmallFont"); }

  override int getBonusCountdown() const { return 3; }

  override int getYOffset() const
  {
    int scale = max(1, Cvar.getCvar("tt_view_scale", players[consolePlayer]).getInt());
    let [width, height] = tt_Drawing.getBoxSize("", "", scale);
    return height * 2 + tt_InfoPanel.MARGIN;
  }

  override int getScale() const
  {
    return max(1, Cvar.getCvar("tt_view_scale", players[consolePlayer]).getInt());
  }

  override bool isPickupBonusEnabled() const { return false; }

  override bool isScoringEnabledNow() const
  {
    let eventHandler = tt_EventHandler(EventHandler.find("tt_EventHandler"));
    return eventHandler.getMode() == tt_Mode.Combat;
  }
}
