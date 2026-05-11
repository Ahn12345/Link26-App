/// [MainShell] 이 마운트될 때 탭 전환 콜백을 등록해, 홈 등에서 AI 탭으로 이동할 수 있게 합니다.
abstract final class MainShellTabBus {
  MainShellTabBus._();

  static void Function(int index)? _goTo;

  static void bind(void Function(int index) goTo) {
    _goTo = goTo;
  }

  static void unbind() {
    _goTo = null;
  }

  static void goTo(int index) {
    _goTo?.call(index);
  }
}
