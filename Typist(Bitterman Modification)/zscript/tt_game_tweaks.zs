// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Handles game tweaks.
class tt_GameTweaks play
{
  static void tweakPlayer(PlayerInfo player)
  {
    let pawn = player.mo;
    if (pawn == NULL) return;

    makeInvulnerable(pawn);
    increaseDamage(pawn);
    decreaseIncomingDamage(pawn);
    protectFromSelfDamage(pawn);
    disableSeekingMissiles(pawn);
  }

  // Still lose health down to 1 point.
  static private void makeInvulnerable(PlayerPawn pawn)
  {
    if (tt_buddha_enabled)
      pawn.giveInventory("tt_Buddha", 1);
  }

  static private void increaseDamage(PlayerPawn pawn)
  {
    double originalDamage = getDefaultByType(pawn.getClass()).damageMultiply;
    pawn.damageMultiply = originalDamage * 10;
  }

  static private void decreaseIncomingDamage(PlayerPawn pawn)
  {
    double originalFactor = getDefaultByType(pawn.getClass()).damageFactor;
    pawn.damageFactor = originalFactor / 2;
  }

  static private void protectFromSelfDamage(PlayerPawn pawn)
  {
    pawn.selfDamageFactor = 0;
  }

  static private void disableSeekingMissiles(PlayerPawn pawn)
  {
    pawn.bCantSeek = true;
  }
}
