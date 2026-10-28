import 'package:flutter_test/flutter_test.dart';

import 'package:central_achados/models/ocorrencia.dart';

void main() {
  test('Ocorrencia guarda autor e status informados', () {
    const o = Ocorrencia(id: '1', titulo: 'Garrafa', local: 'Quadra',
      descricao: '', autorId: 'uid-a', autorNome: 'Aluno A',
      resolvido: false, criadoEm: null);
    expect(o.autorId, 'uid-a');
    expect(o.resolvido, isFalse);
  });
}
