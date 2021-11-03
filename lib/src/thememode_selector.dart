import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../thememode_selector.dart';
import 'celestial_transition.dart';
import 'flare.dart';
import 'focus_background.dart';
import 'moon.dart';
import 'star.dart';
import 'sun.dart';

class _ThemeModeSelectorConsts {
  late Size size;
  EdgeInsets? padding;
  EdgeInsets? focusPadding;
  late Size inset;
  late double toggleDiameter;
  List<dynamic> stars = [];
  List<dynamic> flares = [];

  _ThemeModeSelectorConsts(double height) {
    focusPadding = EdgeInsets.all(2);
    height = height - focusPadding!.bottom - focusPadding!.top;
    var width = height * 100 / 56;
    size = Size(width, height);
    padding = EdgeInsets.fromLTRB(
        width * .11, width * .085, width * .11, width * .085);
    var insetWidth = width - padding!.left - padding!.right;

    var insetHeight = height - padding!.top - padding!.bottom;
    toggleDiameter = insetHeight;
    inset = Size(insetWidth, toggleDiameter);

    var center = insetWidth / 2;

    stars.add({
      "from": Offset(center, 0.112 * insetHeight),
      "to": Offset(0.482 * insetWidth, 0.112 * insetHeight),
      "size": 0.03 * width
    });
    stars.add({
      "from": Offset(center, 0.332 * insetHeight),
      "to": Offset(0.335 * insetWidth, 0.332 * insetHeight),
      "size": 0.03 * width
    });
    stars.add({
      "from": Offset(center, 0.112 * insetHeight),
      "to": Offset(0.133 * insetWidth, 0.112 * insetHeight),
      "size": 0.1 * width
    });
    stars.add({
      "from": Offset(center, 0.551 * insetHeight),
      "to": Offset(0.042 * insetWidth, 0.551 * insetHeight),
      "size": 0.03 * width
    });
    stars.add({
      "from": Offset(center, 0.661 * insetHeight),
      "to": Offset(0.335 * insetWidth, 0.661 * insetHeight),
      "size": 0.05 * width
    });
    flares.add({
      "from": Offset(0.739 * insetWidth, 0.039 * insetHeight),
      "to": Offset(center, 0.039 * insetHeight),
      "size": 0.10 * width
    });
    flares.add({
      "from": Offset(0.628 * insetWidth, 0.368 * insetHeight),
      "to": Offset(center, 0.368 * insetHeight),
      "size": 0.043 * width
    });
  }
}

/// A ThemeMode Selector widget designed by Zhenya Karapetyan
/// /// Creates a ThemeMode Selector.
///
/// This selector maintains its own state and the widget calls the
/// [onChanged] callback when its state is changed.
///
/// * [height] allows the user to control the height of the widget and
///    a default height of 39 is used.
/// * [onChanged] is called while the user is selecting a new value for the
///   slider.
/// * [lightBackground] and [lightToggle] are colors which control the
///   foreground and background colors representing the "light" theme mode
/// * [darkBackground] and [darkToggle] are colors which control the
///   foreground and background colors representing the "dark" theme mode
///
class ThemeModeSelector extends HookWidget {
  final int _durationInMs;
  final Color? _lightBackgroundColor;
  final Color? _darkBackgroundColor;
  final Color? _lightToggleColor;
  final Color? _darkToggleColor;
  final _ThemeModeSelectorConsts _consts;
  final bool _isChecked;
  final ValueChanged<ThemeMode> _onChanged;

  ThemeModeSelector({
    Key? key,
    int durationInMs = 750,
    Color? lightBackground,
    Color? lightToggle,
    Color? darkBackground,
    Color? darkToggle,
    double height = 39,
    this.animationController,
    required bool isChecked,
    required ValueChanged<ThemeMode> onChanged,
  })  : _durationInMs = durationInMs,
        _onChanged = onChanged,
        _lightBackgroundColor = lightBackground,
        _lightToggleColor = lightToggle,
        _darkBackgroundColor = darkBackground,
        _darkToggleColor = darkToggle,
        _consts = _ThemeModeSelectorConsts(height),
        _isChecked = isChecked,
        super(key: key);

  final AnimationController? animationController;
  late AnimationController _animationController;
  Set<MaterialState> _states = {};

  late Animation<Alignment> _alignmentAnimation;
  Animation<double>? _starFade;
  Animation<double>? _flareFade;
  late Animation<double> _starToggleFade;
  late Animation<double> _flareToggleFade;
  late Animation<Color?> _bgColorAnimation;
  late ValueNotifier<bool> isChecked;

  initialize(BuildContext context, ThemeModeSelectorThemeData myTheme) {
    Duration _duration = Duration(milliseconds: _durationInMs);

    _animationController = animationController ??
        useAnimationController(
            duration: _duration, initialValue: isChecked.value ? 1 : 0);

    // Setup the tween for the background colors
    _bgColorAnimation = ColorTween(
      begin: lightBackgroundColor(myTheme) as Color,
      end: darkBackgroundColor(myTheme) as Color,
    ).animate(_animationController);

    // the tween for the toggle button (left and right)
    _alignmentAnimation = AlignmentTween(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.9, curve: Curves.easeOutBack),
        reverseCurve: Interval(0.0, 0.9, curve: Curves.easeInBack),
      ),
    );

    // Tweens and animation for the stars and flares
    var earlyFade = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.5, curve: Curves.elasticOut),
      reverseCurve: Interval(0.5, 1.0, curve: Curves.elasticIn),
    );

    _starFade = Tween(begin: 0.0, end: 1.0).animate(earlyFade);
    _flareFade = Tween(begin: 1.0, end: 0.0).animate(earlyFade);
    _starToggleFade = Tween(begin: 0.0, end: 1.0).animate(earlyFade);
    _flareToggleFade = Tween(begin: 1.0, end: 0.0).animate(earlyFade);
  }

  // Builds the semi-complex tween for the stars and flares which aninate to
  // and fro from the center of the widget
  Animation<RelativeRect> slide(Offset from, Offset to, double size) {
    var container =
        Rect.fromLTWH(0, 0, _consts.inset.width, _consts.inset.height);
    return RelativeRectTween(
      begin: RelativeRect.fromRect(
          Rect.fromLTWH(from.dx, from.dy, size, size), container),
      end: RelativeRect.fromRect(
          Rect.fromLTWH(to.dx, to.dy, size, size), container),
    ).animate(
        // _animationController
        CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeOut.flipped,
    ));
  }

  lightToggleColor(myTheme) =>
      _lightToggleColor ?? myTheme.lightToggleColor ?? Colors.white;

  lightBackgroundColor(myTheme) =>
      _lightBackgroundColor ??
      myTheme.lightBackgroundColor ??
      Color(0xFF689DFF);

  darkToggleColor(myTheme) =>
      _darkToggleColor ?? myTheme.darkToggleColor ?? Colors.white;

  darkBackgroundColor(myTheme) =>
      _darkBackgroundColor ?? myTheme.darkBackgroundColor ?? Color(0xFF040507);

  @override
  Widget build(BuildContext context) {
    ThemeModeSelectorThemeData myTheme = ThemeModeSelectorTheme.of(context);
    isChecked = useState(_isChecked);

    initialize(context, myTheme);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (isChecked.value) {
            _animationController.reverse();
          } else {
            _animationController.forward();
          }

          isChecked.value = !isChecked.value;
          _onChanged(isChecked.value ? ThemeMode.dark : ThemeMode.light);
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: _consts.size.width,
                  height: _consts.size.height,
                  padding: _consts.padding,
                  decoration: BoxDecoration(
                    color: _bgColorAnimation.value,
                    borderRadius: BorderRadius.all(
                      Radius.circular(_consts.size.height),
                    ),
                  ),
                  child: Stack(
                    children: <Widget>[
                      ..._consts.stars
                          .map((star) => CelestialTransition(
                                alphaAnimation: _starFade,
                                child: Star(
                                    size: star['size'] as double?,
                                    color: lightToggleColor(myTheme) as Color),
                                relativeRectAnimation: slide(
                                    star['from'] as Offset,
                                    star['to'] as Offset,
                                    star['size'] as double),
                              ))
                          .toList(),
                      ..._consts.flares
                          .map((flare) => CelestialTransition(
                                alphaAnimation: _flareFade,
                                child: Flare(
                                    size: flare['size'] as double?,
                                    color: lightToggleColor(myTheme) as Color),
                                relativeRectAnimation: slide(
                                    flare['from'] as Offset,
                                    flare['to'] as Offset,
                                    flare['size'] as double),
                              ))
                          .toList(),
                      Align(
                        alignment: _alignmentAnimation.value,
                        child: Stack(children: [
                          FadeTransition(
                            opacity: _flareToggleFade,
                            child: Sun(
                              color: lightToggleColor(myTheme) as Color,
                              size: _consts.inset.height,
                            ),
                          ),
                          FadeTransition(
                            opacity: _starToggleFade,
                            child: Moon(
                              color: darkToggleColor(myTheme) as Color,
                              size: _consts.inset.height,
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
                FocusBackground(
                  padding: _consts.focusPadding,
                  focused: _states.contains(MaterialState.focused),
                  width: _consts.size.width,
                  height: _consts.size.height,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
