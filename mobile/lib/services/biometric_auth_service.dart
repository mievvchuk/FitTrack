import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  const BiometricAuthService(this._localAuthentication);

  final LocalAuthentication _localAuthentication;

  Future<bool> canAuthenticate() async {
    final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
    final isDeviceSupported = await _localAuthentication.isDeviceSupported();
    return canCheckBiometrics || isDeviceSupported;
  }

  Future<bool> authenticate() {
    return _localAuthentication.authenticate(
      localizedReason: 'Підтвердьте вхід у FitTrack',
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
  }
}
