# Laudo Técnico — Operação Resgate: Detetives de Bugs

Projeto: Central de Achados e Perdidos (Flutter + Firebase Auth + Cloud Firestore)

## Resumo

| Bug | Arquivo | Problema |
|----|---------|----------|
| 01 | `lib/pages/central_page.dart` | Quebra de linha literal dentro de uma string (não compila) |
| 02 | `lib/pages/central_page.dart` | `DetalhePage()` chamado sem o parâmetro obrigatório `ocorrencia` (não compila) |
| 03 | `lib/services/central_service.dart` | `autorId` gravado com o e-mail em vez do `uid` |
| 04 | `lib/models/ocorrencia.dart` | `autorId` lido do campo `autorNome` |
| 05 | `lib/models/ocorrencia.dart` | Status `resolvido` invertido na leitura (`!`) |
| 06 | `lib/pages/central_page.dart` | Switch "Somente não resolvidos" grava o valor invertido |
| 07 | `lib/pages/central_page.dart` | Filtro mostra os resolvidos em vez dos não resolvidos |
| 08 | `lib/pages/central_page.dart` | Validação do cadastro usa `&&` em vez de `\|\|` |
| 09 | `lib/services/central_service.dart` | Lista em ordem crescente (mais antigo primeiro) |
| 10 | `lib/services/central_service.dart` | "Marcar como resolvido" grava o mesmo valor (não muda nada) |
| 11 | `lib/services/central_service.dart` | Pista gravada no documento fixo `ocorrencias/pistas` |
| 12 | `lib/pages/detalhe_page.dart` | Envio de pista com condição invertida e mensagem vazia |

Também ajustei a configuração do projeto (`pubspec.yaml`, teste, regras do Firestore). Isso está na seção "Ajustes de ambiente", no fim deste laudo.

---

## Bug 01

- **Arquivo:** `lib/pages/central_page.dart` (subtítulo do `ListTile`)
- **Sintoma:** o projeto não compilava. O analisador mostrava `Unterminated string literal`, `Undefined name 'Por'` e outros erros em cascata.
- **Causa:** a string `'... "Em aberto"}` + ENTER + `Por ${o.autorNome}'` tinha uma quebra de linha real. Em Dart, uma string com aspas simples não pode atravessar linhas.
- **Correção:** troquei a quebra real por `\n`:
  ```dart
  subtitle: Text('${o.local} • ${o.resolvido ? "Resolvido" : "Em aberto"}\nPor ${o.autorNome}'),
  ```
- **Teste:** rodei `flutter analyze` e os erros de sintaxe sumiram. No app, o card mostra o local e o status na 1ª linha e "Por <nome>" na 2ª.

## Bug 02

- **Arquivo:** `lib/pages/central_page.dart` (`onTap` do card)
- **Sintoma:** erro de compilação: `The named parameter 'ocorrencia' is required`. Sem isso não dava para abrir os detalhes.
- **Causa:** `DetalhePage` exige `required this.ocorrencia`, mas a navegação chamava `DetalhePage()` sem argumento.
- **Correção:** `MaterialPageRoute(builder: (_) => DetalhePage(ocorrencia: o))`
- **Teste:** `flutter analyze` sem erros. Ao tocar num card, a tela "Investigação" abre com o título, o local e o autor da ocorrência tocada.

## Bug 03

- **Arquivo:** `lib/services/central_service.dart` (`registrar`)
- **Sintoma:** o dono de uma ocorrência nunca conseguia mudar o status, e o botão "Marcar como resolvido" não aparecia nem para quem registrou.
- **Causa:** o campo `autorId` era gravado com `u.email`. O app (`alterarStatus` e `DetalhePage`) e as regras de segurança comparam com `u.uid`, então nunca batia. O e-mail também não é um identificador estável.
- **Correção:** `'autorId': u.uid`
- **Teste:** registrei uma ocorrência e conferi no console do Firestore que `autorId` passou a ser o UID da conta (o mesmo de Authentication > Users).

## Bug 04

- **Arquivo:** `lib/models/ocorrencia.dart` (`fromDoc`)
- **Sintoma:** mesmo com o `autorId` correto no banco, o app não reconhecia o dono. Os dados no Firestore estavam certos, mas a comparação falhava.
- **Causa:** `autorId: d['autorNome']`. O modelo lia o nome no lugar do ID.
- **Correção:** `autorId: d['autorId'] as String? ?? ''`
- **Teste:** na conta A, ao abrir a própria ocorrência, o botão "Marcar como resolvido" aparece. Na conta B, ao abrir a mesma ocorrência, ele não aparece.

## Bug 05

- **Arquivo:** `lib/models/ocorrencia.dart` (`fromDoc`)
- **Sintoma:** objetos recém-registrados apareciam como "Resolvido", e os resolvidos como "Em aberto". No Firestore estava `resolvido: false`.
- **Causa:** `resolvido: !(d['resolvido'] as bool? ?? false)`. O `!` invertia o valor lido.
- **Correção:** `resolvido: d['resolvido'] as bool? ?? false`
- **Teste:** registrei um objeto novo e ele aparece como "Em aberto", conferindo com `resolvido: false` no console.

## Bug 06

- **Arquivo:** `lib/pages/central_page.dart` (`SwitchListTile`)
- **Sintoma:** o switch "Somente não resolvidos" não ligava (ou ligava e desligava sozinho).
- **Causa:** `onChanged: (value) => setState(() => somenteAbertos = !value)`. O `value` recebido já é o novo estado, e invertê-lo desfazia o toque.
- **Correção:** `somenteAbertos = value`
- **Teste:** ao tocar no switch ele liga, e ao tocar de novo ele desliga.

## Bug 07

- **Arquivo:** `lib/pages/central_page.dart` (filtro da lista)
- **Sintoma:** com o filtro ligado, apareciam apenas os objetos resolvidos.
- **Causa:** `todos.where((o) => o.resolvido)` fazia o oposto do que o rótulo promete.
- **Correção:** `todos.where((o) => !o.resolvido)`
- **Teste:** com 2 objetos, um marcado como resolvido, o filtro ligado mostra só o que está "Em aberto". Desligado, mostra os dois.

## Bug 08

- **Arquivo:** `lib/pages/central_page.dart` (`cadastrar`)
- **Sintoma:** dava para registrar uma ocorrência com o título vazio ou com o local vazio. Só era bloqueado quando os dois estavam vazios.
- **Causa:** `titulo...isEmpty && local...isEmpty`. A mensagem "Informe título e local" exige os dois campos, então a condição precisa ser "um OU outro vazio".
- **Correção:** troquei `&&` por `||`.
- **Teste:** com só o título preenchido aparece o aviso "Informe título e local." e nada é gravado. Com título e local preenchidos, registra normalmente.

## Bug 09

- **Arquivo:** `lib/services/central_service.dart` (`acompanhar`)
- **Sintoma:** os registros novos iam para o fim da lista, e as ocorrências mais recentes ficavam escondidas lá embaixo.
- **Causa:** `orderBy('criadoEm', descending: false)`.
- **Correção:** `orderBy('criadoEm', descending: true)`, com as mais recentes no topo. (As pistas continuam em ordem crescente, como uma conversa.)
- **Teste:** registrei "Objeto 1" e depois "Objeto 2", e o "Objeto 2" aparece primeiro.

## Bug 10

- **Arquivo:** `lib/services/central_service.dart` (`alterarStatus`)
- **Sintoma:** ao tocar em "Marcar como resolvido", a tela fechava sem erro, mas o status não mudava.
- **Causa:** `update({'resolvido': item.resolvido})` gravava o valor atual em vez de alternar.
- **Correção:** `update({'resolvido': !item.resolvido})`
- **Teste:** marquei como resolvido e no console ficou `resolvido: true`, com o card mostrando "Resolvido". Depois toquei em "Reabrir" e voltou para `false` / "Em aberto".

## Bug 11

- **Arquivo:** `lib/services/central_service.dart` (`enviarPista`)
- **Sintoma:** as pistas enviadas não apareciam na ocorrência. No Firestore todas iam para `ocorrencias/pistas/pistas`, um documento "fantasma" chamado `pistas`, misturando as pistas de todos os casos. Não aparecia nenhum erro no terminal.
- **Causa:** o caminho usava a string fixa `.doc('pistas')` em vez do ID recebido.
- **Correção:** `.doc(ocorrenciaId).collection('pistas')`
- **Teste:** a conta B enviou uma pista na ocorrência X. Ela aparece em `ocorrencias/<id de X>/pistas` e na tela da ocorrência X, para as contas A e B, mas não na ocorrência Y.

## Bug 12

- **Arquivo:** `lib/pages/detalhe_page.dart` (`enviar`)
- **Sintoma:** ao digitar uma pista e enviar, nada acontecia. Com o campo vazio, o app tentava enviar uma pista sem texto.
- **Causa:** havia dois erros na mesma função:
  1. `if (pista.text.trim().isNotEmpty) return;` saía justamente quando havia texto.
  2. `service.enviarPista(widget.ocorrencia.id, '')` enviava uma string vazia em vez do texto digitado.
- **Correção:**
  ```dart
  if (pista.text.trim().isEmpty) return;
  await service.enviarPista(widget.ocorrencia.id, pista.text);
  ```
- **Teste:** com o campo vazio nada é enviado. Com texto, a pista aparece na lista com o nome do autor e o campo é limpo.

---

## Ajustes de ambiente (fazer o projeto rodar)

Não são defeitos de lógica, mas impediam a execução ou os testes:

| Arquivo | Problema | Ajuste |
|---------|----------|--------|
| `lib/firebase_options.dart` | Não vinha no repositório (avisado no README), então o app não iniciava | Criado com a configuração Web do projeto `detetives-de-bugs-1d317`. Também foram criados `firebase.json` e `.firebaserc` para publicar as regras |
| `pubspec.yaml` | `firebase_core ^4`, `firebase_auth ^6`, `cloud_firestore ^6` e `device_preview ^1.3.1` exigem Dart ≥ 3.8. O Flutter do laboratório é o 3.27.1 (Dart 3.6), e o `pub get` falhava | Versões compatíveis: `firebase_core ^3.8.0`, `firebase_auth ^5.3.0`, `cloud_firestore ^5.5.0`, `device_preview ^1.2.0`. A API usada pelo app é a mesma |
| `pubspec.yaml` | Faltavam `flutter_test` e `flutter_lints` (usados pelo teste e pelo `analysis_options.yaml`) | Adicionado `dev_dependencies` |
| `test/widget_test.dart` | Teste padrão do template importava `package:bugsresolver/main.dart` e `MyApp`, que não existem | Trocado por um teste do modelo `Ocorrencia` |
| `firestore.rules` | O projeto não tinha regras. Sem elas, a autorização só existia no app e qualquer usuário poderia alterar o status de qualquer caso direto pela API | Criado com as regras abaixo (as regras de segurança ficam ativas, não foram desativadas) |

### Regras do Firestore (`firestore.rules`)

- Ler ocorrências e pistas exige login.
- Criar uma ocorrência só é permitido com `autorId == request.auth.uid`, `resolvido == false` e título e local preenchidos.
- Alterar uma ocorrência só é permitido para o dono, e apenas no campo `resolvido`.
- Criar uma pista só é permitido em nome próprio e com a mensagem preenchida.
- Ninguém pode apagar nada nem editar pistas.

**Teste de autorização:** a conta B abriu uma ocorrência da conta A e o botão de status não aparece (proteção no app). Uma tentativa de `update` feita pela conta B é recusada pelo Firestore com `permission-denied` (proteção no servidor). O mesmo pode ser simulado no *Rules Playground* do console.

## Teste multiusuário (Missão 3)

1. Abrir o app em duas janelas (uma normal e outra anônima, ou dois perfis do Chrome) e entrar com a conta A e a conta B.
2. A conta A registra uma ocorrência, que aparece **sozinha** na lista da conta B, sem recarregar (o `snapshots()` mantém a lista ao vivo).
3. A conta B abre a ocorrência e envia uma pista, que aparece ao vivo na tela da conta A, na ocorrência correta.
4. A conta B não vê o botão de status. A conta A marca como resolvido e o status muda nas duas janelas.

Print: `print-duas-contas.png` (as duas contas visualizando a mesma ocorrência).
