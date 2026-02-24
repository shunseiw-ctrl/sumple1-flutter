import 'splash_remover_stub.dart'
    if (dart.library.html) 'splash_remover_web.dart';

void removeSplashScreen() => removeSplashScreenImpl();
