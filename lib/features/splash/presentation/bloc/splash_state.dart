import 'package:equatable/equatable.dart';

abstract class SplashState extends Equatable {
  const SplashState();
  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {
  const SplashInitial();
}

/// Tells the page which route to open.
class SplashNavigate extends SplashState {
  final String route;
  const SplashNavigate(this.route);
  @override
  List<Object?> get props => [route];
}
