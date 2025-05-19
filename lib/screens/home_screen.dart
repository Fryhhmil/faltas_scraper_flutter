import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/falta_model.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega os dados quando a tela é iniciada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataProvider>(context, listen: false).refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualização'),
        actions: [
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
                    _buildDisciplinasList(dataProvider),
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
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }



  Widget _buildDisciplinasList(DataProvider dataProvider) {
    final materias = dataProvider.getMaterias();
    
    if (materias.isEmpty) {
      return const Center(
        child: Text('Nenhuma matéria encontrada'),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: materias.length,
      itemBuilder: (context, index) {
        final materia = materias[index];
        final falta = dataProvider.faltas.firstWhere(
          (f) => f.nomeMateria == materia,
          orElse: () => FaltaModel(
            nomeMateria: materia,
            faltas: 0,
            podeFaltar: 0,
            percentual: 0.0,
          ),
        );
        final percentual = falta.percentual;
        final statusColor = dataProvider.getStatusColor(percentual);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(materia),
            subtitle: Text('${percentual.toStringAsFixed(1)}% de faltas'),
            trailing: Container(
              width: 100,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentual / 100,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaltasTable(List<FaltaModel> faltas) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Matéria',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Faltas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Pode Faltar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Percentual',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (faltas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Nenhuma falta encontrada'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: faltas.length,
              itemBuilder: (context, index) {
                final falta = faltas[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: index < faltas.length - 1
                          ? BorderSide(color: Colors.grey.shade300)
                          : BorderSide.none,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            falta.nomeMateria,
                            textAlign: TextAlign.center,
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
                            '${falta.percentual}%',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
