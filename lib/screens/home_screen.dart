import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../models/contexto_aluno.dart';
import '../models/falta_model.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _contextDialogShown = false;
  bool _contextRetryVisible = false;
  @override
  void initState() {
    super.initState();
    // Carrega os dados quando a tela é iniciada. Se não houver cookie,
    // pede ao usuário selecionar um contexto antes de buscar os dados.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Não aguardar diretamente para evitar bloquear frames iniciais
      _ensureContextSelected();
    });
  }

  void _ensureContextSelected() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final cookie = await auth.getCookie();
      if (cookie == null) {
        // Buscar contextos com timeout
        List<ContextoAluno> contexts = [];
        try {
          contexts = await auth.fetchContextos().timeout(const Duration(seconds: 10));
        } catch (e) {
          // timeout ou erro
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao buscar contextos (timeout). Tente novamente).')),
          );
          setState(() => _contextRetryVisible = true);
        }

        if (contexts.isNotEmpty && mounted && !_contextDialogShown) {
          _contextDialogShown = true;
          final selected = await _showContextSelection(contexts);
          _contextDialogShown = false;
          if (selected != null) {
            final ok = await auth.selecionarContexto(selected);
            if (ok && mounted) {
              // chama refresh sem await para não bloquear a UI
              Provider.of<DataProvider>(context, listen: false).refreshData();
            }
          }
        }
      } else {
        if (mounted) {
          // chama refresh sem await para não bloquear o fluxo de IU
          Provider.of<DataProvider>(context, listen: false).refreshData();
        }
      }
    } catch (e) {
      if (mounted) {
        final dp = Provider.of<DataProvider>(context, listen: false);
        await dp.refreshData();
      }
    }
  }

  Future<ContextoAluno?> _showContextSelection(List<ContextoAluno> contexts) {
    ContextoAluno? _selected = contexts.first;

    return showDialog<ContextoAluno>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Selecione o contexto'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<ContextoAluno>(
                isExpanded: true,
                value: _selected,
                items: contexts.map((c) {
                  final label = '${c.nomeCurso} • ${c.nomePeriodo} • (${c.nomeTurno})';
                  return DropdownMenuItem(
                    value: c,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selected = v),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(_selected),
              child: const Text('Selecionar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualização'),
        actions: [
          // Botão para abrir manualmente a seleção de contexto
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Selecionar contexto',
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              try {
                final contexts = await auth.fetchContextos().timeout(const Duration(seconds: 10));
                if (contexts.isNotEmpty && mounted) {
                  final selected = await _showContextSelection(contexts);
                  if (selected != null) {
                    final ok = await auth.selecionarContexto(selected);
                    if (ok && mounted) {
                      Provider.of<DataProvider>(context, listen: false).refreshData();
                    }
                  }
                } else {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum contexto disponível')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao buscar contextos')));
              }
            },
          ),
          // Botão de configurações
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: dataProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => dataProvider.refreshData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodayCard(dataProvider),
                    const SizedBox(height: 16),
                    _buildFaltasTable(dataProvider.faltas),
                    const SizedBox(height: 16),
                    _buildProgressBars(dataProvider.faltas),
                  ],
                ),
              ),
            ),
  floatingActionButton: FloatingActionButton(
    onPressed: () {
      dataProvider.refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atualizando dados...'),
          duration: Duration(seconds: 2),
        ),
      );
    },
    child: const Icon(Icons.refresh),
  ),
    );
  }

  Widget _buildTodayCard(DataProvider dataProvider) {
    final diaHoje = dataProvider.getDiaAtual();
    final materiasHoje = dataProvider.getMateriasHoje();
    final faltasRestantes = dataProvider.getFaltasRestantesHoje();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  diaHoje,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Aulas de hoje',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  const TextSpan(
                    text: '📚 ',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const TextSpan(
                    text: 'Matérias: ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: materiasHoje,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (faltasRestantes.isEmpty) ...[
              const Center(
                child: Text(
                  'Nenhuma matéria com aulas hoje',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ] else ...[
              Column(
                children: [
                  if (faltasRestantes.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: const Text(
                              'Matéria',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Text(
                            'Faltas Restantes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...faltasRestantes.map((falta) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${falta['materia']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'Restam ${falta['faltasRestantes']} de ${falta['podeFaltar']}',
                            style: TextStyle(
                              color: dataProvider.getStatusColor(falta['percentual']),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ]
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }





  Widget _buildFaltasTable(List<FaltaModel> faltas) {
    if (faltas.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma falta registrada',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.school, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Tabela de Faltas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Cabeçalho da tabela
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Matéria',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Faltas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Restam',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Linha separadora
          Container(
            color: Colors.grey[200],
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Linhas de dados
          ...faltas.map((falta) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      falta.nomeMateria,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      falta.faltas.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      falta.podeFaltar.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${falta.percentual.toStringAsFixed(1)}%',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildProgressBars(List<FaltaModel> faltas) {
    if (faltas.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma falta registrada',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Progresso das Faltas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Linhas separadoras
          Container(
            color: Colors.grey[200],
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Barras de progresso
          ...faltas.map((falta) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          falta.nomeMateria,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 100,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: (falta.percentual >= 25) ? 1.0 : (falta.percentual / 25),
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getColorForPercentage(falta.percentual),
                        ),
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(falta.percentual >= 25 ? 100 : (falta.percentual / 25 * 100)).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 25) return Colors.red;          
    if (percentage >= 10) return Colors.orange; 
    return Colors.amber[600]!;          
  }
}
