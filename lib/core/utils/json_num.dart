/// Postgres serializa columnas `numeric`/`decimal` como string en el JSON
/// de Laravel en varios endpoints (ej. `lat`/`lng`, `score_ranking`,
/// `promedio` de reseñas) — a diferencia de un entero normal, que sí viaja
/// como `num`. Parsear con `as num` directo revienta con
/// "type 'String' is not a subtype of type 'num'" apenas el backend manda
/// uno de estos como texto. Esta función acepta ambas formas.
double numDeJson(dynamic valor, [double porDefecto = 0]) {
  if (valor == null) return porDefecto;
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor.toString()) ?? porDefecto;
}

double? numDeJsonOrNull(dynamic valor) {
  if (valor == null) return null;
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor.toString());
}
