// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// This interface represents entities that change the world state.
class tt_WorldChanger abstract
{
  play abstract void changeWorld();
}

// Implements tt_WorldChanger by executing several instances of tt_WorldChanger.
class tt_WorldChangers : tt_WorldChanger
{
  static tt_WorldChangers of(Array<tt_WorldChanger> changers)
  {
    let result = new("tt_WorldChangers");
    result._changers.move(changers);
    return result;
  }

  void add(tt_WorldChanger changer) { _changers.push(changer); }

  override void changeWorld()
  {
    foreach (changer : _changers)
      changer.changeWorld();
  }

  private Array<tt_WorldChanger> _changers;
}

// Implements tt_WorldChanger by executing not-NULL world changers.
class tt_PlayerWorldChangers : tt_WorldChanger
{
  static tt_PlayerWorldChangers of() { return new("tt_PlayerWorldChangers"); }

  void add(int playerNumber, tt_WorldChanger changer)
  {
    _changers[playerNumber] = changer;
  }

  void remove(int playerNumber)
  {
    _changers[playerNumber] = NULL;
  }

  override void changeWorld()
  {
    foreach (changer : _changers)
      if (changer != NULL) changer.changeWorld();
  }

  private tt_WorldChanger _changers[MAXPLAYERS];
}

// Implements tt_WorldChanger by slowing down enemies.
// Adapts tt_KnownTargetSource to tt_TargetSource by extracting raw actors.
// Allows tt_EnemySpeedController to be fed from a LOS-confirmed source.
class tt_KnownToTargetSourceAdapter : tt_TargetSource
{
  static tt_KnownToTargetSourceAdapter of(tt_KnownTargetSource source)
  {
    let result    = new("tt_KnownToTargetSourceAdapter");
    result._source  = source;
    result._targets = tt_Targets.of();
    return result;
  }

  override tt_Targets getTargets()
  {
    _targets.clear();
    let known = _source.getTargets();
    for (uint i = 0; i < known.size(); ++i)
      _targets.add(known.at(i).getTarget());
    return _targets;
  }

  private tt_KnownTargetSource _source;
  private tt_Targets           _targets;
}

class tt_EnemySpeedController : tt_WorldChanger
{
  static tt_EnemySpeedController of(tt_TargetSource targetSource,
                                    tt_PlayerSource playerSource)
  {
    let result = new("tt_EnemySpeedController");
    result._targetSource = targetSource;
    result._playerSource = playerSource;
    return result;
  }

  // Swap in a LOS-confirmed source so enemies only slow down when there
  // is a genuine clear shot — not just because they're nearby.
  void setTargetSource(tt_KnownTargetSource newSource)
  {
    _targetSource = tt_KnownToTargetSourceAdapter.of(newSource);
  }

  override void changeWorld()
  {
    let  targets  = _targetSource.getTargets();
    uint nTargets = targets.size();
    int  player   = _playerSource.getNumber();
    double scale  = getEnemyScale();

    // Slow down enemies currently in LOS target list.
    for (uint i = 0; i < nTargets; ++i)
    {
      let enemy = targets.at(i).getActor();
      if (enemy != NULL && !tt_VelocityStorage.isSlowedDown(enemy, player))
        tt_VelocityStorage.slowDown(enemy, player, scale);
    }

    // Restore any monsters that were slowed but are no longer in the LOS list.
    // Without this, enemies stay frozen if they leave the visible target list
    // (e.g. player moves, LOS breaks, or enemy drops out of range).
    foreach (Actor a : ThinkerIterator.create("Actor", Thinker.STAT_DEFAULT))
    {
      if (!a.bIsMonster || !tt_VelocityStorage.isSlowedDown(a, player)) continue;

      bool stillTargeted = false;
      for (uint i = 0; i < nTargets; ++i)
      {
        if (targets.at(i).getActor() == a) { stillTargeted = true; break; }
      }

      if (!stillTargeted) tt_VelocityStorage.restoreVelocity(a, player);
    }
  }

  private double getEnemyScale() const
  {
    let cv = CVar.GetCVar("tt_enemy_speed_scale", _playerSource.getInfo());
    if (cv != NULL) return clamp(cv.GetFloat(), 0.05, 1.0);
    return tt_VelocityStorage.DEFAULT_SCALE;
  }

  private tt_TargetSource _targetSource;
  private tt_PlayerSource _playerSource;
}

// Implements tt_WorldChanger by slowing down projectiles that fly towards the player.
//
// When a projectile is no longer flying towards the player, its speed is
// restored.
class tt_ProjectileSpeedController : tt_WorldChanger
{
  static tt_ProjectileSpeedController of(tt_OriginSource playerOriginSource,
                                         tt_PlayerSource playerSource)
  {
    let result = new("tt_ProjectileSpeedController");
    result._playerOriginSource = playerOriginSource;
    result._playerSource = playerSource;
    return result;
  }

  override void changeWorld()
  {
    let origin       = _playerOriginSource.getOrigin().getVector();
    let playerRadius = _playerSource.getPawn().radius;
    int player       = _playerSource.getNumber();
    double scale     = getProjectileScale();

    foreach (Actor a : ThinkerIterator.create("Actor", Thinker.STAT_DEFAULT))
      if (a.bMissile) controlProjectile(a, origin, playerRadius, player, scale);
  }

  private double getProjectileScale() const
  {
    let cv = CVar.GetCVar("tt_projectile_speed_scale", _playerSource.getInfo());
    if (cv != NULL) return clamp(cv.GetFloat(), 0.05, 1.0);
    return 0.2;
  }

  private static play void controlProjectile(Actor a,
                                             vector3 playerOrigin,
                                             double playerRadius,
                                             int player,
                                             double scale)
  {
    bool isInRange = tt_Math.isInEffectiveRange(a.pos, playerOrigin);

    if (isInRange && isMovingTowardsPlayer(a, playerOrigin, playerRadius))
    {
      if (!tt_VelocityStorage.isSlowedDown(a, player))
        tt_VelocityStorage.slowDown(a, player, scale);
    }
    else if (tt_VelocityStorage.isSlowedDown(a, player))
    {
      tt_VelocityStorage.restoreVelocity(a, player);
    }
  }

  private static play bool isMovingTowardsPlayer(Actor projectile,
                                                 vector3 playerPos,
                                                 double playerRadius)
  {
    vector3 vel = projectile.vel;
    if (vel == (0, 0, 0)) return false; // doesn't move

    vector3 oldProjectileRelativePosition = level.vec3Diff(playerPos, projectile.pos);
    vector3 newProjectileRelativePosition = oldProjectileRelativePosition + vel;

    if (oldProjectileRelativePosition.length()
        < newProjectileRelativePosition.length()) return false; // moves from player

    // http://mathworld.wolfram.com/Point-LineDistance3-Dimensional.html
    vector3 x10             = level.vec3Diff(projectile.pos, playerPos);
    vector3 prod            = vel cross x10;
    double  lineDistance    = prod.length() / vel.length();
    double  hitDistance     = playerRadius + projectile.radius;
    bool    willTouchPlayer = (hitDistance >= lineDistance);

    return willTouchPlayer;
  }

  private tt_OriginSource _playerOriginSource;
  private tt_PlayerSource _playerSource;
}

// This is a helper class that allows storing the velocity.
// TODO: rewrite with a Behavior?
class tt_VelocityStorage : Inventory
{
  static bool isSlowedDown(Actor other, int byPlayer)
  {
    let storage = tt_VelocityStorage(other.findInventory("tt_VelocityStorage"));
    if (storage == NULL) return false;

    return storage._byWhichPlayer[byPlayer];
  }

  static void slowDown(Actor other, int byPlayer, double scaleFactor = DEFAULT_SCALE)
  {
    let storage = tt_VelocityStorage(other.findInventory("tt_VelocityStorage"));

    if (storage != NULL)
    {
      storage._byWhichPlayer[byPlayer] = true;
      return;
    }

    storage = tt_VelocityStorage(Actor.spawn("tt_VelocityStorage"));
    storage._velocity = other.vel;
    storage._speed    = other.speed;

    other.addInventory(storage);

    other.vel   *= scaleFactor;
    other.speed *= scaleFactor;
  }

  static void restoreVelocity(Actor other, int byPlayer)
  {
    let storage = tt_VelocityStorage(other.findInventory("tt_VelocityStorage"));

    storage._byWhichPlayer[byPlayer] = false;

    if (storage.countByPlayers() == 0)
    {
      other.vel   = storage._velocity;
      other.speed = storage._speed;

      other.removeInventory(storage);
      storage.destroy();
    }
  }

  private int countByPlayers()
  {
    int result = 0;
    foreach (byPlayer : _byWhichPlayer)
      result += byPlayer;
    return result;
  }

  // Default fallback if CVars are unavailable. 0.5 = half speed (was 0.1).
  const DEFAULT_SCALE = 0.5;

  private vector3 _velocity;
  private double  _speed;
  private bool[MAXPLAYERS] _byWhichPlayer;
}

// Implements tt_WorldChanger interface by rotating the player.
class tt_HorizontalAimer : tt_WorldChanger
{
  static tt_HorizontalAimer of(tt_OriginSource targetOriginSource,
                               tt_PlayerSource playerSource)
  {
    let result = new("tt_HorizontalAimer");
    result._targetOriginSource = targetOriginSource;
    result._playerSource       = playerSource;
    return result;
  }

  override void changeWorld()
  {
    let targetOrigin = _targetOriginSource.getOrigin();
    if (targetOrigin == NULL) return;

    let pawn = _playerSource.getPawn();
    if (pawn == NULL) return;

    vector3 myPosition    = pawn.pos;
    vector3 otherPosition = targetOrigin.getVector();
    double  angle         = angleTo(myPosition.XY, otherPosition.XY);

    pawn.a_SetAngle(angle, SPF_INTERPOLATE);
  }

  private static double angleTo(vector2 myPosition, vector2 otherPosition)
  {
    vector2 diff = level.vec2Diff(myPosition, otherPosition);
    return vectorAngle(diff.x, diff.y);
  }

  private tt_OriginSource _targetOriginSource;
  private tt_PlayerSource _playerSource;
}

// Implements tt_WorldChanger interface by adjusting the player pitch
// (horizontal angle). If freelook is disabled, no pitch adjustment is done.
// TODO: fix when is an enemy is visible, but its middle is not.
class tt_VerticalAimer : tt_WorldChanger
{
  static tt_VerticalAimer of(tt_OriginSource targetOriginSource,
                             tt_PlayerSource playerSource,
                             tt_BoolSetting  freelookSetting)
  {
    let result = new("tt_VerticalAimer");
    result._targetOriginSource = targetOriginSource;
    result._playerSource       = playerSource;
    result._freelookSetting    = freelookSetting;
    return result;
  }

  override void changeWorld()
  {
    if (_freelookSetting.get()) setPitch();
  }

  private play void setPitch()
  {
    let targetOrigin = _targetOriginSource.getOrigin();
    if (targetOrigin == NULL) { return; }

    let pawn = _playerSource.getPawn();
    if (pawn == NULL) { return; }

    vector3 myPosition = pawn.pos;
    myPosition.z += pawn.Height / 2 + pawn.AttackZOffset;

    vector3 otherPosition = targetOrigin.getVector();
    vector3 diff          = level.vec3Diff(myPosition, otherPosition);
    double  pitch         = -atan2(diff.z, diff.xy.Length());

    pawn.a_SetPitch(pitch, SPF_INTERPOLATE);
  }

  private tt_OriginSource _targetOriginSource;
  private tt_PlayerSource _playerSource;
  private tt_BoolSetting  _freelookSetting;
}

// Implements tt_WorldChanger by making the player pawn fire a shot.
class tt_Firer : tt_WorldChanger
{
  static tt_Firer of(tt_PlayerSource playerSource)
  {
    let result = new("tt_Firer");
    result._playerSource = playerSource;
    return result;
  }

  override void changeWorld()
  {
    let  playerInfo = _playerSource.getInfo();
    bool isReady    = isWeaponReady(playerInfo);

    if (isReady)
    {
      let   pawn = _playerSource.getPawn();
      State stat = NULL;
      playerInfo.cmd.buttons |= BT_ATTACK;
      pawn.FireWeapon(stat);
    }
  }

  private static bool isWeaponReady(PlayerInfo player)
  {
    bool isReady = (player.WeaponState & WF_WEAPONREADY)
      || (player.WeaponState & WF_WEAPONREADYALT)
      || player.attackDown;

    return isReady;
  }

  private tt_PlayerSource _playerSource;
}
