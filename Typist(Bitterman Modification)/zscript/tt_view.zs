// SPDX-FileCopyrightText: © 2019 Alexander Kromm <mmaulwurff@gmail.com>
// SPDX-License-Identifier: BSD-3-Clause

// This interface represents a view - something that displays something.
class tt_View abstract
{
  ui abstract void draw(RenderEvent event);
}

// Implements View by allowing several Views to be drawn.
class tt_Views : tt_View
{
  static tt_Views of(Array<tt_View> views)
  {
    let result = new("tt_Views");
    result._views.move(views);
    return result;
  }

  override void draw(RenderEvent event)
  {
    foreach (view : _views)
      view.draw(event);
  }

  private Array<tt_View> _views;
}

class tt_Frame : tt_View
{
  static tt_Frame of(tt_ModeSource modeSource)
  {
    let result = new("tt_Frame");
    result._modeSource = modeSource;
    result._alphaInterpolator = tt_DoubleInterpolator.of();
    return result;
  }

  static int getWidth() { return Screen.getWidth() / 64; }

  override void draw(RenderEvent _)
  {
    double destination = (_modeSource.getMode() == tt_Mode.Combat) ? 1.0 : 0.0;

    _alphaInterpolator.reset(destination, 0.1);
    // TODO: untie from framerate?
    _alphaInterpolator.update();

    double alpha = _alphaInterpolator.getValue();

    if (alpha ~== 0.0) return;

    int   screenWidth  = Screen.getWidth();
    int   screenHeight = Screen.getHeight();
    int   width        = getWidth();
    int   height       = width;
    Color white        = "FFFFFF";

    Screen.dim(white, alpha, 0, 0, width, screenHeight);
    Screen.dim(white, alpha, width, 0, screenWidth - width * 2, height);
    Screen.dim(white, alpha, screenWidth - width, 0, width, screenHeight);
    Screen.dim(white,
               alpha,
               width,
               screenHeight - height,
               screenWidth - width * 2,
               height);
  }

  private tt_ModeSource _modeSource;
  private tt_DoubleInterpolator _alphaInterpolator;
}

// Implements a view by taking another view, and calling draw()
// only if conditions are met.
//
// The list of conditions:
// - not in a menu
// - automap is closed
//
// Attention! This class reads data from global scope.
class tt_ConditionalView : tt_View
{
  static tt_ConditionalView of(tt_View view)
  {
    let result = new("tt_ConditionalView");
    result._view = view;
    return result;
  }

  override void draw(RenderEvent event)
  {
    if (!menuActive && !automapActive) _view.draw(event);
  }

  private tt_View _view;
}

// Implements View by collecting and displaying various information:
// - game mode
// - list of commands
// - current input string
// - several targets
class tt_InfoPanel : tt_View
{
  static tt_InfoPanel of(tt_ModeSource        modeSource,
                         tt_AnswerSource      answerSource,
                         tt_Activatable       activatable,
                         tt_KnownTargetSource knownTargetSource,
                         tt_IntSetting        scaleSetting)
  {
    let result = new("tt_InfoPanel");

    result._modeSource   = modeSource;
    result._answerSource = answerSource;
    result._activatable  = activatable;
    result._targetSource = knownTargetSource;
    result._scaleSetting = scaleSetting;

    return result;
  }

  override void draw(RenderEvent _)
  {
    let targets      = _targetSource.getTargets();
    let targetCount  = targets.size();
    let commands     = _activatable.getCommands();
    let commandCount = commands.size();
    if (targetCount == 0 && commandCount == 0) return;

    int scale        = _scaleSetting.get();
    int screenWidth  = Screen.getWidth();
    int halfScreen   = screenWidth / 2;
    int scaledMargin = MARGIN * scale;
    int frameWidth   = tt_Frame.getWidth();
    int y            = scaledMargin + frameWidth;
    let answer       = _answerSource.getAnswer().getString();
    int color        = tt_Drawing.getColorForMode(_modeSource.getMode());

    int xLeft  = halfScreen;
    int xRight = halfScreen;

    // 1. Draw the first target in the center.
    if (targetCount > 0)
    {
      let    question       = targets.at(0).getQuestion();
      string questionString = question.getDescription();
      string hintedAnswer   = question.getHintFor(answer);
      let [width, height]   = tt_Drawing.getBoxSize(questionString,
                                                    hintedAnswer,
                                                    scale);

      tt_Drawing.drawTarget(halfScreen - width / 2,
                            y,
                            width,
                            height,
                            questionString,
                            hintedAnswer,
                            scale,
                            color);

      xLeft  = halfScreen - width / 2 - scaledMargin;
      xRight = xLeft + width + scaledMargin * 2;
    }

    // 2. Draw the targets to the right while there is space.
    uint i = 1;
    for (; i < targetCount; ++i)
    {
      let    question       = targets.at(i).getQuestion();
      string questionString = question.getDescription();
      string hintedAnswer   = question.getHintFor(answer);
      let [width, height]   = tt_Drawing.getBoxSize(questionString,
                                                    hintedAnswer,
                                                    scale);

      if (xRight + width > screenWidth - frameWidth) break;

      tt_Drawing.drawTarget(xRight,
                            y,
                            width,
                            height,
                            questionString,
                            hintedAnswer,
                            scale,
                            color);

      xRight += width + scaledMargin;
    }

    // 3. Draw the commands to the left while there is space.
    for (uint c = 0; c < commandCount; ++c)
    {
      let  command        = commands.at(c);
      let  hintedAnswer   = tt_Match.getColoredMatch(command, answer);
      let [width, height] = tt_Drawing.getBoxSize(command, hintedAnswer, scale);
      bool isCentered     = targetCount == 0 && c == 0;
      let  x              = isCentered ? halfScreen - width / 2 : xLeft - width;

      if (x < frameWidth) break;

      tt_Drawing.drawTarget(x,
                            y,
                            width,
                            height,
                            command,
                            hintedAnswer,
                            scale,
                            color);

      xLeft -= width + scaledMargin;
    }

    // 4. Draw the remaining targets to the left while there is space.
    for (; i < targetCount; ++i)
    {
      let    question       = targets.at(i).getQuestion();
      string questionString = question.getDescription();
      string hintedAnswer   = question.getHintFor(answer);
      let [width, height]   = tt_Drawing.getBoxSize(questionString,
                                                    hintedAnswer,
                                                    scale);

      if (xLeft - width < frameWidth) break;

      tt_Drawing.drawTarget(xLeft - width,
                            y,
                            width,
                            height,
                            questionString,
                            hintedAnswer,
                            scale,
                            color);

      xLeft -= width + scaledMargin;
    }
  }

  const MARGIN = 2;

  private tt_ModeSource        _modeSource;
  private tt_AnswerSource      _answerSource;
  private tt_Activatable       _activatable;
  private tt_KnownTargetSource _targetSource;
  private tt_IntSetting        _scaleSetting;
}

// Implement tt_View by getting a list of Target Widgets and drawing them.
class tt_TargetOverlay : tt_View
{
  static tt_TargetOverlay of(tt_TargetWidgetSource targetWidgetSource,
                             tt_AnswerSource       answerSource,
                             tt_IntSetting         scaleSetting,
                             tt_ModeSource         modeSource)
  {
    let result = new("tt_TargetOverlay");

    result._targetWidgetSource = targetWidgetSource;
    result._answerSource       = answerSource;
    result._scaleSetting       = scaleSetting;
    result._modeSource         = modeSource;

    return result;
  }

  override void draw(RenderEvent event)
  {
    let widgets = _targetWidgetSource.getWidgets(event);
    let answer  = _answerSource.getAnswer().getString();
    int mode    = _modeSource.getMode();
    int color   = tt_Drawing.getColorForMode(mode);
    int scale   = _scaleSetting.get();
    int screenWidth  = Screen.getWidth();
    int screenHeight = Screen.getHeight();
    int frameWidth   = tt_Frame.getWidth();

    uint nWidgets = widgets.size();
    for (uint i = 0; i < nWidgets; ++i)
    {
      let widget          = widgets.at(i);
      let question        = widget.getTarget().getQuestion();
      let questionString  = question.getDescription();
      let hintedAnswer    = question.getHintFor(answer);
      let position        = widget.getPosition();
      let [width, height] = tt_Drawing.getBoxSize(questionString,
                                                  hintedAnswer,
                                                  scale);

      int x = int(clamp(position.x - width / 2,
                        frameWidth,
                        screenWidth  - width - frameWidth));
      int y = int(clamp(position.y - height,
                        frameWidth,
                        screenHeight - height * 2 - frameWidth));

      tt_Drawing.drawTarget(x,
                            y,
                            width,
                            height,
                            questionString,
                            hintedAnswer,
                            scale,
                            color);
    }
  }

  private tt_TargetWidgetSource _targetWidgetSource;
  private tt_AnswerSource       _answerSource;
  private tt_IntSetting         _scaleSetting;
  private tt_ModeSource         _modeSource;
}

// Namespace for common drawing functions.
class tt_Drawing ui
{
  static int getColorForMode(int mode)
  {
    return (mode == tt_Mode.Combat)
      ? tt_RgbColors.AnswerCombat
      : tt_RgbColors.AnswerExploration;
  }

  static int, int getBoxSize(string question, string answer, int scale)
  {
    // One extra BORDER for width: stringWidth tends to underestimate the width.
    let aFont  = NewSmallFont;
    int height = scale * (BORDER * 4 + aFont.getHeight());
    int width  = scale * (BORDER * 5 + max(aFont.stringWidth(question),
                                           aFont.stringWidth(answer)));
    return width, height;
  }

  static void drawTarget(int    x,
                         int    y,
                         int    width,
                         int    height, // Box height, target is two boxes.
                         string question,
                         string answer,
                         int    scale,
                         Color  answerColor)
  {
    drawBox(x, y, width, height, question, scale, tt_RgbColors.Question);
    drawBox(x, y + height, width, height, answer, scale, answerColor);
  }

  private static void drawBox(int    x,
                              int    y,
                              int    width,
                              int    height,
                              string text,
                              int    scale,
                              Color  aColor)
  {
    int scaledBorder = BORDER * scale;
    Color backgroundColor = Color(aColor.r / 2, aColor.g / 2, aColor.b / 2);

    Screen.dim(aColor, ALPHA, x, y, width, height);
    Screen.dim(backgroundColor,
               ALPHA,
               x + scaledBorder,
               y + scaledBorder,
               width  - scaledBorder * 2,
               height - scaledBorder * 2,
               STYLE_Subtract);

    Screen.drawText(NewSmallFont,
                    tt_TextColors.Base,
                    x + scaledBorder * 2,
                    y + scaledBorder * 2,
                    text,
                    DTA_ScaleX, scale,
                    DTA_ScaleY, scale);
  }

  const BORDER = 2;
  const ALPHA  = 0.2;
}
