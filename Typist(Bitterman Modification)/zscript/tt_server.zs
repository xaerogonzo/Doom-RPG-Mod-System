// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

class tt_Server
{
  static tt_Server of()
  {
    let result = new("tt_Server");
    result._globalChangers = tt_PlayerWorldChangers.of();
    return result;
  }

  void addPlayer(int playerNumber)
  {
    let playerSource       = tt_PlayerSourceImpl    .of(playerNumber);
    let originSource       = tt_PlayerOriginSource  .of(playerSource);
    let targetOriginSource = tt_ExternalOriginSource.of();
    let targetRadar        = tt_TargetRadar         .of(originSource);
    let radarStaleMarker   = tt_StaleMarkerImpl     .of(tt_TotalClock.of());
    let radarCacheDirty    = tt_TargetSourceCache   .of(targetRadar, radarStaleMarker);
    let radarCache         = tt_TargetSourcePruner  .of(radarCacheDirty);
    let freelookSetting    = tt_BoolCvar            .of(playerSource, "freelook");

    Array<tt_WorldChanger> targetChangers = {
      tt_HorizontalAimer.of(targetOriginSource, playerSource),
      tt_VerticalAimer.of(targetOriginSource, playerSource, freelookSetting),
      tt_Firer.of(playerSource)
    };

    _targetSources[playerNumber]  = targetOriginSource;
    _targetChangers[playerNumber] = tt_WorldChangers.of(targetChangers);

    let speedController = tt_EnemySpeedController.of(radarCache, playerSource);

    Array<tt_WorldChanger> globalChangers = {
      tt_ProjectileSpeedController.of(originSource, playerSource),
      speedController
    };

    _speedControllers[playerNumber] = speedController;
    _globalChangers.add(playerNumber, tt_WorldChangers.of(globalChangers));
  }

  void removePlayer(int playerNumber) { _globalChangers.remove(playerNumber); }

  // Called after tt_PlayerSupervisor is built to swap the radar-based feed
  // for the LOS-confirmed visible source. Enemies now only slow down when
  // the player genuinely has a clear shot at them.
  void setVisibleTargetSource(int playerNumber, tt_KnownTargetSource visible)
  {
    _speedControllers[playerNumber].setTargetSource(visible);
  }

  play void react(int playerNumber, vector3 targetOrigin)
  {
    _targetSources[playerNumber].setOrigin(tt_Origin.of(targetOrigin));
    _targetChangers[playerNumber].changeWorld();
  }

  play void tick() { _globalChangers.changeWorld(); }

  tt_ExternalOriginSource _targetSources[MAXPLAYERS];
  tt_WorldChanger         _targetChangers[MAXPLAYERS];
  tt_PlayerWorldChangers  _globalChangers;
  tt_EnemySpeedController _speedControllers[MAXPLAYERS];
}
