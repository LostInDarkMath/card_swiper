import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:icon_decoration/icon_decoration.dart';

// const NAVIGATION_ICON = Icon(Icons.forward);
const NAVIGATION_ICON = DecoratedIcon(
  icon: Icon(Icons.forward, color: Colors.white),
  decoration: IconDecoration(
    border: IconBorder(
      color: Colors.black,
      width: 2.0,
    ),
  ),
);
const NAVIGATION_ICON_SPACE = 10.0;

/// Shows an image in full-screen mode.
/// Provides also the ability to zoom into the image.
class FullScreenImage extends StatefulWidget {
  /// The image.
  final Image image;

  /// The maximum allowed zoom factor.
  final double maxZoomFactor;

  /// The threshold for detecting swipe gestures.
  final double sensitivity;

  /// Called when the image is tapped.
  /// Default behavior is doing nothing.
  final VoidCallback? onTap;

  /// Called when user swipes the image in the right direction.
  final Future<Image> Function()? onSwipeRight;

  /// Called when user swipes the image in the left direction.
  final Future<Image> Function()? onSwipeLeft;

  /// If false, the callbacks [onSwipeRight] and [onSwipeLeft] are ignored. If true, arrow buttons are displayed on the top of the image.
  final bool isNavigationEnabled;

  /// To avoid treating one swipe gesture as multiple we wait after a detected gesture before we listen to a new one.
  final Duration swipeDetectionPauseAfterGesture;

  const FullScreenImage({
    required this.image,
    this.maxZoomFactor = 5.0,
    this.sensitivity = 8.0,
    this.onTap,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.isNavigationEnabled = false,
    this.swipeDetectionPauseAfterGesture = const Duration(milliseconds: 100),
    Key? key,
  }):
    assert(isNavigationEnabled ? onSwipeLeft != null && onSwipeRight != null : true),
    super(key: key);

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  /// The [TransformationController] is needed to determine if
  /// the user has zoomed in or not.
  final transformationController = TransformationController();

  late Image image;
  bool _isLoading = false;

  bool get userHasZoomedIn => (Matrix4.identity() - transformationController.value).infinityNorm() > 0.000001;

  @override
  void initState(){
    super.initState();
    image = widget.image;
  }

  Future<void> showNextImage({bool rightDirection = true}) async {
    print('show next image: rightDirection = $rightDirection');
    _isLoading = true;

    if(rightDirection) {
      image = await widget.onSwipeRight!();
    } else {
      image = await widget.onSwipeLeft!();
    }

    print('Got new image, rebuilding...');
    transformationController.value = Matrix4.identity(); // reset zooming before navigation to next image
    if(!mounted) return;
    setState(() {});

    // instead of a simple "_isLoading = false;" we wait after a detected gesture
    unawaited(Future.delayed(widget.swipeDetectionPauseAfterGesture, () => _isLoading = false));
  }

  @override
  Widget build(BuildContext context) {
    final interactiveImage = Center(
      child: Hero(
        tag: 'imageHero',
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              maxScale: widget.maxZoomFactor,
              transformationController: transformationController,
              child: image,
              onInteractionEnd: (details) => setState((){}), // refresh
            ),
            Positioned(
              top: NAVIGATION_ICON_SPACE,
              left: NAVIGATION_ICON_SPACE,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: DecoratedIcon(
                  icon: Icon(Platform.isAndroid ? Icons.arrow_back: Icons.arrow_back_ios, color: Colors.white),
                  decoration: const IconDecoration(
                    border: IconBorder(
                      color: Colors.black,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            if(widget.isNavigationEnabled)
            Positioned(
              bottom: NAVIGATION_ICON_SPACE,
              right: NAVIGATION_ICON_SPACE,
              child: IconButton(
                onPressed: () async => await showNextImage(rightDirection: false),
                icon: NAVIGATION_ICON,
              ),
            ),
            if(widget.isNavigationEnabled)
            Positioned(
              bottom: NAVIGATION_ICON_SPACE,
              left: NAVIGATION_ICON_SPACE,
              child: RotatedBox(
                quarterTurns: 2,
                child: IconButton(
                  onPressed: () async => await showNextImage(rightDirection: true),
                  icon: NAVIGATION_ICON,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if(userHasZoomedIn || !widget.isNavigationEnabled){
      return Scaffold(
        body: interactiveImage,
      );
    }

    // at this point we now that widget.onSwipeRight / Left callbacks are both not null
    return Scaffold(
      body: GestureDetector(
        onTap: widget.onTap,
        onHorizontalDragUpdate: userHasZoomedIn ? null : (details) async {
          if(_isLoading){
            print('Skip gesture because I am loading.');
            return;
          }

          final userHasSwipedInRightDirection = details.delta.dx > widget.sensitivity;
          final userHasSwipedInLeftDirection = details.delta.dx < -widget.sensitivity;

          if (userHasSwipedInRightDirection) {
            print('Detected swipe to the right.');
            await showNextImage(rightDirection: true);
          } else if (userHasSwipedInLeftDirection) {
            print('Detected swipe to the left.');
            await showNextImage(rightDirection: false);
          }
        },
        child: interactiveImage,
      ),
    );
  }
}
