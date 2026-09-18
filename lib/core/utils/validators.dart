class AppValidators {
  AppValidators._();

  /// Celular ecuatoriano: `09` + 8 dígitos (mismo formato que exige la API
  /// en todos los endpoints de Identity).
  static final _telefonoRegExp = RegExp(r'^09\d{8}$');

  static String? telefono(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Ingresa tu número de celular';
    if (!_telefonoRegExp.hasMatch(valor.trim())) {
      return 'Formato inválido: debe ser 09 seguido de 8 dígitos';
    }
    return null;
  }

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Ingresa tu correo';
    if (!_emailRegExp.hasMatch(valor.trim())) return 'Correo inválido';
    return null;
  }

  static String? password(String? valor) {
    if (valor == null || valor.isEmpty) return 'Ingresa tu contraseña';
    if (valor.length < 8) return 'Debe tener al menos 8 caracteres';
    return null;
  }

  static String? requerido(String? valor, [String etiqueta = 'Este campo']) {
    if (valor == null || valor.trim().isEmpty) return '$etiqueta es obligatorio';
    return null;
  }

  static String? codigoOtp(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Ingresa el código';
    if (valor.trim().length != 6) return 'El código tiene 6 dígitos';
    return null;
  }

  static String? numeroPositivo(String? valor, [String etiqueta = 'El valor']) {
    if (valor == null || valor.trim().isEmpty) return '$etiqueta es obligatorio';
    final n = double.tryParse(valor.replaceAll(',', '.'));
    if (n == null || n < 0) return '$etiqueta debe ser un número válido';
    return null;
  }

  static String? enteroPositivo(String? valor, [String etiqueta = 'El valor']) {
    if (valor == null || valor.trim().isEmpty) return '$etiqueta es obligatorio';
    final n = int.tryParse(valor);
    if (n == null || n <= 0) return '$etiqueta debe ser un entero mayor a 0';
    return null;
  }
}
