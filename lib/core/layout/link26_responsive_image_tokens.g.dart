// GENERATED FILE - do not edit by hand.
// Source: assets/design/link26_responsive_images.xml
// Regenerate: dart run tool/generate_link26_surface.dart

import 'link26_responsive_layout.dart';
import 'link26_responsive_tokens.g.dart';

abstract final class Link26ResponsiveImageHeights {
  static double authWelcome(double width) {
    if (width < Link26ResponsiveTokens.breakpointCompact) {
      return 100.0;
    }
    if (width < Link26ResponsiveTokens.breakpointMedium) {
      return 124.0;
    }
    return 144.0;
  }

  static double authWelcomeDisplayWidth(double width) => (Link26Layout.innerWidth(width) * 0.92).clamp(0.0, double.infinity);

  static double login(double width) {
    if (width < Link26ResponsiveTokens.breakpointCompact) {
      return 108.0;
    }
    if (width < Link26ResponsiveTokens.breakpointMedium) {
      return 160.0;
    }
    return 192.0;
  }

  static double loginDisplayWidth(double width) => (Link26Layout.innerWidth(width) * 1.0).clamp(0.0, double.infinity);

  static double signup(double width) {
    if (width < Link26ResponsiveTokens.breakpointCompact) {
      return 108.0;
    }
    if (width < Link26ResponsiveTokens.breakpointMedium) {
      return 160.0;
    }
    return 192.0;
  }

  static double signupDisplayWidth(double width) => (Link26Layout.innerWidth(width) * 1.0).clamp(0.0, double.infinity);

  static double aiChat(double width) {
    if (width < Link26ResponsiveTokens.breakpointCompact) {
      return 76.0;
    }
    if (width < Link26ResponsiveTokens.breakpointMedium) {
      return 96.0;
    }
    return 118.0;
  }

  static double aiChatDisplayWidth(double width) => (Link26Layout.innerWidth(width) * 0.52).clamp(0.0, double.infinity);

  static double pillSearch(double width) {
    if (width < Link26ResponsiveTokens.breakpointCompact) {
      return 118.0;
    }
    if (width < Link26ResponsiveTokens.breakpointMedium) {
      return 158.0;
    }
    return 200.0;
  }

  static double pillSearchDisplayWidth(double width) => (Link26Layout.innerWidth(width) * 1.0).clamp(0.0, double.infinity);

  static double emergencyIllustration(double width) {
    if (width < Link26ResponsiveTokens.breakpointCompact) {
      return 140.0;
    }
    if (width < Link26ResponsiveTokens.breakpointMedium) {
      return 180.0;
    }
    return 220.0;
  }

  static double emergencyIllustrationDisplayWidth(double width) => (Link26Layout.innerWidth(width) * 1.0).clamp(0.0, double.infinity);

  static double simpleLogin1(double width) {
    if (width < Link26ResponsiveTokens.breakpointCompact) {
      return 160.0;
    }
    if (width < Link26ResponsiveTokens.breakpointMedium) {
      return 200.0;
    }
    return 240.0;
  }

  static double simpleLogin1DisplayWidth(double width) => (Link26Layout.innerWidth(width) * 1.0).clamp(0.0, double.infinity);

  static double simpleLogin2(double width) {
    if (width < Link26ResponsiveTokens.breakpointCompact) {
      return 160.0;
    }
    if (width < Link26ResponsiveTokens.breakpointMedium) {
      return 200.0;
    }
    return 240.0;
  }

  static double simpleLogin2DisplayWidth(double width) => (Link26Layout.innerWidth(width) * 1.0).clamp(0.0, double.infinity);

}
