// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// Represents a target displayed on the screen.
class tt_TargetWidget
{
  static tt_TargetWidget of(tt_KnownTarget target, vector2 position)
  {
    let result = new("tt_TargetWidget");

    result._target   = target;
    result._position = position;

    return result;
  }

  tt_KnownTarget getTarget() const
  {
    return _target;
  }

  vector2 getPosition() const
  {
    return _position;
  }

  double getDistanceTo(vector3 other)
  {
    let worldPosition = _target.getTarget().getPosition().getVector();
    let distance      = (worldPosition - other).Length();

    return distance;
  }

  void setPosition(vector2 position)
  {
    _position = position;
  }

  private tt_KnownTarget _target;
  private vector2        _position;
}

// Represents a list of target widgets.
class tt_TargetWidgets
{
  static tt_TargetWidgets of() { return new("tt_TargetWidgets"); }

  // Returns a target in this list.
  tt_TargetWidget at(uint index) const { return _widgets[index]; }

  // Returns a number of targets in this list.
  uint size() const { return _widgets.size(); }

  tt_TargetWidget find(tt_Target id) const
  {
    foreach (widget : _widgets)
      if (widget.getTarget().getTarget().isEqual(id)) return widget;

    return NULL;
  }

  bool containsWidget(tt_TargetWidget widget) const
  {
    foreach (widgetItem : _widgets)
      if (widget == widgetItem) return true;

    return false;
  }

  tt_TargetWidgets copy() const
  {
    let result = tt_TargetWidgets.of();
    result._widgets.Reserve(size());
    result._widgets.Copy(_widgets);

    return result;
  }

  // Adds a target to this list.
  void add(tt_TargetWidget widget) { _widgets.push(widget); }

  void set(uint i, tt_TargetWidget widget)  { _widgets[i] = widget; }

  void clear() { _widgets.clear(); }

  private Array<tt_TargetWidget> _widgets;
}

// This interface provides a source of target widgets.
class tt_TargetWidgetSource abstract
{
  // Get a list of target widgets.
  // Returns a list of target widgets.
  ui abstract tt_TargetWidgets getWidgets(RenderEvent event);
}

// Implements TargetWidgetSource by accumulating Target Widgets.
// Attention: this class has no tests. Modifications must be checked manually.
class tt_Projector : tt_TargetWidgetSource
{
  static tt_Projector of(tt_KnownTargetSource knownTargetSource,
                         tt_PlayerSource playerSource)
  {
    let result = new("tt_Projector");

    result._knownTargetSource = knownTargetSource;
    result._playerSource      = playerSource;
    result._cvarRenderer      = tt_IntCvar.of(playerSource, "vid_rendermode");

    result._glProjection = new("tt_le_GlScreen");
    result._swProjection = new("tt_le_SwScreen");

    result._widgets = tt_TargetWidgets.of();

    return result;
  }

  override tt_TargetWidgets getWidgets(RenderEvent event)
  {
    let targets = _knownTargetSource.getTargets();
    let info    = _playerSource.getInfo();

    prepareProjection();

    _projection.CacheResolution();
    _projection.CacheFov(info.fov);
    _projection.OrientForRenderOverlay(event);
    _projection.BeginProjection();

    tt_le_Viewport viewport;
    viewport.FromHud();

    _widgets.clear();
    uint nTargets = targets.size();
    for (uint i = 0; i < nTargets; ++i)
    {
      let target = targets.at(i);

      let targetActor = target.getTarget().getActor();
      if (targetActor == NULL)
      {
        continue;
      }

      vector3 targetPos = target.getTarget().getPosition().getVector();
      vector2 position;
      bool    isPositionSuccessful;
      [position, isPositionSuccessful] = makeDrawPos(targetPos, viewport);

      if (isPositionSuccessful)
      {
        let widget = tt_TargetWidget.of(target, position);
        _widgets.add(widget);
      }
    }

    return _widgets;
  }

  // Calculates the screen position (draw position).
  // Returns screen position and success flag.
  private ui vector2, bool makeDrawPos(vector3 targetPos, tt_le_Viewport viewport)
  {
    _projection.ProjectWorldPos(targetPos);

    if(!_projection.IsInFront())
    {
      return (0, 0), false;
    }

    vector2 drawPos = viewport.SceneToWindow(_projection.ProjectToNormal());

    return drawPos, true;
  }

  private void prepareProjection()
  {
    if(_cvarRenderer.isDefined())
    {
      switch (_cvarRenderer.get())
      {
      case 0:
      case 1:  _projection = _swProjection; break;
      default: _projection = _glProjection; break;
      }
    }
    else // cannot get render mode.
    {
      _projection = _glProjection;
    }
  }

  private tt_KnownTargetSource _knownTargetSource;
  private tt_PlayerSource      _playerSource;

  private tt_le_ProjScreen _projection;
  private tt_le_GlScreen   _glProjection;
  private tt_le_SwScreen   _swProjection;

  private transient bool _isInitialized;

  private tt_IntCvar _cvarRenderer;

  private tt_TargetWidgets _widgets;
}

// Implements TargetWidgetSource by taking another TargetWidgetSource
// and sorting the widgets from it by a distance to origin from OriginSource.
//
// Sorting algorithm: merge sort
// https://en.wikipedia.org/wiki/Merge_sort
class tt_SorterByDistance : tt_TargetWidgetSource
{
  static tt_SorterByDistance of(tt_TargetWidgetSource targetWidgetSource,
                                tt_OriginSource originSource)
  {
    let result = new("tt_SorterByDistance");

    result._targetWidgetSource = targetWidgetSource;
    result._originSource       = originSource;

    return result;
  }

  override tt_TargetWidgets getWidgets(RenderEvent event)
  {
    let widgets = _targetWidgetSource.getWidgets(event);
    let origin  = _originSource.getOrigin().getVector();
    let sorted  = sort(widgets, origin);

    return sorted;
  }

  static tt_TargetWidgets sort(tt_TargetWidgets widgets, vector3 origin)
  {
    if (widgets.size() == 0) return widgets;

    let result    = widgets;
    let workplace = widgets.copy();

    TopDownSplitMerge(workplace, 0, widgets.size(), result, origin);

    return result;
  }

  private static void TopDownSplitMerge(tt_TargetWidgets B,
                                        uint             begin,
                                        uint             end,
                                        tt_TargetWidgets A,
                                        vector3          origin)
  {
    if ((end - begin) < 2) // if run size == 1 consider it sorted
    {
      return;
    }

    // split the run longer than 1 item into halves
    uint middle = (end + begin) / 2; // mid point

    // recursively sort both runs from array A into B
    TopDownSplitMerge(A, begin,  middle, B, origin); // sort the left  run
    TopDownSplitMerge(A, middle,    end, B, origin); // sort the right run

    // merge the resulting runs from array B into A
    TopDownMerge(B, begin, middle, end, A, origin);
  }

  private static void TopDownMerge(tt_TargetWidgets A,
                                   uint             begin,
                                   uint             middle,
                                   uint             end,
                                   tt_TargetWidgets B,
                                   vector3          origin)
  {
    uint i = begin;
    uint j = middle;

    // While there are elements in the left or right runs...
    for (uint k = begin; k < end; ++k)
    {
      // If left run head exists and is >= existing right run head.
      if (i < middle
          && (j >= end || A.at(i).getDistanceTo(origin) >= A.at(j).getDistanceTo(origin)))
      {
        B.set(k, A.at(i));
        ++i;
      }
      else
      {
        B.set(k, A.at(j));
        ++j;
      }
    }
  }

  private tt_TargetWidgetSource _targetWidgetSource;
  private tt_OriginSource       _originSource;
}

// Implements TargetWidgetSource by storing target widgets, getting
// new widgets from the source, and updating the coordinates of the widgets that
// are already registered.
class tt_TargetWidgetRegistry : tt_TargetWidgetSource
{
  static tt_TargetWidgetRegistry of(tt_TargetWidgetSource source)
  {
    let result = new("tt_TargetWidgetRegistry");
    result._source      = source;
    result._registry    = tt_TargetWidgets.of();
    result._newRegistry = tt_TargetWidgets.of();
    return result;
  }

  override tt_TargetWidgets getWidgets(RenderEvent event)
  {
    let widgets     = _source.getWidgets(event);

    uint nWidgets = widgets.size();
    for (uint i = 0; i < nWidgets; ++i)
    {
      let widget   = widgets.at(i);
      let target   = widget.getTarget().getTarget();
      let existing = _registry.find(target);

      if (existing == NULL)
      {
        _newRegistry.add(widget);
      }
      else
      {
        _newRegistry.add(existing);
        let newPosition      = widget.getPosition();
        let existingPosition = existing.getPosition();
        let middle           = (newPosition * 0.3 + existingPosition * 0.7);
        existing.setPosition(middle);
      }
    }

    // Widgets that are not new or not updated are thrown away.
    tt_TargetWidgets temp = _registry;
    _registry    = _newRegistry;
    _newRegistry = temp;
    _newRegistry.clear();

    return _registry;
  }

  private tt_TargetWidgetSource _source;
  private tt_TargetWidgets      _registry;
  private tt_TargetWidgets      _newRegistry;
}
